# 🚀 SRM - Swift Running Manager

SRM is a lightweight, Swift-based command-line tool designed to help you manage, monitor, and control various processes, including Swift applications, shell scripts, binaries, and commands. Inspired by [PM2](https://pm2.keymetrics.io), it provides an intuitive interface for starting, stopping, monitoring processes, and viewing real-time logs.

## ✨ Features

- 🚦 Process Management: Start, stop, restart processes like commands, binaries, or Swift applications.
- 📊 Monitoring: List all running processes with real-time tracking.
- 📜 Logging: Automatically store and fetch logs for each process.
- 🎯 Flexibility: Run shell commands, executables, or scripts seamlessly.

## 📋 Prerequisites

To use SRM, ensure you have [Swift 5.9](https://www.swift.org/install/) or later installed on your system. Here's how to install Swift:

### macOS Installation

On macOS, you possibly already have Swift if using Xcode. You can also install Swift via [Homebrew](https://formulae.brew.sh/formula/swift):

```bash
brew install swift
```

### Linux Installation (Ubuntu/Debian/Fedora-based systems)

For Linux-based distributions (like Ubuntu, Debian, Fedora, Raspbian), you can install Swift toolchain manager [swiftly](https://github.com/Maxim-Lanskoy/Swiftly) with a one-liner:

```bash
curl -s https://raw.githubusercontent.com/Maxim-Lanskoy/Swiftly/main/install/swiftly-install.sh | bash
```

### Other Linux Distributions

For distributions such as Arch or others, please follow the official Swift [installation guide](https://www.swift.org/getting-started/) for Linux.

## 🛠️ Installation

1. #### Clone the repository:

  ```bash
  git clone https://github.com/yourusername/SRM.git
  cd SRM
  ```

2. #### Build the project:

  Run the following command to build SRM:

```bash
swift build -c release
```

3. #### Run SRM Setup:

  After building, run the setup to ensure SRM is globally available:

```bash
swift run srm setup
```

This command adds SRM to your $PATH and makes it available from anywhere in your terminal.

4. #### Sourcing Your Shell:

Depending on your shell, run:

- For ZSH users: ```source ~/.zshrc```
- For BASH users: ```source ~/.bashrc```


## 🏃 Usage

SRM offers a variety of commands to manage and monitor processes, scripts, and executables.

### 🔧 General Commands

#### 1. Starting a Process:

- Start any command, executable, or script with a custom name:

  ```bash
  srm run "watch -n 5 free -m" --name MemoryMonitor
  ```

- Running a Swift application:
  
  ```bash
  srm run /path/to/swift/app --name SwiftApp
  ```

- Running a Shell Script:
  
  ```bash
  srm run ./myscript.sh --name ScriptRunner
  ```

#### 2. Stopping a Process:

Stop a running process by its name:  

```bash
srm stop MemoryMonitor
```

This will send a ```SIGTERM``` signal to the process and remove its logs from SRM.

#### 3. Listing Processes:

See a list of all active processes and their status:

```bash
srm list
```

#### 4. Viewing Logs:

Fetch the latest 10 lines of logs from any process:

```bash
srm logs MemoryMonitor
```

## 🔄 Running SRM Setup Again

If for any reason SRM is no longer available in your path, you can re-run the setup command:

```bash
swift run srm setup
```

## 🔥 Destroying SRM

If you wish to completely remove SRM from your system:

```bash
srm destroy
```

This will:

- Remove SRM from the $PATH;
- Delete any saved logs and generated files;
- Delete the compiled binaries from your system.

## 👨‍💻 How It Works

SRM relies on a forked and improved version of the [ShellOut](https://github.com/Maxim-Lanskoy/ShellOut) library to handle process execution, logging, and management. ShellOut enables SRM to shell out to bash commands, run scripts, or execute binaries directly from Swift code.

## 💻 ShellOut Pre-defined Commands:
You can also directly use some pre-defined commands using [ShellOut](https://github.com/Maxim-Lanskoy/ShellOut) inside your Swift scripts:

- #### Git Commands:

  ```swift
  try shellOut(to: .gitClone(url: repositoryURL))
  try shellOut(to: .gitCommit(message: "Commit message"))
  ```

- #### File System:

  ```swift
  try shellOut(to: .createFolder(named: "folderName"))
  try shellOut(to: .readFile(at: "Podfile"))
  ```

### Example Swift Code Using ShellOut:

```swift
import ShellOut

do {
    let result = try shellOut(to: "echo Hello World")
    print(result)  // Outputs: Hello World
} catch {
    print("Error executing command: \(error)")
}
```
