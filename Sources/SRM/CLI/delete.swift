//
//  delete.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 10.10.2024.
//

import ArgumentParser
import Foundation

extension SRM {
    struct Delete: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Delete a process from SRM.",
            discussion: """
            The `delete` command removes a process from SRM's management.

            Examples:
              - Delete a process by name: `srm delete MyApp`
              - Delete a process by index: `srm delete 1`
              - Delete all processes: `srm delete all`
            """
        )

        @Argument(help: "Name or index of the process to delete, or 'all' to delete all processes.")
        var nameOrIndex: String

        func run() throws {
            if nameOrIndex.lowercased() == "all" {
                try deleteAllProcesses()
            } else if let index = Int(nameOrIndex) {
                // Delete process by index
                try deleteProcess(atIndex: index)
            } else {
                // Delete process by name
                try deleteProcess(named: nameOrIndex)
            }
        }

        func deleteProcess(named name: String) throws {
            print("Deleting process: \(name)")

            guard let processInfo = try ProcessManager.fetchProcessInfo(for: name) else {
                print("No process found with name: \(name)")
                return
            }

            // Remove process info
            try ProcessManager.removeProcessInfo(for: name)

            // Remove log file
            let logFilePath = processInfo.logFilePath
            if FileManager.default.fileExists(atPath: logFilePath) {
                try FileManager.default.removeItem(atPath: logFilePath)
            }

            print("Process \(name) has been deleted from SRM.")
        }

        func deleteProcess(atIndex index: Int) throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if index < 1 || index > processInfos.count {
                print("Invalid process index: \(index)")
                return
            }

            let processInfo = processInfos[index - 1]
            try deleteProcess(named: processInfo.processName)
        }

        func deleteAllProcesses() throws {
            let processInfos = try ProcessManager.fetchAllProcessInfos()
            if processInfos.isEmpty {
                print("No processes to delete.")
                return
            }

            for processInfo in processInfos {
                try deleteProcess(named: processInfo.processName)
            }
        }
    }
}
