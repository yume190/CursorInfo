import Foundation

func arg(_ name: String) -> String? {
    guard let index = CommandLine.arguments.firstIndex(of: name), index + 1 < CommandLine.arguments.count else {
        return nil
    }
    return CommandLine.arguments[index + 1]
}

let file = arg("--file") ?? ""
let line = arg("--line") ?? "0"
let column = arg("--column") ?? "0"

let output: [String: String] = [
    "event": "cursor_moved",
    "file": file,
    "line": line,
    "column": column,
    "note": "Replace this script with your own Swift logic."
]

if let data = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted]),
   let text = String(data: data, encoding: .utf8) {
    print(text)
} else {
    print("{\"event\":\"cursor_moved\"}")
}
