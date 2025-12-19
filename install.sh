#!/bin/sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository information
REPO_OWNER="tequdev"
REPO_NAME="guard-checker"
BINARY_NAME="guard-checker"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

# Detect architecture
detect_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)   echo "x64" ;;
        aarch64|arm64)  echo "arm64" ;;
        i386|i686)      echo "x86" ;;
        armv7l|armv6l) echo "arm" ;;
        *)              echo "$arch" ;;
    esac
}

# Detect libc (Linux only)
detect_libc() {
    if [ "$(detect_os)" != "linux" ]; then
        echo ""
        return
    fi
    
    # Check if musl is available
    if ldd --version 2>&1 | grep -q musl; then
        echo "musl"
    else
        echo "gnu"
    fi
}

# Get latest release tag
get_latest_release() {
    api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    tag=$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$tag" ]; then
        printf "${RED}Error: Could not fetch latest release${NC}\n" >&2
        exit 1
    fi
    
    echo "$tag"
}

# Construct binary name
construct_binary_name() {
    local os=$1
    local arch=$2
    local libc=$3
    
    if [ -z "$libc" ]; then
        echo "${BINARY_NAME}-${os}-${arch}"
    else
        echo "${BINARY_NAME}-${os}-${arch}-${libc}"
    fi
}

# Download binary
download_binary() {
    tag=$1
    binary_name=$2
    download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${tag}/${binary_name}"
    
    printf "${YELLOW}Downloading ${binary_name}...${NC}\n"
    
    # Create temporary directory
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT
    
    # Download binary
    if ! curl -fsSL -o "${tmp_dir}/${binary_name}" "$download_url"; then
        printf "${RED}Error: Failed to download ${binary_name}${NC}\n" >&2
        printf "${YELLOW}Available binaries for this release:${NC}\n" >&2
        list_available_binaries "$tag"
        exit 1
    fi
    
    # Make executable
    chmod +x "${tmp_dir}/${binary_name}"
    
    # Move to install directory
    if [ ! -d "$INSTALL_DIR" ]; then
        printf "${YELLOW}Creating directory ${INSTALL_DIR}...${NC}\n"
        sudo mkdir -p "$INSTALL_DIR"
    fi
    
    printf "${YELLOW}Installing to ${INSTALL_DIR}/${BINARY_NAME}...${NC}\n"
    sudo mv "${tmp_dir}/${binary_name}" "${INSTALL_DIR}/${BINARY_NAME}"
    
    printf "${GREEN}Successfully installed ${BINARY_NAME} to ${INSTALL_DIR}/${BINARY_NAME}${NC}\n"
}

# List available binaries for a release
list_available_binaries() {
    tag=$1
    api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${tag}"
    
    curl -s "$api_url" | grep '"name":' | grep -E 'guard-checker-' | sed -E 's/.*"([^"]+)".*/\1/' | sort
}

# Main function
main() {
    printf "${GREEN}Installing ${BINARY_NAME}...${NC}\n"
    
    # Detect system information
    os=$(detect_os)
    arch=$(detect_arch)
    libc=$(detect_libc)
    
    printf "Detected: OS=${os}, Architecture=${arch}, Libc=${libc:-N/A}\n"
    
    if [ "$os" = "unknown" ]; then
        printf "${RED}Error: Unsupported operating system${NC}\n" >&2
        exit 1
    fi
    
    # Get latest release
    printf "${YELLOW}Fetching latest release...${NC}\n"
    tag=$(get_latest_release)
    printf "Latest release: ${tag}\n"
    
    # Construct binary name
    binary_name=$(construct_binary_name "$os" "$arch" "$libc")
    printf "Looking for binary: ${binary_name}\n"
    
    # Download and install
    download_binary "$tag" "$binary_name"
    
    # Verify installation
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        printf "${GREEN}Installation verified: $($BINARY_NAME --version 2>/dev/null || echo 'installed')${NC}\n"
    else
        printf "${YELLOW}Note: Make sure ${INSTALL_DIR} is in your PATH${NC}\n"
    fi
}

# Run main function
main "$@"

