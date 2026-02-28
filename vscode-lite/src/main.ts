import "./styles.css";
import { invoke } from "@tauri-apps/api/core";
import * as monaco from "monaco-editor";
import editorWorker from "monaco-editor/esm/vs/editor/editor.worker?worker";
import jsonWorker from "monaco-editor/esm/vs/language/json/json.worker?worker";
import cssWorker from "monaco-editor/esm/vs/language/css/css.worker?worker";
import htmlWorker from "monaco-editor/esm/vs/language/html/html.worker?worker";
import tsWorker from "monaco-editor/esm/vs/language/typescript/ts.worker?worker";

import "monaco-editor/esm/vs/basic-languages/swift/swift.contribution";
import "monaco-editor/esm/vs/basic-languages/python/python.contribution";
import "monaco-editor/esm/vs/basic-languages/go/go.contribution";
import "monaco-editor/esm/vs/basic-languages/rust/rust.contribution";
import "monaco-editor/esm/vs/basic-languages/java/java.contribution";
import "monaco-editor/esm/vs/basic-languages/kotlin/kotlin.contribution";
import "monaco-editor/esm/vs/basic-languages/cpp/cpp.contribution";
import "monaco-editor/esm/vs/basic-languages/csharp/csharp.contribution";
import "monaco-editor/esm/vs/basic-languages/markdown/markdown.contribution";
import "monaco-editor/esm/vs/basic-languages/yaml/yaml.contribution";
import "monaco-editor/esm/vs/basic-languages/shell/shell.contribution";
import "monaco-editor/esm/vs/basic-languages/ruby/ruby.contribution";
import "monaco-editor/esm/vs/basic-languages/php/php.contribution";

(self as unknown as { MonacoEnvironment: unknown }).MonacoEnvironment = {
  getWorker(_: string, label: string) {
    if (label === "json") return new jsonWorker();
    if (label === "css" || label === "scss" || label === "less") return new cssWorker();
    if (label === "html" || label === "handlebars" || label === "razor") return new htmlWorker();
    if (label === "typescript" || label === "javascript") return new tsWorker();
    return new editorWorker();
  },
};

type FileNode = {
  name: string;
  path: string;
  is_dir: boolean;
  children?: FileNode[];
};

type CursorEventPayload = {
  filePath: string;
  code: string;
  offset: number;
};

const app = document.querySelector<HTMLDivElement>("#app");
if (!app) throw new Error("#app not found");

app.innerHTML = `
  <aside class="sidebar">
    <div class="title">Explorer</div>
    <div class="toolbar">
      <button id="choose-root">Choose Root</button>
      <button id="save-file">Save</button>
    </div>
    <div id="current-root" class="node"></div>
    <div id="file-tree" class="tree"></div>
  </aside>
  <section class="editor-pane">
    <div id="editor-path" class="editor-header">No file selected</div>
    <div id="editor" class="editor"></div>
    <div class="editor-footer">
      <label for="language-select">Highlighter</label>
      <select id="language-select"></select>
      <span id="cursor-metrics" class="cursor-metrics">Ln 1, Col 1, Offset 0</span>
    </div>
  </section>
  <aside class="result-pane">
    <div class="result-block result-search-block">
      <input id="json-search" class="json-search" placeholder="Search keyword..." />
    </div>
    <div class="result-pane-scroll">
    <div class="result-block">
      <div id="shell-result-fields" class="json-fields"></div>
    </div>
    </div>
  </aside>
`;

const chooseRootBtn = document.getElementById("choose-root") as HTMLButtonElement;
const saveFileBtn = document.getElementById("save-file") as HTMLButtonElement;
const currentRootEl = document.getElementById("current-root") as HTMLDivElement;
const treeEl = document.getElementById("file-tree") as HTMLDivElement;
const editorPathEl = document.getElementById("editor-path") as HTMLDivElement;
const shellResultFieldsEl = document.getElementById("shell-result-fields") as HTMLDivElement;
const jsonSearchEl = document.getElementById("json-search") as HTMLInputElement;
const languageSelectEl = document.getElementById("language-select") as HTMLSelectElement;
const cursorMetricsEl = document.getElementById("cursor-metrics") as HTMLSpanElement;

