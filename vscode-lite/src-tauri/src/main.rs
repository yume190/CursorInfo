#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::Serialize;
use serde_json::Value;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use tauri::path::BaseDirectory;
use tauri::Manager;

#[derive(Serialize)]
struct FileNode {
    name: String,
    path: String,
    is_dir: bool,
    children: Option<Vec<FileNode>>,
}

#[tauri::command]
fn default_project_root() -> Result<String, String> {
    std::env::current_dir()
        .map(|path| path.to_string_lossy().to_string())
        .map_err(|e| format!("Failed to get current directory: {}", e))
}

fn read_dir_tree(root: &Path) -> Result<Vec<FileNode>, String> {
    let mut entries = fs::read_dir(root)
        .map_err(|e| format!("Failed to read dir {}: {}", root.display(), e))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| format!("Failed to read dir entry: {}", e))?;

    entries.sort_by_key(|entry| entry.path());

    let mut nodes = Vec::new();

    for entry in entries {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().to_string();

        if name.starts_with('.') {
            continue;
        }

        let metadata = entry
            .metadata()
            .map_err(|e| format!("Failed to read metadata {}: {}", path.display(), e))?;

        if metadata.is_dir() {
            let children = read_dir_tree(&path)?;
            nodes.push(FileNode {
                name,
                path: path.to_string_lossy().to_string(),
                is_dir: true,
                children: Some(children),
            });
        } else {
            nodes.push(FileNode {
                name,
                path: path.to_string_lossy().to_string(),
                is_dir: false,
                children: None,
            });
        }
    }

    Ok(nodes)
}

#[tauri::command]
fn list_project_tree(root: String) -> Result<Vec<FileNode>, String> {
    let root_path = PathBuf::from(&root);
    if !root_path.exists() {
        return Err(format!("Root path not found: {}", root));
    }
    read_dir_tree(&root_path)
}

#[tauri::command]
fn read_file(path: String) -> Result<String, String> {
    fs::read_to_string(&path).map_err(|e| format!("Failed to read file {}: {}", path, e))
}

#[tauri::command]
fn write_file(path: String, content: String) -> Result<(), String> {
    fs::write(&path, content).map_err(|e| format!("Failed to write file {}: {}", path, e))
}

#[tauri::command]
fn demangle_usr(app: tauri::AppHandle, demangle_command: String, usr: String) -> Result<String, String> {
    if demangle_command.trim().is_empty() {
        return Err("Demangle command is empty".to_string());
    }
    if usr.trim().is_empty() {
        return Err("USR is empty".to_string());
    }
    let resolved = resolve_executable_command(&app, demangle_command.trim());

    let output = Command::new("zsh")
        .arg("-lc")
        .arg(format!("{} --usr {}", shell_escape(&resolved), shell_escape(&usr)))
        .output()
        .map_err(|e| format!("Failed to run demangle command: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        return Err(format!("Demangle command failed: {}", stderr));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

#[tauri::command]
fn run_shell_on_cursor(
    app: tauri::AppHandle,
    shell_command: String,
    file_path: String,
    code: String,
    offset: usize,
) -> Result<Value, String> {
    if shell_command.trim().is_empty() {
        return Err("Shell command is empty".to_string());
    }
    let resolved = resolve_executable_command(&app, shell_command.trim());

    let escaped_path = shell_escape(&file_path);
    let escaped_code = shell_escape(&code);
    let full_command = format!(
        "{} --offset {} --filepath {} --code {}",
        shell_escape(&resolved),
        offset,
        escaped_path,
        escaped_code
    );
    eprintln!(
        "[run_shell_on_cursor] command={} offset={} filepath={} code_len={}",
        resolved,
        offset,
        file_path,
        code.len()
    );

    let output = Command::new("zsh")
        .arg("-lc")
        .arg(&full_command)
        .output()
        .map_err(|e| format!("Failed to run shell command: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        return Err(format!("Shell command failed: {}", stderr));
    }

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if stdout.is_empty() {
        return Err("Shell command returned empty stdout; expected JSON".to_string());
    }

    serde_json::from_str::<Value>(&stdout)
        .map_err(|e| format!("Shell stdout is not valid JSON: {}. stdout={}", e, stdout))
}

fn shell_escape(input: &str) -> String {
    format!("'{}'", input.replace('\'', "'\"'\"'"))
}

fn resolve_executable_command(app: &tauri::AppHandle, command: &str) -> String {
    if command.contains('/') || command.contains(' ') {
        return command.to_string();
    }

    if let Ok(path) = app
        .path()
        .resolve(format!("bin/{}", command), BaseDirectory::Resource)
    {
        if path.exists() {
            return path.to_string_lossy().to_string();
        }
    }

    let dev_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("bin")
        .join(command);
    if dev_path.exists() {
        return dev_path.to_string_lossy().to_string();
    }

    command.to_string()
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            default_project_root,
            list_project_tree,
            read_file,
            write_file,
            demangle_usr,
            run_shell_on_cursor
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
