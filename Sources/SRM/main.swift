import ArgumentParser
import Foundation
import ShellOut

// Define RuntimeError type
struct RuntimeError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

// Define SRM structure without the @main attribute
struct SRM: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Swift Running Manager (SRM)",
        subcommands: [Start.self, Stop.self, List.self, Logs.self, HelpCommand.self, Setup.self, Destroy.self],
        defaultSubcommand: HelpCommand.self
    )
    
    struct HelpCommand: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Detailed help")

        func run() throws {
            print("""
            SRM - Swift Running Manager
            Available commands:
            - start: Start a process
            - stop: Stop a process
            - list: List all running processes
            - logs: View logs of a process
            """)
        }
    }
}

SRM.main()
