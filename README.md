# SRM - Swift Running Manager

SRM is a Swift-based command-line tool designed to manage and monitor Swift applications, inspired by PM2. SRM allows you to easily start, stop, restart, and monitor processes, and provides real-time process tracking.

## Features

- **Process Management**: Start, stop, restart Swift processes.
- **Monitoring**: Check the status of running processes.
- **Logging**: Keep track of process logs and monitor errors.
- **Real-time Process Tracking**: Automatically updates the status of running processes.

## Prerequisites

- **Swift 5.8 or later**

Optionally, you can install Swift on Debian-based systems using the following script:

```bash
curl -s https://raw.githubusercontent.com/Maxim-Lanskoy/Swiftly/main/install/swiftly-install.sh | bash
```

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/SRM.git
cd SRM
```

Build the project:

```bash
swift build
```

Run SRM:

```bash
swift run srm
```

## Usage

### Starting a Process

You can start a Swift process with the following command:

```bash
srm start myApp.swift --name myApp
```

### Stopping a Process

Stop a running process:

```bash
srm stop myApp
```

### Restarting a Process

Restart a process:

```bash
srm restart myApp
```

### Monitoring Processes

List all running processes and their statuses:

```bash
srm list
```

### Real-time Logs

You can monitor logs in real-time:

```bash
srm logs myApp
```
