//
//  setup.swift
//  Swift Running Manager
//
//  Created by Maxim Lanskoy on 11.09.2024.
//

import ArgumentParser
import Foundation
import ShellOut

extension SRM {
    struct Setup: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Setup the SRM CLI globally.",
            discussion: """
            The `setup` command builds the SRM tool and adds it to your PATH.
            """
        )

        func run() throws {
            // Step 1: Create necessary directories
            try createRequiredDirectories()

            // Step 2: Build the release version
            try buildRelease()

            // Step 3: Set up PATH
            try setupPath()

            // Step 4: Set up service based on OS
            try setupService()
            
            print("\n✨ SRM setup completed successfully!")
            print("🚀 Type 'srm --help' command for info.")
        }

        private func createRequiredDirectories() throws {
            // Create .srm directory in home
            let srmDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".srm")
            try FileManager.default.createDirectory(at: srmDir, withIntermediateDirectories: true, attributes: nil)
            
            // Create logs directory
            try FileManager.default.createDirectory(at: ProcessManager.logsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Set proper permissions
            try shellOut(to: "chmod", arguments: ["755", srmDir.path])
            try shellOut(to: "chmod", arguments: ["755", ProcessManager.logsDirectory.path])
        }

        private func buildRelease() throws {
            print("Building SRM in release mode...")
            try shellOut(to: "swift build -c release")
        }

        private func setupPath() throws {
            let buildPath = FileManager.default.currentDirectoryPath + "/.build/release"
            let exportLine = "\n# Swift Running Manager path:\nexport PATH=\"$PATH:\(buildPath)\"\n"
            
            // Try to modify shell config files
            let shellConfigFiles = [".bashrc", ".zshrc", ".bash_profile", ".profile"]
            var configUpdated = false
            var updatedConfigPath: String? = nil
            
            // Detect current shell
            let currentShell = try? shellOut(to: "echo $SHELL")
            
            for fileName in shellConfigFiles {
                let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: configPath.path) {
                    var content = (try? String(contentsOf: configPath, encoding: .utf8)) ?? ""
                    if !content.contains(buildPath) {
                        content += exportLine
                        try content.write(to: configPath, atomically: true, encoding: .utf8)
                        print("Updated PATH in \(fileName)")
                        configUpdated = true
                        updatedConfigPath = configPath.path
                        break
                    }
                }
            }
            
            if !configUpdated {
                print("Warning: Could not update PATH in any shell configuration file.")
                return
            }
            
            // Re-source the environment based on the current shell
            if let configPath = updatedConfigPath {
                print("\nApplying changes to current shell environment...")
                
                // Attempt to source the updated config file
                if let shell = currentShell?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    do {
                        switch shell {
                        case let sh where sh.hasSuffix("/bash"):
                            try shellOut(to: "bash -c 'source \(configPath)'")
                            print("Sourced bash configuration.")
                        case let sh where sh.hasSuffix("/zsh"):
                            try shellOut(to: "zsh -c 'source \(configPath)'")
                            print("Sourced zsh configuration.")
                        default:
                            // For other shells, try a generic source approach
                            try shellOut(to: "source \(configPath)")
                            print("Attempted to source shell configuration.")
                        }
                        // Export the PATH directly for the current session
                        try shellOut(to: "export PATH=\"$PATH:\(buildPath)\"")
                        
                        print("\nEnvironment has been updated successfully.")
                        print("Note: Some shells may require you to start a new terminal session for changes to take full effect.")
                    } catch {
                        print("\nWarning: Could not automatically apply changes to the current shell.")
                        print("Please run the following command manually or start a new terminal session:")
                        print("    source \(configPath)")
                    }
                }
            }
        }

        private func setupService() throws {
            #if os(Linux)
            try setupSystemdService()
            #elseif os(macOS)
            try setupLaunchdService()
            #endif
        }

        private func setupSystemdService() throws {
            let serviceContent = """
            [Unit]
            Description=SRM Monitoring Service
            After=network.target

            [Service]
            Type=simple
            User=\(NSUserName())
            Environment="SRM_AUTOMATIC_RUN=true"
            ExecStart=\(FileManager.default.currentDirectoryPath)/.build/release/srm monitor
            Restart=always
            RestartSec=5

            [Install]
            WantedBy=multi-user.target
            """

            // First try user service
            let userServiceDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config/systemd/user")
            
            do {
                try FileManager.default.createDirectory(at: userServiceDir,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
                let servicePath = userServiceDir.appendingPathComponent("srm-monitor.service")
                try serviceContent.write(to: servicePath, atomically: true, encoding: .utf8)
                
                // Enable and start the user service
                try shellOut(to: "systemctl --user daemon-reload")
                try shellOut(to: "systemctl --user enable srm-monitor")
                try shellOut(to: "systemctl --user start srm-monitor")
                
                print("SRM monitor service has been set up as a user service.")
            } catch {
                print("Warning: Could not set up user service. Error: \(error)")
                print("Attempting to set up system service (requires sudo)...")
                
                // Create temporary file
                let tempFile = "/tmp/srm-monitor.service"
                try serviceContent.write(toFile: tempFile, atomically: true, encoding: .utf8)
                
                // Move to system directory using sudo
                try shellOut(to: "sudo mv \(tempFile) /etc/systemd/system/srm-monitor.service")
                try shellOut(to: "sudo systemctl daemon-reload")
                try shellOut(to: "sudo systemctl enable srm-monitor")
                try shellOut(to: "sudo systemctl start srm-monitor")
                
                print("SRM monitor service has been set up as a system service.")
            }
        }
        
        // macOS-specific launchd setup
        func setupLaunchdService() throws {
            let plistPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/com.srm.monitor.plist")
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.srm.monitor</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/local/bin/srm</string>
                    <string>monitor</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <true/>
            </dict>
            </plist>
            """
            
            // Write plist content
            try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
            
            // Check if the service is already loaded
            let loadStatus = try? shellOut(to: "launchctl", arguments: ["list", "com.srm.monitor"])
            if loadStatus != nil {
                print("SRM monitoring service already exists. Unloading to apply updates...")
                try shellOut(to: "launchctl", arguments: ["unload", plistPath.path])
            }
            
            // Load the new service
            try shellOut(to: "launchctl", arguments: ["load", plistPath.path])
            print("SRM monitoring service has been loaded with launchd.")
        }
    }
}
