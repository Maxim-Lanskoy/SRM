import ArgumentParser
import Foundation

// Define RuntimeError type
struct RuntimeError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

// Define SRM structure without the @main attribute
struct SRM: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "Swift Running Manager (SRM)",
        subcommands: [Start.self, Stop.self, List.self, Logs.self, HelpCommand.self, Setup.self, Destroy.self],
        defaultSubcommand: HelpCommand.self
    )
    
    struct Start: ParsableCommand {
        @Argument(help: "Script or executable name to run")
        var executable: String

        @Option(name: .shortAndLong, help: "Specify process name")
        var name: String

        func run() throws {
            print("Starting process: \(name)")
            // Starting process code...
        }
    }
    
    struct Stop: ParsableCommand {
        @Argument(help: "Name of the process to stop")
        var name: String

        func run() throws {
            print("Stopping process: \(name)")
            // Stopping process code...
        }
    }
    
    struct List: ParsableCommand {
        func run() throws {
            print("Listing all running processes...")
            // Listing processes code...
        }
    }

    struct Logs: ParsableCommand {
        func run() throws {
            print("Fetching logs...")
            // Fetch logs code...
        }
    }

    struct HelpCommand: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Detailed help")

        func run() throws {
            print("""
            SRM - Swift Running Manager
            Available commands:
            - start: Start a process
            - stop: Stop a process
            - list: List all running processes
            - logs: View logs of a process
            """)
        }
    }
}

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
            let currentPath = ProcessInfo().environment["PATH"] ?? ""
            
            if !currentPath.contains(buildPath) {
                print("Adding .build/release to PATH...")
                
                // Step 3: Detect the shell type and corresponding config file
                let shell = ProcessInfo().environment["SHELL"] ?? ""
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

    // Command to remove the SRM setup (remove from PATH)
    struct Destroy: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Remove SRM CLI setup and clean up generated data")
        
        func run() throws {
            let shell = ProcessInfo().environment["SHELL"] ?? ""
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
                print("Please run `source \(configFile.path)` or restart your terminal to apply the changes.")
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
        }
    }
}


SRM.main()
