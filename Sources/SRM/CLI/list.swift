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
                print("No processes found.")
                return
            }
            
            // Print header
            print("Name    PID    CPU%    MEM%    Start Time")
            
            for processInfo in processInfos {
                var status = processInfo.status
                let pid = processInfo.processIdentifier ?? 0
                let startTime = processInfo.startTime != nil ? formatDate(processInfo.startTime!) : "N/A"
                var cpuUsage = "N/A"
                var memUsage = "N/A"
                
                if let pid = processInfo.processIdentifier, isProcessRunning(pid: pid) {
                    cpuUsage = getCPUUsage(pid: pid)
                    memUsage = getMemoryUsage(pid: pid)
                    status = "running"
                } else if status == "running" {
                    // Process was marked as running but is no longer running
                    status = "stopped"
                }
                //print(String(format: "%-20s %-10s %-8d %-8s %-8s %-20s", processInfo.processName, status, pid, cpuUsage, memUsage, startTime))
                print("Name: \(processInfo.processName), PID: \(pid), CPU%: \(cpuUsage), MEM%: \(memUsage), Start Time: \(startTime)")
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
