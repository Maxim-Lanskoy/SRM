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
    static var systemInstructions = """
    **System Instructions:** 
    // Use the provided request and concatenated code to address the user's issue or implement new features. 
    // Return only the runnable Swift code block without any markdown syntax (no "```swift" or "```").
    // Ensure the code includes necessary imports, the main structure, and all relevant functions.
    // The code should be self-contained and executable when placed into `result.swift`.
    // Do not include any explanations, comments, or repeated parts from the input code.
    """
    
    static var requestHeader = "\n\n**Request: \"-=-=-=-\".**\n\n"
    
    static var additionalInfo = """
    **Project Details:** SRM This is a lightweight, Swift-based command-line tool designed to help manage, monitor, and control various processes, including Swift applications, shell scripts, binaries, and commands. Inspired by PM2, it provides an intuitive interface for starting, stopping, monitoring processes, and viewing real-time logs.
        
    **✨ Features**
    - 🚦 Process Management: Start, stop, restart processes like commands, binaries, or Swift applications.
    - 📊 Monitoring: List all running processes with real-time tracking.
    - 📜 Logging: Automatically store and fetch logs for each process.
    - 🎯 Flexibility: Run shell commands, executables, or scripts seamlessly.
      
    **🏃 Usage**
    SRM should offer a variety of commands to manage and monitor processes, scripts, and executables.
    🔧 General Commands should look similar to this list.
    1. Starting a Process:
    - Start any command, executable, or script with a custom name:
        "srm start "watch -n 5 free -m" --name MemoryMonitor"
    - Running a Swift application:
        "srm start /path/to/swift/app --name SwiftApp"
    - Running a Shell Script:
        "srm start ./myscript.sh --name ScriptRunner"
    2. Stopping a Process:
    - Stop a running process by its name:
        "srm stop ProcessName"
    - This will send a SIGTERM signal to the process and remove its logs from SRM.
    3. Listing Processes:
    - See a list of all active processes and their status:
        "srm list"
    4. Viewing Logs:
    - Fetch the latest 10 lines of logs from any process:
        "srm logs ProcessName"
    
    This is basic info about SRM tool overall vision and expected features.
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
