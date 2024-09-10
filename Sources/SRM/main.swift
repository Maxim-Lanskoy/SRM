import Foundation

let processManager = ProcessManager()

let args = CommandLine.arguments

if args.count > 1 {
    let command = args[1]
    switch command {
    case "start":
        guard args.count > 2 else {
            print("Error: You must provide an application name to start.")
            exit(1)
        }
        let appName = args[2]
        processManager.startProcess(appName: appName)
    case "stop":
        guard args.count > 2 else {
            print("Error: You must provide an application name to stop.")
            exit(1)
        }
        let appName = args[2]
        processManager.stopProcess(appName: appName)
    case "restart":
        guard args.count > 2 else {
            print("Error: You must provide an application name to restart.")
            exit(1)
        }
        let appName = args[2]
        processManager.restartProcess(appName: appName)
    case "list":
        processManager.listProcesses()
    case "logs":
        guard args.count > 2 else {
            print("Error: You must provide an application name to view logs.")
            exit(1)
        }
        let appName = args[2]
        processManager.showLogs(appName: appName)
    default:
        print("Unknown command: \(command)")
        printUsage()
    }
} else {
    printUsage()
}

func printUsage() {
    print("""
    Usage: srm <command> [args]
    
    Commands:
      start <app>    Start a process
      stop <app>     Stop a running process
      restart <app>  Restart a process
      list           List all running processes
      logs <app>     Show logs for a process
    """)
}
