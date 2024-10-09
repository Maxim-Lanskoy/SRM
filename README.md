# 🚀 SRM - Swift Running Manager

SRM is a lightweight, Swift-based command-line tool designed to help you manage, monitor, and control various processes, including Swift applications, shell scripts, binaries, and commands. Inspired by [PM2](https://pm2.keymetrics.io), it provides an intuitive interface for starting, stopping, monitoring processes, and viewing real-time logs.

## ✨ Features

- 🚦 **Process Management**: Start, stop, and restart processes like commands, binaries, or Swift applications.
- 📊 **Monitoring**: List all running processes with real-time tracking, including CPU and memory usage.
- 📜 **Logging**: Automatically store and fetch logs for each process, with support for real-time log tailing.
- ♻️ **Auto-Restart**: Automatically restart processes if they crash, ensuring continuous uptime.
- 🔄 **Log Rotation**: Prevent log files from becoming too large with automatic log rotation.
- 🎯 **Flexibility**: Run shell commands, executables, or scripts seamlessly.
- 🖥 **Cross-Platform**: Compatible with macOS and Linux systems, supporting both `bash` and `zsh` shells.

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

   This command builds SRM and adds it to your `$PATH`, making it accessible from anywhere in your terminal.

3. **Source Your Shell:**

   Depending on your shell and operating system, run:

   - For **macOS (ZSH)** users:

     ```bash
     source ~/.zshrc
     ```

   - For **Linux (Bash)** users:

     ```bash
     source ~/.bashrc
     ```

   - For **Other shells**: Restart your terminal session to apply the changes.

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

#### 2. Stopping a Process:

Stop a running process by its name:

```bash
srm stop ProcessName
```

This command will stop the process and remove its logs from SRM.

#### 3. Listing Processes:

See a list of all active processes and their status, including CPU and memory usage:

```bash
srm list
```

You can also use the alias:

```bash
srm ls
```

#### 4. Viewing Logs:

- **Fetch the latest 10 lines of logs from any process:**

  ```bash
  srm logs ProcessName
  ```

- **View a specific number of lines:**

  ```bash
  srm logs ProcessName --lines 50
  ```

- **Tail logs in real-time:**

  ```bash
  srm logs ProcessName --follow
  ```

#### 5. Monitoring Processes:

Start the SRM monitoring service to automatically restart processes if they crash (required if using the `--restart` flag):

```bash
srm monitor
```

**Note:** To run the monitor in the background:

```bash
nohup srm monitor > /dev/null 2>&1 &
```

## 🔄 Running SRM Setup Again

If, for any reason, SRM is no longer available in your `$PATH`, or you want to rebuild the tool binary, you can re-run the setup command:

```bash
srm setup
```

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
- **Log Rotation**: SRM automatically rotates logs when they exceed 5 MB to prevent log files from becoming too large.
- **Auto-Restart**: Use the `--restart` flag when starting a process to have SRM automatically restart it if it crashes. Ensure the monitoring service is running with `srm monitor`.
- **Aliases**: Use `srm ls` as a shortcut for `srm list`.
