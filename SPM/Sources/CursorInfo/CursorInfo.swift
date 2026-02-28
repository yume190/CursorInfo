import Foundation
import ArgumentParser
import SourceKittenFramework

@main
struct CursorInfo: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Return SourceKit cursor info as JSON."
    )

    @Option(name: .long, help: "Absolute or relative source file path.")
    var filepath: String

    @Option(name: .long, help: "Inline source code. If provided, it takes precedence over --filepath.")
    var code: String?

    @Option(name: .long, help: "Zero-based cursor offset.")
    var offset: Int

    @Option(name: .long, help: "Input mode: file | swiftpm.")
    var kind: Kind = .file

    mutating func run() throws {
        guard offset >= 0 else {
            printErrorJSON("offset must be >= 0")
            throw ExitCode.failure
        }

        switch kind {
        case .file:
            runFile()
        case .swiftpm:
            printErrorJSON("kind=swiftpm is not implemented yet")
            throw ExitCode.failure
        }
    }
    
    private func runFile() {
        do {
            let client: SKClient
            if let code {
                client = SKClient(code: code, sdk: .macosx)
            } else {
                client = try SKClient(path: filepath, sdk: .macosx)
            }
            try client.editorOpen()
            defer {
                _ = try? client.editorClose()
            }
            let response = try client.cursorInfo(offset)
            let json = try JSONSerialization.data(withJSONObject: response)
            print(String(data: json, encoding: .utf8) ?? "")
        } catch {
            printErrorJSON(String(describing: error))
            Self.exit(withError: ExitCode.failure)
        }
    }

    private func printErrorJSON(_ message: String) {
        let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
        print("{\"ok\":false,\"error\":\"\(escaped)\"}")
    }
}

enum Kind: String, ExpressibleByArgument {
    case file
    case swiftpm
}
