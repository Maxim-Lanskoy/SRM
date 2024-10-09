//
//  setup.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation

extension SRM {
    struct Setup: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Setup the SRM CLI globally.",
            discussion: """
            The `setup` command builds the SRM tool and adds it to your PATH.

            - Detects your shell and updates the appropriate configuration file.
            - Supports zsh, bash, and other common shells.
            """
        )

        func run() throws {
            // Step 1: Build the release version
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["swift", "build", "-c", "release"]

            try process.run()
            process.waitUntilExit()

            let result = process.terminationStatus
            if result != 0 {
                throw RuntimeError("Build failed.")
            }

            // Step 2: Check if '.build/release' is in the user's PATH
            let buildPath = "$(pwd)/.build/release"
            let currentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""

            if !currentPath.contains(buildPath) {
                print("Adding .build/release to PATH...")

                // Detect shell configuration files
                let shellConfigFiles = [".zshrc", ".bashrc", ".bash_profile", ".profile"]
                var configFileFound = false

                for fileName in shellConfigFiles {
                    let configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fileName)
                    if FileManager.default.fileExists(atPath: configFile.path) {
                        // Add the .build/release path to the shell configuration file if not already present
                        let exportLine = "export PATH=\"$PATH:\(buildPath)\""
                        try appendToShellConfig(configFile: configFile, exportLine: exportLine)
                        print("SRM setup completed successfully in \(configFile.path).")
                        print("Please run `source \(configFile.path)` or restart your terminal to apply the changes.")
                        configFileFound = true
                        break
                    }
                }

                if !configFileFound {
                    print("No supported shell configuration file found. Please manually add .build/release to your PATH.")
                }
            } else {
                print(".build/release is already in PATH.")
            }
        }

        // Helper function to append to the shell config file only if the export line doesn't exist
        func appendToShellConfig(configFile: URL, exportLine: String) throws {
            let fileContent = (try? String(contentsOf: configFile)) ?? ""
            if !fileContent.contains(exportLine) {
                // Append export line only if it doesn't already exist
                if FileManager.default.fileExists(atPath: configFile.path) {
                    let fileHandle = try FileHandle(forWritingTo: configFile)
                    fileHandle.seekToEndOfFile()
                    if let data = ("\n" + exportLine + "\n").data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                } else {
                    // If the config file doesn't exist, create it and add the line
                    try exportLine.write(to: configFile, atomically: true, encoding: .utf8)
                }
            } else {
                print("The PATH entry already exists in \(configFile.path). Skipping...")
            }
        }
    }
}
