# SRM - Swift Running Manager

**SRM** (swift-running-manager) is a command-line tool designed to help manage Swift processes and toolchains in a simplified way. Inspired by PM2 (process management) and swiftly (toolchain management), SRM provides a powerful and easy-to-use interface for developers working with Swift.

## Key Features

- **Process Management:**
  - Start, stop, restart, and monitor Swift applications.
  - Manage multiple Swift applications, similar to PM2 for Node.js.
  
- **Swift Toolchain Management:**
  - Install, update, and manage latest version of the Swift toolchain on macOS, Linux, and ARM-based systems (e.g., Raspberry Pi).
  - Supports downloading Swift toolchains from custom URLs (for Raspberry Pi, using [futurejones/swift-arm64](https://github.com/futurejones/swift-arm64)).

- **Cross-platform Support:**
  - Runs on macOS, Linux, and ARM64 systems (Raspberry Pi and other SBCs).
  
## Installation

### 1. Install SRM

To get started with SRM, clone this repository and build the executable using Swift Package Manager.

```bash
git clone https://github.com/your-username/swift-running-manager.git
cd SRM
swift build -c release
