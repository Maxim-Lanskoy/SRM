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
        static let configuration = CommandConfiguration(
            abstract: "Start the SRM monitoring service (intended to run at system startup only)."
        )

        private var pidFilePath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".srm/monitor.pid")

        func run() throws {
            // Step 1: Prevent manual execution by checking the environment variable
            guard ProcessInfo.processInfo.environment["SRM_AUTOMATIC_RUN"] == "true" else {
                print("The 'srm monitor' command is intended to run automatically at startup only and should not be called manually.")
                return
            }

            // Step 2: Check if the monitor is already running
            if let existingPID = try? String(contentsOf: pidFilePath, encoding: .utf8),
               let pid = Int32(existingPID),
               isProcessRunning(pid: pid) {
                print("SRM monitor is already running with PID: \(pid). Exiting to prevent multiple instances.")
                return
            }

            // Step 3: Write the current process's PID to the PID file
            let currentPID = ProcessInfo.processInfo.processIdentifier
            try "\(currentPID)".write(to: pidFilePath, atomically: true, encoding: .utf8)

            // Step 4: Start the monitoring loop
            print("Starting SRM monitoring service with PID: \(currentPID)...")

            // Step 5: Restart processes that were previously running
            try restartPreviouslyRunningProcesses()

            // Step 6: Monitor the processes
            while true {
                let processInfos = try ProcessManager.fetchAllProcessInfos()

                for var processInfo in processInfos {
                    if processInfo.status == "error" || processInfo.status == "stopped" {
                        continue
                    }

                    if let pid = processInfo.processIdentifier, !isProcessRunning(pid: pid) {
                        if processInfo.restart {
                            print("Process \(processInfo.processName) has stopped. Restarting...")
                            try restartProcess(processInfo: &processInfo)
                        } else {
                            processInfo.status = "stopped"
                            processInfo.processIdentifier = nil
                            processInfo.startTime = nil
                            try ProcessManager.saveProcessInfo(processInfo)
                            print("Process \(processInfo.processName) has stopped and will not be restarted.")
                        }
                    }
                }

                Thread.sleep(forTimeInterval: 5)
            }
        }

        private func restartPreviouslyRunningProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()

            for var processInfo in processInfos {
                if processInfo.status == "running" {
                    print("Restarting process \(processInfo.processName) that was previously running...")
                    try restartProcess(processInfo: &processInfo)
                }
            }
        }

        private func restartProcess(processInfo: inout CodableProcessInfo) throws {
            let name = processInfo.processName
            let executable = processInfo.executable
            let logFilePath = processInfo.logFilePath

            let command = """
            nohup stdbuf -oL \(executable) > \(logFilePath) 2>&1 & echo $! && disown
            """

            do {
                let output = try shellOut(to: command)
                let pidString = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                guard let pid = Int32(pidString) else {
                    throw RuntimeError("Failed to retrieve PID of the restarted process.")
                }

                processInfo.processIdentifier = pid
                processInfo.startTime = Date()
                processInfo.status = "running"
                try ProcessManager.saveProcessInfo(processInfo)

                print("Process \(name) restarted with PID: \(pid).")
            } catch {
                print("Failed to restart process \(name): \(error)")
                processInfo.status = "error"
                processInfo.processIdentifier = nil
                processInfo.startTime = nil
                try ProcessManager.saveProcessInfo(processInfo)
            }
        }

        private func isProcessRunning(pid: Int32) -> Bool {
            return kill(pid, 0) == 0
        }
    }
}
