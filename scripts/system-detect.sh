#!/bin/sh

if [ -n "$__SYSTEM_DETECT_CACHED" ]; then
    return 0
fi
__SYSTEM_DETECT_CACHED=1

__SYS_OS="$(uname -s)"
__SYS_RAW_ARCH="$(uname -m)"
__HOST="$(hostname)"

# Map OS to platform string
case "$__SYS_OS" in
    Darwin) 
        OS_TYPE="darwin"
        OS_IS_DARWIN="true"
        OS_IS_LINUX="false"
        ;;
    Linux)
        if [ -n "$WSL_DISTRO_NAME" ]; then
            OS_TYPE="wsl"
        else
            OS_TYPE=$(awk -F= '/^ID=/{gsub(/"/,""); print $2}' /etc/os-release 2>/dev/null)
            if [ -z "$OS_TYPE" ]; then
                OS_TYPE="linux"
            fi
        fi
        OS_IS_DARWIN="false"
        OS_IS_LINUX="true"
        ;;
esac

# Map OS architecture to Docker arch format
case "$__SYS_RAW_ARCH" in
    arm64|aarch64)
        OS_DOCKER_ARCH="arm64"
        OS_DISPLAY_ARCH="arm64v8"
        OS_IS_ARM="true"
        ;;
    armv7l)
        OS_DOCKER_ARCH="arm32v7"
        OS_DISPLAY_ARCH="arm32v7"
        OS_IS_ARM="true"
        ;;
    armv6l)
        OS_DOCKER_ARCH="arm32v6"
        OS_DISPLAY_ARCH="arm32v6"
        OS_IS_ARM="true"
        ;;
    *)
        OS_DOCKER_ARCH="latest"
        OS_DISPLAY_ARCH="amd64"
        OS_IS_ARM="false"
        ;;
esac

# Export all cached variables for use in other scripts
export HOST="$__HOST"                 # Hostname
export OS_DISPLAY="$__SYS_OS"         # Platform string (Linux/Darwin/etc)
export OS_RAW_ARCH="$__SYS_RAW_ARCH"  # Raw architecture string (x86_64/arm64/arm32)
export OS_TYPE                        # Platform string (darwin/wsl/ubuntu/etc)
export OS_DOCKER_ARCH                 # Docker arch format (latest/arm64/arm32v7/etc)
export OS_DISPLAY_ARCH                # Display Docker arch format (amd64/arm64v8/arm32v7/etc)
export OS_IS_ARM                      # Boolean: true/false
export OS_IS_DARWIN                   # Boolean: true/false
export OS_IS_LINUX                    # Boolean: true/false