const editor = monaco.editor.create(document.getElementById("editor") as HTMLElement, {
  value: `struct A {
  let a = 1
  let b = 2
  func abcd() {
    print(a, b)
    let aaa = A()
  }
}`,
  language: "swift",
  automaticLayout: true,
  minimap: { enabled: false },
  theme: "vs-dark",
  fontSize: 14,
});

let projectRoot = "";
let activeFilePath = "";
let debounceTimer: number | null = null;
let languageMode = "swift";
let latestOffset = 0;
let shellCommand = "cursor-info";
let demangleCommand = "demangle";
let lastShellResult: unknown = null;
const demangleCache = new Map<string, string>();

const inferLanguage = (path: string): string => {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  const map: Record<string, string> = {
    swift: "swift",
    ts: "typescript",
    js: "javascript",
    jsx: "javascript",
    tsx: "typescript",
    mjs: "javascript",
    cjs: "javascript",
    py: "python",
    go: "go",
    rs: "rust",
    java: "java",
    kt: "kotlin",
    c: "c",
    cpp: "cpp",
    h: "cpp",
    hpp: "cpp",
    cs: "csharp",
    html: "html",
    css: "css",
    json: "json",
    md: "markdown",
    yaml: "yaml",
    yml: "yaml",
    sh: "shell",
    rb: "ruby",
    php: "php",
  };
  return map[ext] ?? "plaintext";
};

const languages = [
  { value: "auto", label: "Auto (by extension)" },
  { value: "plaintext", label: "Plain Text" },
  { value: "swift", label: "Swift" },
  { value: "typescript", label: "TypeScript" },
  { value: "javascript", label: "JavaScript" },
  { value: "python", label: "Python" },
  { value: "go", label: "Go" },
  { value: "rust", label: "Rust" },
  { value: "java", label: "Java" },
  { value: "kotlin", label: "Kotlin" },
  { value: "cpp", label: "C/C++" },
  { value: "csharp", label: "C#" },
  { value: "html", label: "HTML" },
  { value: "css", label: "CSS" },
  { value: "json", label: "JSON" },
  { value: "markdown", label: "Markdown" },
  { value: "yaml", label: "YAML" },
  { value: "shell", label: "Shell" },
  { value: "ruby", label: "Ruby" },
  { value: "php", label: "PHP" },
];

const applyLanguage = () => {
  const model = editor.getModel();
  if (!model) return;
  const nextLanguage = languageMode === "auto" ? inferLanguage(activeFilePath) : languageMode;
  monaco.editor.setModelLanguage(model, nextLanguage);
};

const updateCursorMetrics = () => {
  const model = editor.getModel();
  const position = editor.getPosition();
  if (!model || !position) return;

  latestOffset = model.getOffsetAt(position);
  cursorMetricsEl.textContent = `Ln ${position.lineNumber}, Col ${position.column}, Offset ${latestOffset}`;
};

for (const language of languages) {
  const option = document.createElement("option");
  option.value = language.value;
  option.textContent = language.label;
  languageSelectEl.appendChild(option);
}
languageSelectEl.value = "swift";
languageSelectEl.onchange = () => {
  languageMode = languageSelectEl.value;
  applyLanguage();
};

const renderTree = (nodes: FileNode[], depth = 0) => {
  for (const node of nodes) {
    const row = document.createElement("div");
    row.className = `node ${node.is_dir ? "dir" : "file"}`;

    const indent = "<span class=\"node-indent\"></span>".repeat(depth);
    if (node.is_dir) {
      row.innerHTML = `${indent}[D] ${node.name}`;
      treeEl.appendChild(row);
      renderTree(node.children ?? [], depth + 1);
      continue;
    }

    row.innerHTML = `${indent}[F] ${node.name}`;
    row.onclick = async () => {
      await openFile(node.path);
      document.querySelectorAll(".node.file.active").forEach((el) => el.classList.remove("active"));
      row.classList.add("active");
    };
    treeEl.appendChild(row);
  }
};

const loadTree = async () => {
  if (!projectRoot) return;
  treeEl.innerHTML = "";
  const nodes = await invoke<FileNode[]>("list_project_tree", { root: projectRoot });
  renderTree(nodes);
};

