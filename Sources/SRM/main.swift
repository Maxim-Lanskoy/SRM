//
//  main.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation

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
        subcommands: [
            Start.self,
            Stop.self,
            List.self,
            Logs.self,
            Monitor.self,
            Setup.self,
            Destroy.self,
            HelpCommand.self
        ],
        defaultSubcommand: HelpCommand.self
    )

    struct HelpCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "help",
            abstract: "Display help information"
        )

        func run() throws {
            print("""
            SRM - Swift Running Manager
            Usage: srm <command> [options]

            Commands:
                start     Start a process
                stop      Stop a process
                list (ls) List all running processes
                logs      View logs of a process
                monitor   Start the monitoring service
                setup     Setup SRM
                destroy   Remove SRM setup
                help      Display this help information

            Use 'srm <command> --help' for more information on a command.
            """)
        }
    }
}

SRM.main()
