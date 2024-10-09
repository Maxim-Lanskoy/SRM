//
//  minotor.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 10.10.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Monitor: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Start the SRM monitoring service")

        func run() throws {
            print("Starting SRM monitoring service...")

            while true {
                // Fetch all process info files
                let processInfos = try ProcessManager.fetchAllProcessInfos()

                for processInfo in processInfos {
                    // Check if process is running
                    let pid = processInfo.processIdentifier
                    if !isProcessRunning(pid: pid) {
                        if processInfo.restart {
                            print("Process \(processInfo.processName) has stopped. Restarting...")
                            // Restart the process
                            try restartProcess(processInfo: processInfo)
                        } else {
                            // Remove process info as it is no longer running
                            try ProcessManager.removeProcessInfo(for: processInfo.processName)
                            print("Process \(processInfo.processName) has stopped and will not be restarted.")
                        }
                    }
                }

                // Sleep for 5 seconds before the next check
                Thread.sleep(forTimeInterval: 5)
            }
        }

        func isProcessRunning(pid: Int32) -> Bool {
            return kill(pid, 0) == 0
        }

        func restartProcess(processInfo: CodableProcessInfo) throws {
            let name = processInfo.processName
            let executable = processInfo.executable
            let logFilePath = processInfo.logFilePath

            // Build the command to start the process with nohup and redirect output to log file
            let command = "nohup \(executable) >> \(logFilePath) 2>&1 & echo $!"

            // Run the command and capture the output (PID)
            let output = try shellOut(to: command)
            let pidString = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard let pid = Int32(pidString) else {
                throw RuntimeError("Failed to retrieve PID of the restarted process.")
            }

            // Update process info with new PID and start time
            let updatedProcessInfo = CodableProcessInfo(
                processName: name,
                processIdentifier: pid,
                startTime: Date(),
                restart: processInfo.restart,
                executable: executable,
                logFilePath: logFilePath
            )
            try ProcessManager.saveProcessInfo(updatedProcessInfo)

            print("Process \(name) restarted with PID: \(pid).")
        }
    }
}
