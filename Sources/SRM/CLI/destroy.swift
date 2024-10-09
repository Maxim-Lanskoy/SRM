//
//  destroy.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation

extension SRM {
    struct Destroy: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove SRM CLI setup and clean up generated data.",
            discussion: """
            The `destroy` command removes SRM from your system.

            - Removes PATH entries from shell configuration files.
            - Deletes built binaries and log files.
            """
        )

        func run() throws {
            // Detect shell configuration files
            let shellConfigFiles = [".zshrc", ".bashrc", ".bash_profile", ".profile"]
            var configFileFound = false

            for fileName in shellConfigFiles {
                let configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: configFile.path) {
                    let buildPath = "$(pwd)/.build/release"
                    let exportLine = "export PATH=\"$PATH:\(buildPath)\""

                    // Remove the export line from the shell configuration file
                    var fileContents = try String(contentsOf: configFile, encoding: .utf8)
                    if fileContents.contains(exportLine) {
                        fileContents = fileContents.replacingOccurrences(of: exportLine, with: "")
                        try fileContents.write(to: configFile, atomically: true, encoding: .utf8)
                        print("SRM removed from \(configFile.path).")
                        configFileFound = true
                        break
                    }
                }
            }

            if !configFileFound {
                print("No SRM PATH entry found in shell configuration files.")
            }

            // Delete the binary and the build directory
            let releaseDirectory = FileManager.default.currentDirectoryPath.appending("/.build/release")
            if FileManager.default.fileExists(atPath: releaseDirectory) {
                try FileManager.default.removeItem(atPath: releaseDirectory)
                print("Deleted release directory: \(releaseDirectory).")
            }

            // Delete log and other generated files (if any)
            let logsDirectory = ProcessManager.logsDirectory
            if FileManager.default.fileExists(atPath: logsDirectory.path) {
                try FileManager.default.removeItem(at: logsDirectory)
                print("Deleted logs and generated data at \(logsDirectory.path).")
            } else {
                print("No logs or generated data found.")
            }

            print("SRM destroy process completed.")
            print("Please restart your terminal to apply the changes.")
        }
    }
}
