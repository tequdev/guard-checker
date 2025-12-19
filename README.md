# Guard Checker

A repository for providing binaries.

## Overview

This repository fetches source code from [Xahau/xahaud](https://github.com/Xahau/xahaud) as a git submodule and builds binaries for multiple platforms to release them.

## Installation

To install the latest release binary:

```bash
curl -fsSL https://raw.githubusercontent.com/Xahau/guard-checker/main/install.sh | bash
```

Or download and run manually:

```bash
curl -fsSL https://raw.githubusercontent.com/Xahau/guard-checker/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The script will automatically detect your OS, architecture, and libc type, then download and install the appropriate binary.

You can specify a custom installation directory using the `INSTALL_DIR` environment variable:

```bash
INSTALL_DIR=$HOME/.local/bin ./install.sh
```

## Setup

### Cloning the Repository

When cloning for the first time, include submodules:

```bash
git clone --recursive git@github.com:Xahau/guard-checker.git
```

To update submodules to an existing repository:

```bash
git submodule update --init --recursive
```

### Updating Submodule to a Specific Branch

To update the submodule to track a specific branch:

```bash
cd xahaud
git checkout <branch-name>
git pull origin <branch-name>
cd ..
git add xahaud
git commit -m "Update submodule to <branch-name>"
```

Alternatively, you can configure the submodule to track a specific branch:

```bash
git config -f .gitmodules submodule.xahaud.branch <branch-name>
git submodule update --remote
git add .gitmodules xahaud
git commit -m "Update submodule to track <branch-name> branch"
```

### Local Build

To build locally:

```bash
cd xahaud/src/ripple/app/hook
make
```

## Release Process

1. Create and push a git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions will automatically build binaries for the following platforms:
   - **Linux**: x64 (gnu/musl), arm64 (gnu/musl), x86 (gnu/musl), arm (gnu/musl)
   - **macOS**: x64, arm64

3. Once the build completes, a GitHub Release will be automatically created and all binaries will be uploaded.

## Binary Naming Convention

Binary names follow the format below:

- Linux: `guard-checker-linux-{arch}-{libc}`
  - Examples: `guard-checker-linux-x64-gnu`, `guard-checker-linux-arm64-musl`
- macOS: `guard-checker-macos-{arch}`
  - Examples: `guard-checker-macos-x64`, `guard-checker-macos-arm64`

## Supported Platforms

| OS | Architecture | Libc | Binary Name |
|---|---|---|---|
| Linux | x64 | gnu | `guard-checker-linux-x64-gnu` |
| Linux | x64 | musl | `guard-checker-linux-x64-musl` |
| Linux | arm64 | gnu | `guard-checker-linux-arm64-gnu` |
| Linux | arm64 | musl | `guard-checker-linux-arm64-musl` |
| Linux | x86 | gnu | `guard-checker-linux-x86-gnu` |
| Linux | x86 | musl | `guard-checker-linux-x86-musl` |
| Linux | arm | gnu | `guard-checker-linux-arm-gnu` |
| Linux | arm | musl | `guard-checker-linux-arm-musl` |
| macOS | x64 | - | `guard-checker-macos-x64` |
| macOS | arm64 | - | `guard-checker-macos-arm64` |