const openFile = async (filePath: string) => {
  const content = await invoke<string>("read_file", { path: filePath });
  activeFilePath = filePath;
  editorPathEl.textContent = filePath;
  const model = editor.getModel();
  if (model) {
    model.setValue(content);
    applyLanguage();
    editor.setPosition({ lineNumber: 1, column: 1 });
    updateCursorMetrics();
  }
};

const saveCurrentFile = async () => {
  if (!activeFilePath) return;
  const content = editor.getValue();
  await invoke("write_file", { path: activeFilePath, content });
};

updateCursorMetrics();

const copyText = async (value: string) => {
  try {
    await navigator.clipboard.writeText(value);
  } catch {
    const area = document.createElement("textarea");
    area.value = value;
    document.body.appendChild(area);
    area.select();
    document.execCommand("copy");
    document.body.removeChild(area);
  }
};

const stripKeyPrefix = (key: string) => (key.startsWith("key.") ? key.slice(4) : key);

const decodeXmlValue = (raw: string): string => {
  if (!raw.includes("<") || !raw.includes(">")) return raw;
  const parser = new DOMParser();
  const xml = parser.parseFromString(`<root>${raw}</root>`, "text/xml");
  return (xml.documentElement.textContent ?? "").trim();
};

const normalizeUsrForDemangle = (usr: string): string => {
  if (usr.startsWith("s:")) return `$s${usr.slice(2)}`;
  return usr;
};

const matchesSearch = (key: string, value: unknown, keyword: string): boolean => {
  if (!keyword) return true;
  const lower = keyword.toLowerCase();
  if (stripKeyPrefix(key).toLowerCase().includes(lower)) return true;
  if (typeof value === "string") return value.toLowerCase().includes(lower);
  if (typeof value === "number" || typeof value === "boolean") return String(value).toLowerCase().includes(lower);
  if (Array.isArray(value)) return value.some((item, index) => matchesSearch(String(index), item, keyword));
  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>).some(([k, v]) => matchesSearch(k, v, keyword));
  }
  return false;
};

const createCopyButton = (text: string) => {
  const btn = document.createElement("button");
  btn.className = "json-copy-icon";
  btn.textContent = "⧉";
  btn.title = "Copy";
  btn.onclick = async () => {
    await copyText(text);
    btn.textContent = "✓";
    window.setTimeout(() => {
      btn.textContent = "⧉";
    }, 800);
  };
  return btn;
};

const createValueItem = (text: string, label?: string) => {
  const item = document.createElement("div");
  item.className = "json-value-item";

  if (label) {
    const lbl = document.createElement("div");
    lbl.className = "json-sub-label";
    lbl.textContent = label;
    item.appendChild(lbl);
  }

  const box = document.createElement("div");
  box.className = "json-value-box";

  const valueEl = document.createElement("pre");
  valueEl.className = "json-value";
  valueEl.textContent = text;

  const copyBtn = createCopyButton(text);
  box.appendChild(valueEl);
  box.appendChild(copyBtn);
  item.appendChild(box);
  return { item, valueEl };
};

const createLeafRow = (key: string, value: unknown, parent: HTMLElement) => {
  const row = document.createElement("div");
  row.className = "json-row";

  const keyEl = document.createElement("div");
  keyEl.className = "json-key";
  keyEl.textContent = stripKeyPrefix(key);

  const valueWrap = document.createElement("div");
  valueWrap.className = "json-value-wrap";

  const rawText = typeof value === "string" ? value : JSON.stringify(value);
  const rawItem = createValueItem(rawText);
  valueWrap.appendChild(rawItem.item);

  if (typeof value === "string" && value.includes("<") && value.includes(">")) {
    const xmlItem = createValueItem(decodeXmlValue(value), "XML Value");
    valueWrap.appendChild(xmlItem.item);
  }

  if (typeof value === "string" && stripKeyPrefix(key).toLowerCase().includes("usr")) {
    const dmLabel = document.createElement("div");
    dmLabel.className = "json-sub-label";
    dmLabel.textContent = "Demangle Value";

    const dmItem = createValueItem("Loading...");
    const dmValue = dmItem.valueEl;
    valueWrap.appendChild(dmLabel);
    valueWrap.appendChild(dmItem.item);

    const demangleInput = normalizeUsrForDemangle(value);
    const cached = demangleCache.get(demangleInput);
    if (cached !== undefined) {
      dmValue.textContent = cached;
    } else {
      invoke<string>("demangle_usr", { demangleCommand, usr: demangleInput })
        .then((res) => {
          demangleCache.set(demangleInput, res || "??");
          dmValue.textContent = res || "??";
        })
        .catch((err) => {
          const txt = `Error: ${String(err)}`;
          demangleCache.set(demangleInput, txt);
          dmValue.textContent = txt;
        });
    }
  }

  row.appendChild(keyEl);
  row.appendChild(valueWrap);
  parent.appendChild(row);
};

