//
//  list.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all running processes.",
            discussion: """
            The `list` command displays all processes currently managed by SRM.

            Example:
              - List processes: `srm list`
            """,
            aliases: ["ls"]
        )

        func run() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()

            if processInfos.isEmpty {
                print("No running processes found.")
                return
            }

            print(String(format: "%-20s %-8s %-8s %-8s %-20s", "Name", "PID", "CPU%", "MEM%", "Start Time"))
            for processInfo in processInfos {
                let pid = processInfo.processIdentifier
                if isProcessRunning(pid: pid) {
                    let cpuUsage = getCPUUsage(pid: pid)
                    let memUsage = getMemoryUsage(pid: pid)
                    let startTime = formatDate(processInfo.startTime)

                    print(String(format: "%-20s %-8d %-8s %-8s %-20s", processInfo.processName, pid, cpuUsage, memUsage, startTime))
                } else {
                    // Process is not running, remove its info
                    try? ProcessManager.removeProcessInfo(for: processInfo.processName)
                }
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

        func getCPUUsage(pid: Int32) -> String {
            #if os(Linux)
            let command = "ps -p \(pid) -o %cpu --no-headers"
            #elseif os(macOS)
            let command = "ps -p \(pid) -o %cpu | tail -1"
            #else
            return "N/A"
            #endif

            do {
                let output = try shellOut(to: command)
                return output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } catch {
                return "N/A"
            }
        }

        func getMemoryUsage(pid: Int32) -> String {
            #if os(Linux)
            let command = "ps -p \(pid) -o %mem --no-headers"
            #elseif os(macOS)
            let command = "ps -p \(pid) -o %mem | tail -1"
            #else
            return "N/A"
            #endif

            do {
                let output = try shellOut(to: command)
                return output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } catch {
                return "N/A"
            }
        }

        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
    }
}
