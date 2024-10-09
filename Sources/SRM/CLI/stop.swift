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
            The `stop` command stops a running process by its name or index.

            Examples:
              - Stop a process by name: `srm stop MyApp`
              - Stop a process by index: `srm stop 1`
              - Stop all processes: `srm stop all`
            """
        )
        
        @Argument(help: "Name or index of the process to stop, or 'all' to stop all processes.")
        var nameOrIndex: String

        func run() throws {
            if nameOrIndex.lowercased() == "all" {
                try stopAllProcesses()
            } else if let index = Int(nameOrIndex) {
                // Stop process by index
                try stopProcess(atIndex: index)
            } else {
                // Stop process by name
                try stopProcess(named: nameOrIndex)
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

        func stopProcess(atIndex index: Int) throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if index < 1 || index > processInfos.count {
                print("Invalid process index: \(index)")
                return
            }

            let processInfo = processInfos[index - 1]
            try stopProcess(named: processInfo.processName)
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
