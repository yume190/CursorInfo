# VSCode Lite (Tauri + Monaco)

A minimal desktop editor app with:
- Project explorer tree (like VSCode sidebar)
- Monaco code editor with multi-language highlighting
- File open/edit/save
- Run shell command on cursor movement with JSON response

## Run

```bash
cd vscode-lite
npm install
npm run tauri:dev
```

## Shell Hook

Set shell command from the app UI (right panel).

The command runs on every cursor move (debounced), and the app appends arguments:

```bash
/path/to/cursor-info --offset <number> --filepath <path>
```

Command stdout must be valid JSON.
