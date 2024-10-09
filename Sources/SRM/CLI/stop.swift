//
//  stop.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Stop: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Stop a running process managed by SRM.",
            discussion: """
            The `stop` command stops a running process by its name.

            Example:
              - Stop a process: `srm stop MyApp`
            """
        )

        @Argument(help: "Name of the process to stop.")
        var name: String

        func run() throws {
            print("Stopping process: \(name)")

            do {
                guard let processInfo = try ProcessManager.fetchProcessInfo(for: name) else {
                    print("No process found with name: \(name)")
                    return
                }

                let pid = processInfo.processIdentifier
                if isProcessRunning(pid: pid) {
                    #if os(Windows)
                    // Windows-specific kill command
                    let command = "taskkill /PID \(pid) /F"
                    #else
                    // Unix-like kill command
                    let command = "kill \(pid)"
                    #endif
                    try shellOut(to: command)
                    print("Process \(name) with PID \(pid) has been stopped.")
                } else {
                    print("Process \(name) is not running.")
                }

                // Remove process info after stopping
                try ProcessManager.removeProcessInfo(for: name)
            } catch {
                print("An error occurred: \(error.localizedDescription)")
            }
        }

        func isProcessRunning(pid: Int32) -> Bool {
            #if os(Windows)
            // Windows-specific implementation
            // Placeholder: Implement process checking for Windows
            return false
            #else
            return kill(pid, 0) == 0
            #endif
        }
    }
}
