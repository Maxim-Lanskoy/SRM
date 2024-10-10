//
//  restart.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 10.10.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Restart: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Restart a process managed by SRM.",
            discussion: """
            The `restart` command restarts a process by its name or index.

            Examples:
              - Restart a process by name: `srm restart MyApp`
              - Restart a process by index: `srm restart 1`
              - Restart all processes: `srm restart all`
            """
        )

        @Argument(help: "Name or index of the process to restart, or 'all' to restart all processes.")
        var nameOrIndex: String

        func run() throws {
            if nameOrIndex.lowercased() == "all" {
                try restartAllProcesses()
            } else if let index = Int(nameOrIndex) {
                // Restart process by index
                try restartProcess(atIndex: index)
            } else {
                // Restart process by name
                try restartProcess(named: nameOrIndex)
            }
        }

        func restartProcess(named name: String) throws {
            print("Restarting process: \(name)")

            guard let processInfo = try ProcessManager.fetchProcessInfo(for: name) else {
                print("No process found with name: \(name)")
                return
            }

            // Stop the process if it's running
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
            }

            // Update process info to set status to "stopped"
            var updatedProcessInfo = processInfo
            updatedProcessInfo.status = "stopped"
            updatedProcessInfo.processIdentifier = nil
            updatedProcessInfo.startTime = nil
            try ProcessManager.saveProcessInfo(updatedProcessInfo)

            // Start the process again
            var startCommand = Start()
            startCommand.executableOrName = processInfo.executable
            startCommand.name = processInfo.processName
            startCommand.restart = processInfo.restart
            try startCommand.run()
        }


        func restartProcess(atIndex index: Int) throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if index < 1 || index > processInfos.count {
                print("Invalid process index: \(index)")
                return
            }

            let processInfo = processInfos[index - 1]
            try restartProcess(named: processInfo.processName)
        }

        func restartAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if processInfos.isEmpty {
                print("No processes to restart.")
                return
            }

            for processInfo in processInfos {
                try restartProcess(named: processInfo.processName)
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
