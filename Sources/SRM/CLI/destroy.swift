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
    struct Destroy: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Remove SRM CLI setup and clean up generated data")
        
        func run() throws {
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? ""
            let configFile: URL
            
            if shell.contains("zsh") {
                configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zshrc")
            } else if shell.contains("bash") {
                configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".bashrc")
            } else {
                print("Unsupported shell. Please manually remove .build/release from your PATH.")
                return
            }
            
            let buildPath = "$(pwd)/.build/release"
            let exportLine = "export PATH=\"$PATH:\(buildPath)\""
            
            // Step 1: Remove the export line from the shell configuration file
            var fileContents = try String(contentsOf: configFile, encoding: .utf8)
            if fileContents.contains(exportLine) {
                fileContents = fileContents.replacingOccurrences(of: exportLine, with: "")
                try fileContents.write(to: configFile, atomically: true, encoding: .utf8)
                print("SRM removed from \(configFile.path).")
            } else {
                print("No SRM setup found in \(configFile.path).")
            }
            
            // Step 2: Delete the binary and the build directory
            let releaseDirectory = FileManager.default.currentDirectoryPath.appending("/.build/release")
            if FileManager.default.fileExists(atPath: releaseDirectory) {
                try FileManager.default.removeItem(atPath: releaseDirectory)
                print("Deleted release directory: \(releaseDirectory).")
            }
            
            // Step 3: Delete log and other generated files (if any)
            let logsDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".srm/logs")
            if FileManager.default.fileExists(atPath: logsDirectory.path) {
                try FileManager.default.removeItem(at: logsDirectory)
                print("Deleted logs and generated data at \(logsDirectory.path).")
            } else {
                print("No logs or generated data found.")
            }
            
            print("SRM destroy process completed.")
            print("Please run `source \(configFile.path)` or restart your terminal to apply the changes.")
        }
    }
}
