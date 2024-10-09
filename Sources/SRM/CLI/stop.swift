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

            Examples:
              - Stop a process: `srm stop MyApp`
              - Stop all processes: `srm stop --all`
            """
        )

        @Argument(help: "Name of the process to stop.")
        var name: String?

        @Flag(name: .shortAndLong, help: "Stop all running processes.")
        var all: Bool = false

        func run() throws {
            if all {
                try stopAllProcesses()
            } else if let processName = name {
                try stopProcess(named: processName)
            } else {
                print("Please specify a process name or use '--all' to stop all processes.")
            }
        }

        func stopProcess(named name: String) throws {
            print("Stopping process: \(name)")

            do {
                guard var processInfo = try ProcessManager.fetchProcessInfo(for: name) else {
                    print("No process found with name: \(name)")
                    return
                }

                if let pid = processInfo.processIdentifier, isProcessRunning(pid: pid) {
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

                // Update process info to set status to "stopped" and remove pid and startTime
                processInfo.status = "stopped"
                processInfo.processIdentifier = nil
                processInfo.startTime = nil
                try ProcessManager.saveProcessInfo(processInfo)
            } catch {
                print("An error occurred: \(error.localizedDescription)")
            }
        }

        func stopAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if processInfos.isEmpty {
                print("No processes to stop.")
                return
            }

            for processInfo in processInfos {
                try stopProcess(named: processInfo.processName)
            }
        }

        func isProcessRunning(pid: Int32) -> Bool {
            #if os(Windows)
            // Windows-specific implementation
            return false // Placeholder
            #else
            return kill(pid, 0) == 0
            #endif
        }
    }
}
