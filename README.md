# 🚀 SRM - Swift Running Manager

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMaxim-Lanskoy%2FSRM%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Maxim-Lanskoy/SRM)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMaxim-Lanskoy%2FSRM%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Maxim-Lanskoy/SRM)

SRM is a lightweight, Swift-based command-line tool designed to help you manage, monitor, and control various processes, including Swift applications, shell scripts, binaries, and commands. Inspired by [PM2](https://pm2.keymetrics.io), it provides an intuitive interface for starting, stopping, monitoring processes, and viewing real-time logs.

## ✨ Features

- 🚦 **Process Management**: Start, stop, restart, and delete processes like commands, binaries, or Swift applications.
- 📊 **Monitoring**: List all processes with real-time tracking, including CPU and memory usage.
- 📜 **Logging**: Automatically store and fetch logs for each process, with real-time log tailing by default.
- ❗ **Process Statuses**: Processes retain their status (`running`, `stopped`, `error`), even if they fail to start.
- ♻️ **Auto-Restart**: Automatically restart processes if they crash, ensuring continuous uptime.
- 🔄 **Log Rotation**: Prevent log files from becoming too large with automatic log rotation.
- 🎯 **Flexibility**: Run shell commands, executables, or scripts seamlessly.
- 🖥 **Cross-Platform**: Compatible with macOS and Linux systems, supporting both `bash` and `zsh` shells.
- 🚀 **Automatic Monitoring**: SRM supports an automatic monitoring service that runs at system startup, ensuring all previously running processes are restored.

## 📋 Prerequisites

To use SRM, ensure you have [Swift 5.9](https://www.swift.org/install/) or later installed on your system. Here's how to install Swift:

### macOS Installation

On macOS, you may already have Swift if you're using Xcode. You can also install Swift via [Homebrew](https://formulae.brew.sh/formula/swift):

```bash
brew install swift
```

### Linux Installation (Ubuntu/Debian/Fedora-based systems)

For Linux-based distributions like Ubuntu, Debian, Fedora, or Raspbian, you can install the Swift toolchain manager [Swiftly](https://github.com/Maxim-Lanskoy/Swiftly) with a one-liner:

```bash
curl -s https://raw.githubusercontent.com/Maxim-Lanskoy/Swiftly/main/install/swiftly-install.sh | bash
```

### Other Linux Distributions

For distributions such as Arch or others, please follow the official Swift [installation guide](https://www.swift.org/getting-started/) for Linux.

## 🛠️ Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/Maxim-Lanskoy/SRM.git
   cd SRM
   ```

2. **Run SRM Setup:**

   Build and set up SRM to ensure it's globally available:

   ```bash
   swift run srm setup
   ```

   This command builds SRM, adds it to your `$PATH`, and sets up the monitoring service to start with the system.

## 🏃 Usage

SRM offers a variety of commands to manage and monitor processes, scripts, and executables.

### 🔧 General Commands

#### 1. Starting a Process:

- **Start any command, executable, or script with a custom name:**

  ```bash
  srm start "watch -n 5 free -m" --name MemoryMonitor
  ```

- **Running a Swift application:**

  ```bash
  srm start /path/to/swift/app --name SwiftApp
  ```

- **Running a Shell Script:**

  ```bash
  srm start ./myscript.sh --name ScriptRunner
  ```

- **Running a Python Script:**

  ```bash
  srm start "python script.py" --name PythonScript
  ```

- **Automatically restart a process if it crashes:**

  ```bash
  srm start ./myapp --name MyApp --restart
  ```

- **Start all stopped processes:**

  ```bash
  srm start all
  ```

#### 2. Stopping a Process:

- **Stop a running process by its name:**

  ```bash
  srm stop ProcessName
  ```

- **Stop a process by index:**

  ```bash
  srm stop 1
  ```

- **Stop all managed processes:**

  ```bash
  srm stop all
  ```

#### 3. Restarting a Process:

- **Restart a process by its name:**

  ```bash
  srm restart ProcessName
  ```

- **Restart a process by index:**

  ```bash
  srm restart 1
  ```

- **Restart all processes:**

  ```bash
  srm restart all
  ```

#### 4. Deleting a Process:

- **Delete a process from SRM by its name:**

  ```bash
  srm delete ProcessName
  ```

- **Delete a process by index:**

  ```bash
  srm delete 1
  ```

- **Delete all processes from SRM:**

  ```bash
  srm delete all
  ```

#### 5. Listing Processes:

See a numbered list of all processes and their statuses, including CPU and memory usage:

```bash
srm list
```

You can also use the alias:

```bash
srm ls
```

**Example Output:**

```
┌───────┬───────────────┬──────────┬───────┬──────┬──────┬─────────────────────┐
│ Index │ Name          │ Status   │ PID   │ CPU% │ MEM% │ Start Time          │
├───────┼───────────────┼──────────┼───────┼──────┼──────┼─────────────────────┤
│ 1     │ MyApp         │ running  │ 12345 │ 2.3  │ 1.5  │ 2024-10-11 12:34:56 │
├───────┼───────────────┼──────────┼───────┼──────┼──────┼─────────────────────┤
│ 2     │ FailedProcess │ error    │ 0     │ N/A  │ N/A  │ N/A                 │
├───────┼───────────────┼──────────┼───────┼──────┼──────┼─────────────────────┤
│ 3     │ StoppedProcess│ stopped  │ 0     │ N/A  │ N/A  │ N/A                 │
└───────┴───────────────┴──────────┴───────┴──────┴──────┴─────────────────────┘
```

#### 6. Viewing Logs:

- **Fetch the latest 10 lines and follow logs from any process:**

  ```bash
  srm logs ProcessName
  ```

- **View a specific number of lines and follow:**

  ```bash
  srm logs ProcessName --lines 50
  ```

- **View logs without following:**

  ```bash
  srm logs ProcessName --no-follow
  ```

- **View logs for all processes:**

  ```bash
  srm logs all
  ```

#### 7. Monitoring Processes:

The SRM monitoring service automatically starts with the system, restoring any processes that were previously running. It also tracks the status of all processes and attempts to restart those marked with `--restart`, up to a maximum of 15 restart attempts.

**Note:** The `srm monitor` command is now intended to run automatically at system startup only and should not be called manually.

## 🔄 Running SRM Setup Again

If, for any reason, SRM is no longer available in your `$PATH`, or you want to rebuild the tool binary, you can re-run the setup command:

```bash
srm setup
```

This command will also re-register the monitoring service.

## 🔥 Destroying SRM

If you wish to completely remove SRM from your system:

```bash
srm destroy
```

This will:

- Remove SRM from your `$PATH`.
- Delete any saved logs and generated files.
- Delete the compiled binaries from your system.

## 👨‍💻 How It Works

SRM relies on the [ShellOut](https://github.com/JohnSundell/ShellOut) library to handle process execution, logging, and management. ShellOut enables SRM to use shell commands, run scripts, or execute binaries directly from Swift code.

## 📖 Detailed Command Help

For detailed help on each command and its options, use the `--help` flag:

```bash
srm <command> --help
```

**Example:**

```bash
srm start --help
```

This will display usage instructions, available options, and examples for the command.

## 🖥 Compatibility

SRM is compatible with:

- **Operating Systems**: macOS and Linux.
- **Shells**: `bash`, `zsh`, and other common shells.

## 💡 Tips

- **Process Names**: If you don't specify a process name using `--name`, SRM will use the executable's name by default.
- **Process Statuses**: SRM keeps track of each process's status (`running`, `stopped`, `error`), allowing you to monitor and debug processes effectively.
- **Viewing Logs for Failed Processes**: You can view logs for processes that failed to start to help debug issues.
- **Log Rotation**: SRM automatically rotates logs when they exceed 5 MB to prevent log files from becoming too large.
- **Auto-Restart**: Use the `--restart` flag when starting a process to have SRM automatically restart it if it crashes. The monitoring service runs automatically to facilitate this feature.
- **Process Indexing**: Use the index number from `srm list` to refer to processes in commands.
- **Aliases**: Use `srm ls` as a shortcut for `srm list`.
