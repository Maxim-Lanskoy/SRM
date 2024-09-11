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
    struct Stop: ParsableCommand {
        @Argument(help: "Name of the process to stop")
        var name: String
        
        func run() throws {
            print("Stopping process: \(name)")
            
            // Fetch process info (PID) from the saved JSON file
            do {
                if let processInfo = try ProcessManager.fetchProcessInfo(for: name) {
                    let pid = processInfo.processIdentifier
                    let command = "kill \(pid)"
                    
                    // Use ShellOut to kill the process by PID
                    try shellOut(to: command)
                    
                    // Remove the process info after stopping
                    try ProcessManager.removeProcessInfo(for: name)
                    
                    print("Process \(name) stopped successfully.")
                } else {
                    print("No running process found with name: \(name)")
                }
            } catch {
                print("Failed to stop process: \(error)")
            }
        }
    }
}
