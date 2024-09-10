import Foundation

struct ProcessStateTracker {
    private static var processes: [ProcessInfo] = []

    static func addProcess(appName: String, pid: Int32) {
        let process = ProcessInfo(name: appName, pid: pid, status: "Running")
        processes.append(process)
    }

    static func removeProcess(appName: String) {
        processes.removeAll { $0.name == appName }
    }

    static func getProcessId(appName: String) -> Int32 {
        return processes.first { $0.name == appName }?.pid ?? -1
    }

    static func getRunningProcesses() -> [ProcessInfo] {
        return processes
    }
}
