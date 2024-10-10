//
//  start.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut
import Dispatch

extension SRM {
    struct Start: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Start a new process managed by SRM.",
            discussion: """
            The `start` command allows you to run any executable, script, or command as a managed process.

            Examples:
              - Start a Swift app: `srm start /path/to/app --name MyApp`
              - Start a shell script: `srm start ./script.sh --name MyScript`
              - Start a command: `srm start "python script.py" --name PythonScript`

            Options:
              - Start all stopped processes: `srm start all`
              - You can specify a custom name using `--name`.
              - Use `--restart` to automatically restart the process if it crashes.
              - Use `--watch` to start the process and display its output in real-time.
            """
        )

        @Argument(help: "The script, command, or executable to run, or 'all' to start all stopped processes.")
        var executableOrName: String?
        
        @Option(name: .shortAndLong, help: "Specify a custom name for the process.")
        var name: String?
        
        @Flag(name: .shortAndLong, help: "Automatically restart the process if it exits unexpectedly.")
        var restart: Bool = false

        @Flag(name: .long, help: "Start the process and display its output in real-time.")
        var watch: Bool = false

        func run() throws {
            if executableOrName?.lowercased() == "all" {
                try startAllProcesses()
            } else if let executable = executableOrName {
                // Start a new process with the provided executable
                try startProcess(executable: executable, name: name, restart: restart, watch: watch)
            } else {
                print("Please provide an executable to start or 'all' to start all stopped processes.")
            }
        }

        func startProcess(executable: String, name: String?, restart: Bool, watch: Bool) throws {
            let processName = name ?? URL(fileURLWithPath: executable).lastPathComponent
            print("Starting process: \(processName)")
            
            // Ensure logs directory exists
            try FileManager.default.createDirectory(at: ProcessManager.logsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            let logFileURL = ProcessManager.logsDirectory.appendingPathComponent("\(processName).log")
            
            // Rotate log if it exceeds size limit (e.g., 5 MB)
            let maxLogSize: UInt64 = 5 * 1024 * 1024 // 5 MB
            if let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
               let fileSize = attributes[FileAttributeKey.size] as? UInt64,
               fileSize > maxLogSize {
                // Move current log to archived log with timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmmss"
                let timestamp = dateFormatter.string(from: Date())
                let archivedLogPath = ProcessManager.logsDirectory.appendingPathComponent("\(processName)_\(timestamp).log")
                try FileManager.default.moveItem(atPath: logFileURL.path, toPath: archivedLogPath.path)
                print("Rotated log file to \(archivedLogPath.lastPathComponent)")
            }
            
            if watch {
                // Start the process in the foreground and capture output
                try startProcessWithWatch(executable: executable, processName: processName, logFileURL: logFileURL, restart: restart)
            } else {
                // Start the process in the background as before
                try startProcessInBackground(executable: executable, processName: processName, logFileURL: logFileURL, restart: restart)
            }
        }

        func startProcessWithWatch(executable: String, processName: String, logFileURL: URL, restart: Bool) throws {
            let process = Process()
            // Split the executable and its arguments
            let arguments = splitCommandLine(executable)
            guard let executablePath = arguments.first else {
                throw RuntimeError("Executable path is empty.")
            }
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = Array(arguments.dropFirst())
            
            // Set up pipes to capture output
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            // Create or open the log file
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
            }
            let logFileHandle = try FileHandle(forWritingTo: logFileURL)
            logFileHandle.seekToEndOfFile()
            
            // Start the process
            try process.run()
            
            let pid = process.processIdentifier
            
            // Save process info with status "running"
            let processInfo = CodableProcessInfo(
                processName: processName,
                processIdentifier: pid,
                startTime: Date(),
                restart: restart,
                executable: executable,
                logFilePath: logFileURL.path,
                status: "running"
            )
            try ProcessManager.saveProcessInfo(processInfo)
            
            print("Process \(processName) started with PID: \(pid). Press Ctrl+C to stop.")
            
            // Handle SIGINT (Ctrl+C) using DispatchSourceSignal
            // Ignore default handling of SIGINT
            signal(SIGINT, SIG_IGN)
            
            // Create a DispatchSourceSignal for SIGINT
            let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
            signalSource.setEventHandler {
                print("\nReceived interrupt signal. Terminating process \(processName)...")
                process.terminate()
                signalSource.cancel()
            }
            signalSource.resume()
            
            // Set up a dispatch group to wait for both output and error streams
            let dispatchGroup = DispatchGroup()
            
            // Handle standard output
            dispatchGroup.enter()
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    dispatchGroup.leave()
                } else {
                    // Write to log file
                    logFileHandle.write(data)
                    // Print to terminal
                    if let output = String(data: data, encoding: .utf8) {
                        print(output, terminator: "")
                        fflush(stdout)
                    }
                }
            }
            
            // Handle standard error
            dispatchGroup.enter()
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    dispatchGroup.leave()
                } else {
                    // Write to log file
                    logFileHandle.write(data)
                    // Print to terminal (you may want to format errors differently)
                    if let output = String(data: data, encoding: .utf8) {
                        fputs(output, stderr)
                        fflush(stderr)
                    }
                }
            }
            
            // Wait for the process to exit
            process.waitUntilExit()
            
            // Wait for output handling to finish
            dispatchGroup.wait()
            
            // Close file handles
            logFileHandle.closeFile()
            outputPipe.fileHandleForReading.closeFile()
            errorPipe.fileHandleForReading.closeFile()
            
            // Cancel the signal source
            signalSource.cancel()
            
            // Restore default signal handling
            signal(SIGINT, SIG_DFL)
            
            // Update process info to reflect that the process has exited
            var updatedProcessInfo = processInfo
            updatedProcessInfo.status = "stopped"
            updatedProcessInfo.processIdentifier = nil
            updatedProcessInfo.startTime = nil
            try ProcessManager.saveProcessInfo(updatedProcessInfo)
            
            print("\nProcess \(processName) has exited.")
        }

        func startProcessInBackground(executable: String, processName: String, logFileURL: URL, restart: Bool) throws {
            // Prepare the command
            let command = """
            nohup stdbuf -oL \(executable) > \(logFileURL.path) 2>&1 & echo $! && disown

            """
            
            // Prepare the process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]
            
            // Create a pipe to capture the PID output
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            // Start the process
            try process.run()
            process.waitUntilExit()
            
            // Read the PID from the output
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let pidString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let pid = Int32(pidString) {
                
                // Save process info with status "running"
                let processInfo = CodableProcessInfo(
                    processName: processName,
                    processIdentifier: pid,
                    startTime: Date(),
                    restart: restart,
                    executable: executable,
                    logFilePath: logFileURL.path,
                    status: "running"
                )
                try ProcessManager.saveProcessInfo(processInfo)
                
                print("Process \(processName) started with PID: \(pid).")
            } else {
                throw RuntimeError("Failed to retrieve PID of the started process.")
            }
        }

        func startAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            let stoppedProcesses = processInfos.filter { $0.status == "stopped" || $0.status == "error" }
            
            if stoppedProcesses.isEmpty {
                print("No stopped processes to start.")
                return
            }
            
            for processInfo in stoppedProcesses {
                try startProcess(executable: processInfo.executable, name: processInfo.processName, restart: processInfo.restart, watch: false)
            }
        }
        
        private func splitCommandLine(_ commandLine: String) -> [String] {
            var args = [String]()
            var currentArg = ""
            var isInQuotes = false
            var iterator = commandLine.makeIterator()
            while let char = iterator.next() {
                if char == "\"" {
                    isInQuotes.toggle()
                } else if char == " " && !isInQuotes {
                    if !currentArg.isEmpty {
                        args.append(currentArg)
                        currentArg = ""
                    }
                } else {
                    currentArg.append(char)
                }
            }
            if !currentArg.isEmpty {
                args.append(currentArg)
            }
            return args
        }

    }
}
