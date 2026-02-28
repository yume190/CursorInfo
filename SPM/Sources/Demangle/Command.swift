import Foundation
import ArgumentParser

@main
struct Demangle: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Demangle Swift symbol names."
    )

    @Option(name: .long, help: "Inline source code. If provided, it takes precedence over --filepath.")
    var usr: String

    mutating func run() throws {
        print(_Swift.demangle(usr) ?? "??")
    }
}
