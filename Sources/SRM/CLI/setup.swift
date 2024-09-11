//
//  File.swift
//  
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Setup: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Setup the SRM CLI globally")
        
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
                
                // Step 3: Detect the shell type and corresponding config file
                let shell = ProcessInfo.processInfo.environment["SHELL"] ?? ""
                let configFile: URL
                var shellType = ""
                
                if shell.contains("zsh") {
                    configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zshrc")
                    shellType = "zsh"
                } else if shell.contains("bash") {
                    configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".bashrc")
                    shellType = "bash"
                } else {
                    print("Unsupported shell. Please manually add .build/release to your PATH.")
                    return
                }
                
                // Step 4: Add the .build/release path to the shell configuration file if not already present
                let exportLine = "export PATH=\"$PATH:\(buildPath)\""
                try appendToShellConfig(configFile: configFile, exportLine: exportLine)
                
                // Step 5: Provide shell-specific advice
                print("SRM setup completed successfully.")
                switch shellType {
                case "zsh":
                    print("Please run `source ~/.zshrc` or restart your terminal to apply the changes.")
                case "bash":
                    print("Please run `source ~/.bashrc` or restart your terminal to apply the changes.")
                default:
                    print("Please restart your terminal to apply the changes.")
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
