import Foundation

struct ShellExecutor {

    @discardableResult
    static func execute(_ command: String) -> String {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output
    }
}
