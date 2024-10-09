//
//  logs.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation

extension SRM {
    struct Logs: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "View logs of a process.",
            discussion: """
            The `logs` command displays the logs of a managed process.

            Examples:
              - View last 10 lines: `srm logs MyApp`
              - View last 50 lines: `srm logs MyApp --lines 50`
              - Tail logs in real-time: `srm logs MyApp --follow`
            """
        )

        @Argument(help: "Name of the process to fetch logs for.")
        var name: String

        @Option(name: .shortAndLong, help: "Number of lines to display.")
        var lines: Int = 10

        @Flag(name: .shortAndLong, help: "Tail logs in real-time.")
        var follow: Bool = false

        func run() throws {
            let logFilePath = ProcessManager.logsDirectory.appendingPathComponent("\(name).log").path

            if FileManager.default.fileExists(atPath: logFilePath) {
                if follow {
                    tailLogFile(atPath: logFilePath)
                } else {
                    let logData = try String(contentsOfFile: logFilePath, encoding: .utf8)
                    let logLines = logData.split(separator: "\n").suffix(lines)

                    print("Last \(lines) lines of logs for \(name):")
                    for line in logLines {
                        print(line)
                    }
                }
            } else {
                print("No logs found for process: \(name)")
            }
        }

        func tailLogFile(atPath path: String) {
            guard let fileHandle = FileHandle(forReadingAtPath: path) else {
                print("Unable to open log file.")
                return
            }

            // Move to the end of the file
            fileHandle.seekToEndOfFile()

            print("Tailing logs for \(name). Press Ctrl+C to stop.")

            // Observe the file for new data
            let queue = DispatchQueue.global()
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let logEntry = String(data: data, encoding: .utf8) {
                    print(logEntry, terminator: "")
                }
            }

            // Keep the run loop alive
            RunLoop.current.run()
        }
    }
}