const renderNode = (key: string, value: unknown, parent: HTMLElement, keyword: string) => {
  if (!matchesSearch(key, value, keyword)) return;

  if (value && typeof value === "object") {
    const details = document.createElement("details");
    details.className = "json-group";
    details.open = true;

    const summary = document.createElement("summary");
    summary.className = "json-group-summary";

    const title = document.createElement("span");
    const displayKey = stripKeyPrefix(key);
    if (Array.isArray(value)) {
      title.textContent = `${displayKey}: [${value.length}]`;
    } else {
      title.textContent = `${displayKey}: {${Object.keys(value as Record<string, unknown>).length}}`;
    }

    summary.appendChild(title);
    details.appendChild(summary);

    const body = document.createElement("div");
    body.className = "json-group-body";
    details.appendChild(body);

    if (Array.isArray(value)) {
      value.forEach((item, index) => renderNode(String(index), item, body, keyword));
    } else {
      Object.entries(value as Record<string, unknown>)
        .sort(([a], [b]) => a.localeCompare(b))
        .forEach(([childKey, childValue]) => renderNode(childKey, childValue, body, keyword));
    }

    parent.appendChild(details);
    return;
  }

  createLeafRow(key, value, parent);
};

const renderJsonFields = (result: unknown) => {
  lastShellResult = result;
  shellResultFieldsEl.innerHTML = "";
  const keyword = jsonSearchEl.value.trim();

  if (!result || typeof result !== "object" || Array.isArray(result)) {
    const raw = document.createElement("pre");
    raw.textContent = JSON.stringify(result, null, 2);
    shellResultFieldsEl.appendChild(raw);
    return;
  }

  Object.entries(result as Record<string, unknown>)
    .sort(([a], [b]) => a.localeCompare(b))
    .forEach(([key, value]) => renderNode(key, value, shellResultFieldsEl, keyword));

  if (!shellResultFieldsEl.children.length) {
    const empty = document.createElement("pre");
    empty.textContent = "No matched field.";
    shellResultFieldsEl.appendChild(empty);
  }
};

jsonSearchEl.oninput = () => {
  if (lastShellResult !== null) {
    renderJsonFields(lastShellResult);
  }
};

const runShellHook = async (payload: CursorEventPayload) => {
  const result = await invoke<unknown>("run_shell_on_cursor", {
    shellCommand: shellCommand,
    filePath: payload.filePath,
    code: payload.code,
    offset: payload.offset,
  });
  renderJsonFields(result);
};

const scheduleCursorHook = (payload: CursorEventPayload) => {
  if (debounceTimer !== null) {
    window.clearTimeout(debounceTimer);
  }
  debounceTimer = window.setTimeout(async () => {
    try {
      await runShellHook(payload);
    } catch (error) {
      renderJsonFields({ error: String(error) });
    }
  }, 200);
};

editor.onDidChangeCursorPosition((event) => {
  updateCursorMetrics();
  const currentCode = editor.getValue();
  const filepath = activeFilePath || "__placeholder__.swift";
  scheduleCursorHook({
    filePath: filepath,
    code: currentCode,
    offset: latestOffset,
  });
});

chooseRootBtn.onclick = async () => {
  try {
    const suggestedRoot = await invoke<string>("default_project_root");
    const input = window.prompt("Project root path", projectRoot || suggestedRoot);
    if (!input) return;
    projectRoot = input;
    currentRootEl.textContent = input;
    await loadTree();
  } catch (error) {
    currentRootEl.textContent = `Error: ${String(error)}`;
  }
};

saveFileBtn.onclick = async () => {
  try {
    await saveCurrentFile();
  } catch (error) {
    renderJsonFields({ error: `Save error: ${String(error)}` });
  }
};
