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

            // Step 2: Get the absolute path of the built SRM binary
            let buildPath = FileManager.default.currentDirectoryPath + "/.build/release"
            let exportLine = "# Swift Running Manager path:\nexport PATH=\"$PATH:\(buildPath)\""

            // Step 3: Set up the PATH for SRM in the shell configuration file
            let shellConfigFiles = [".zshrc", ".bashrc", ".bash_profile", ".profile"]
            var updatedConfigFilePath: URL? = nil

            for fileName in shellConfigFiles {
                let configFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: configFile.path) {
                    var fileContents = try String(contentsOf: configFile, encoding: .utf8)

                    // Check if the export line already exists
                    if !fileContents.contains(exportLine) {
                        // Append the export line if not already present
                        fileContents += "\n" + exportLine + "\n"
                        try fileContents.write(to: configFile, atomically: true, encoding: .utf8)
                        updatedConfigFilePath = configFile
                        print("SRM setup completed successfully in \(configFile.path).")
                    } else {
                        print("The PATH entry already exists in \(configFile.path). Skipping...")
                    }
                    break
                }
            }

            // Step 4: Register monitoring service
            #if os(macOS)
            try setupLaunchdService()
            #elseif os(Linux)
            try setupSystemdService()
            #endif

            // Step 5: Source the shell configuration file to apply changes
            if let configFilePath = updatedConfigFilePath {
                try shellOut(to: "source \(configFilePath.path)")
                print("Applied changes to the current shell environment.")
            }

            // Automatically start the monitoring service in the background
            print("Starting SRM monitor service in the background...")
            let monitorProcess = Process()
            monitorProcess.executableURL = URL(fileURLWithPath: "/bin/sh")
            monitorProcess.arguments = ["-c", "nohup srm monitor > ~/.srm/monitor.log 2>&1 &"]
            monitorProcess.environment = ["SRM_AUTOMATIC_RUN": "true"]

            try monitorProcess.run()
            monitorProcess.waitUntilExit()

            print("SRM monitoring service has been started in the background.")
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

        // Linux-specific systemd setup
        func setupSystemdService() throws {
            let servicePath = "/etc/systemd/system/srm-monitor.service"
            let serviceContent = """
            [Unit]
            Description=SRM Monitoring Service
            After=network.target

            [Service]
            ExecStart=/usr/local/bin/srm monitor
            Restart=always
            RestartSec=5

            [Install]
            WantedBy=multi-user.target
            """
            
            // Write systemd service content
            try serviceContent.write(toFile: servicePath, atomically: true, encoding: .utf8)
            
            // Reload systemd to reflect changes
            print("Reloading systemd daemon...")
            try shellOut(to: "systemctl", arguments: ["daemon-reload"])

            // Check if the service is already enabled
            let serviceStatus = try? shellOut(to: "systemctl", arguments: ["is-active", "srm-monitor"])
            if serviceStatus == "active" {
                print("SRM monitoring service is currently running. Restarting to apply updates...")
                try shellOut(to: "systemctl", arguments: ["restart", "srm-monitor"])
            } else {
                print("Enabling SRM monitoring service...")
                try shellOut(to: "systemctl", arguments: ["enable", "srm-monitor"])
                try shellOut(to: "systemctl", arguments: ["start", "srm-monitor"])
            }
            
            print("SRM monitoring service has been set up with systemd.")
        }
    }
}
