import Foundation

struct ProcessManager {

    func startProcess(appName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")  // Use `/usr/bin/env` to run Swift from the environment
        process.arguments = ["swift", "run", appName]
        
        // Redirect output to log file
        let logFilePath = "/var/log/\(appName).log"  // Log file path
        let logFile = FileHandle(forWritingAtPath: logFilePath) ?? FileHandle.standardOutput
        
        process.standardOutput = logFile
        process.standardError = logFile
        
        // Start the process
        do {
            try process.run()
            let pid = process.processIdentifier  // Get the actual PID of the process
            ProcessStateTracker.addProcess(appName: appName, pid: pid)
            Logger.log("Started process \(appName) with PID \(pid)")
        } catch {
            Logger.log("Failed to start process \(appName): \(error)")
        }
    }

    func stopProcess(appName: String) {
        let pid = ProcessStateTracker.getProcessId(appName: appName)
        if pid != -1 {
            ShellExecutor.execute("kill \(pid)")
            ProcessStateTracker.removeProcess(appName: appName)
            Logger.log("Stopped process \(appName)")
        } else {
            Logger.log("Process \(appName) not found")
        }
    }

    func restartProcess(appName: String) {
        stopProcess(appName: appName)
        startProcess(appName: appName)
        Logger.log("Restarted process \(appName)")
    }

    func listProcesses() {
        let processes = ProcessStateTracker.getRunningProcesses()
        for process in processes {
            print("Process: \(process.name), PID: \(process.pid), Status: \(process.status)")
        }
    }

    func showLogs(appName: String) {
        let logFilePath = "/var/log/\(appName).log"  // Adjust to match your actual log directory
        let logs = ShellExecutor.execute("cat \(logFilePath)")
        print(logs)
    }
}
