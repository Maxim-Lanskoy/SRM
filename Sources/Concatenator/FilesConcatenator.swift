//
//  FilesConcatenator.swift
//  DaradanayaTales
//
//  Created by Maxim Lanskoy on 01.10.2024.
//

import Foundation

@main
struct SwiftFileConcatenator {
    static let projectRoot = "/Users/maximlanskoy/SRM/"
    static let outputFilePath = "\(projectRoot)/Sources/Concatenator/ConcatenatedSwiftFiles.txt"
    
    static var asciiTree: String? {
        if let rootNode = buildTree(at: URL(fileURLWithPath: "\(projectRoot)/Sources")) {
            return rootNode.renderTree()
        } else {
            print("No Swift files found in the directory.")
            return nil
        }
    }
    
    // Updated header structure
    static var systemInstructions = ""/*"""
    **System Instructions:**
    // Use the provided request and concatenated code to address the user's issue or implement new features. 
    // Return only the runnable Swift code block without any markdown syntax (no "```swift" or "```").
    // Ensure the code includes necessary imports, the main structure, and all relevant functions.
    // The code should be self-contained and executable when placed into `result.swift`.
    // Do not include any explanations, comments, or repeated parts from the input code.
    """*/
    
    static var requestHeader = "\n\n**Request: \"-=-=-=-\".**\n\n"
    
    static var additionalInfo = """
    Hi! I'm making SRM (Swift Running Manager).
    
    Executable cli Swift tool project description:
    SRM is a command-line tool written in Swift that functions as a process manager, similar to pm2. It is designed to manage and monitor the execution of various scripts, commands, executables, or applications on macOS and Linux systems. SRM allows users to start, stop, restart, and monitor processes, as well as view logs and manage process lifecycles.

    Purpose:
    The primary goal of SRM is to provide developers and system administrators with a lightweight and efficient tool to manage long-running processes without the need to modify the code of the processes being managed. It is particularly useful for running and monitoring scripts or applications where source code modification is not feasible.

    Key Features:
    Process Management Commands:
    start: Start a new process or all stopped processes.
    Supports specifying a custom name for the process.
    Includes a --restart flag to automatically restart processes if they exit unexpectedly.
    Introduces a --watch flag to display real-time output of the process.
    stop: Stop a running process by name or index, or stop all processes.
    restart: Restart a process by name or index, or restart all processes.
    list (ls): List all managed processes with details like status, PID, CPU and memory usage, and start time.
    logs: View logs of a process by name or index, or view logs for all processes.
    Supports tailing logs in real-time or viewing the last N lines.
    Monitoring Service:
    monitor: Start a monitoring service that checks the health of managed processes and restarts them if they crash (when --restart is enabled).
    Setup and Cleanup:
    setup: Sets up SRM by building the release version and adding it to the system PATH.
    destroy: Removes SRM setup and associated files.
    Process Information Management:
    Stores process information in JSON files for persistence across sessions.
    Manages log files, including log rotation when files exceed a specified size.
    Cross-Platform Support:
    Designed to work on macOS and Linux systems.
    Uses Swift's Process API for process execution and management.
    No Dependency on Modifying Managed Processes:
    Capable of managing processes without requiring changes to their source code.
    Handles output buffering issues by providing the --watch flag to capture and display process output in real-time.
    Similarities to pm2:

    Like pm2, SRM allows for the management of multiple processes, providing start, stop, and restart functionalities.
    Offers process monitoring and automatic restarts for crashed processes.
    Provides logging capabilities and real-time output viewing.
    Use Cases:

    Managing background services or daemons.
    Running and monitoring scripts or applications written in Swift, Python, shell, or other languages.
    Deploying applications that need to run continuously and be monitored for crashes or unexpected exits.
    Environments where modifying the source code of the managed processes is not possible or desirable.
    Additional Information:

    Logging: SRM manages log files for each process, storing them in a designated logs directory (~/.srm/logs). It supports log rotation to prevent uncontrolled growth of log files.
    Process Identification: Processes can be managed by name or by their index in the process list.
    Extensibility: The tool is designed with extensibility in mind, allowing for future enhancements and additional features as needed.
    User-Friendly Interface: Provides clear and concise command-line output, including tables for listing processes and helpful messages for user actions.
    Example Commands:

    Start a process and display its output:
    css
    Copy code
    srm start /path/to/app --name MyApp --watch
    Stop a process by name:
    arduino
    Copy code
    srm stop MyApp
    View logs for a process:
    Copy code
    srm logs MyApp
    List all managed processes:
    Copy code
    srm list
    Conclusion:

    SRM aims to be a simple yet powerful tool for process management in the development and deployment of applications. By providing essential features similar to pm2, it helps users manage processes effectively without the overhead of larger process management systems.
    """

    static var swiftFilesAndContent = ""
    
    // Build the directory tree
    static func buildTree(at url: URL) -> DirectoryNode? {
        let nodeName = url.lastPathComponent
        let node = DirectoryNode(name: nodeName)
        var containsSwiftFiles = false
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            let sortedContents = contents.sorted {
                if $0.hasDirectoryPath && !$1.hasDirectoryPath {
                    return true
                } else if !$0.hasDirectoryPath && $1.hasDirectoryPath {
                    return false
                } else {
                    return $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased()
                }
            }
            
            for fileURL in sortedContents {
                if fileURL.hasDirectoryPath {
                    if let subdirectoryNode = buildTree(at: fileURL), !subdirectoryNode.subdirectories.isEmpty || !subdirectoryNode.files.isEmpty {
                        node.subdirectories.append(subdirectoryNode)
                        containsSwiftFiles = true
                    }
                } else if fileURL.pathExtension == "swift" &&
                         !fileURL.lastPathComponent.contains("Logger") &&
                         !fileURL.lastPathComponent.contains("FilesConcatenator") &&
                         !fileURL.lastPathComponent.contains("Constants") {
                    node.files.append(fileURL)
                    containsSwiftFiles = true
                    
                    // Collect Swift file content
                    if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                        swiftFilesAndContent += "\n// File: \(fileURL.lastPathComponent) | Path: \(fileURL.path)\n"
                        swiftFilesAndContent += fileContent.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
                    }
                }
            }
        } catch {
            print("Error reading directory contents: \(error.localizedDescription)")
        }
        
        return containsSwiftFiles ? node : nil
    }
    
    static func main() {
        print("Project Root: \(projectRoot)")
        
        let tree = "\nProject File Structure:\n\(asciiTree ?? "No Swift files found in the directory.")"
        let result = systemInstructions + requestHeader + additionalInfo + tree + swiftFilesAndContent
        
        do {
            try result.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
            print("Successfully concatenated all Swift files into: \(outputFilePath)")
        } catch {
            print("Error writing to output file: \(error.localizedDescription)")
        }
    }
}

// Define a class to represent directories and files in a tree structure
class DirectoryNode {
    let name: String
    var subdirectories: [DirectoryNode] = []
    var files: [URL] = []
    
    init(name: String) {
        self.name = name
    }
    
    // Recursively build the ASCII tree structure
    func renderTree(indent: String = "") -> String {
        var result = "\(indent)📁 \(name)\n"
        let subIndent = indent + "    "
        
        // Add files
        for file in files {
            result += "\(subIndent)📄 \(file.lastPathComponent)\n"
        }
        
        // Add subdirectories
        for subdirectory in subdirectories {
            result += subdirectory.renderTree(indent: subIndent)
        }
        
        return result
    }
}
