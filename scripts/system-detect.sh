#!/bin/sh

[ -n "$__SYSTEM_DETECT_CACHED" ] && return
__SYSTEM_DETECT_CACHED=1

__SYS_OS="$(uname -s)"
__SYS_ARCH="$(uname -m)"

# Map System OS information
case "$__SYS_OS" in
    Darwin)
        OS_TYPE="$__SYS_OS"
        OS_DISPLAY="$(sw_vers -productName)"
        OS_ID="darwin"
        OS_CODENAME=$(
            awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/ {printf "%s", substr($NF, 1, length($NF)-1)}' \
            /System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf
        )
        OS_DISTRO_VERSION="$(sw_vers -productVersion)"
        OS_IS_LINUX="false"
        OS_IS_DARWIN="true"
        ;;
    Linux)
        . /etc/os-release 2>/dev/null

        OS_ID="$ID"
        OS_CODENAME="$VERSION_CODENAME"
        OS_DISTRO_VERSION="$VERSION_ID"

        if [ -n "$WSL_DISTRO_NAME" ]; then
            OS_TYPE="WSL"
            OS_DISPLAY="WSL Linux"
        else
            OS_TYPE="$__SYS_OS"
        fi
        OS_IS_LINUX="true"
        OS_IS_DARWIN="false"
        ;;
esac

# Map OS architecture to Docker arch format
case "$__SYS_ARCH" in
    arm64|aarch64)
        OS_DOCKER_ARCH="arm64"
        OS_DOCKER_DISPLAY_ARCH="arm64v8"
        OS_IS_ARM="true"
        ;;
    armv7l)
        OS_DOCKER_ARCH="arm32v7"
        OS_DOCKER_DISPLAY_ARCH="arm32v7"
        OS_IS_ARM="true"
        ;;
    armv6l)
        OS_DOCKER_ARCH="arm32v6"
        OS_DOCKER_DISPLAY_ARCH="arm32v6"
        OS_IS_ARM="true"
        ;;
    *)
        OS_DOCKER_ARCH="latest"
        OS_DOCKER_DISPLAY_ARCH="amd64"
        OS_IS_ARM="false"
        ;;
esac

# System Info
export HOSTNAME="$(hostname)"        # Hostname
export OS="$__SYS_OS"                # Platform string (Linux/Darwin)
export OS_TYPE                       # Remap of platform string (Linux/Darwin/WSL)
export OS_DISPLAY                    # Pretty display platform string (Linux/WSL/macOS/etc)
export OS_ID                         # OS ID (ubuntu/debian/fedora/etc)
export OS_CODENAME                   # OS codename (noble/sequoia/etc)
export OS_DISTRO_VERSION             # OS codename distro version number
export OS_ARCH="$__SYS_ARCH"         # Raw architecture string (x86_64/arm64/arm32/etc)

# Container Runtime Info
export OS_DOCKER_ARCH                # Docker arch format (latest/arm64/arm32v7/etc)
export OS_DOCKER_DISPLAY_ARCH        # Display Docker arch format (amd64/arm64v8/arm32v7/etc)


# TDDO - Remap from System Info and from Container Runtime Info above and then scrap all the below
# export HOST="$__HOST"                 # Hostname
# export OS_DISPLAY="$__SYS_OS"         # Platform string (Linux/Darwin/etc)
# export OS_RAW_ARCH="$__SYS_ARCH"  # Raw architecture string (x86_64/arm64/arm32)
# export OS_TYPE                        # Platform string (darwin/wsl/ubuntu/etc)
# export OS_DOCKER_ARCH                 # Docker arch format (latest/arm64/arm32v7/etc)
# export OS_DOCKER_DISPLAY_ARCH                # Display Docker arch format (amd64/arm64v8/arm32v7/etc)
export OS_IS_ARM                      # Boolean: true/false
export OS_IS_DARWIN                   # Boolean: true/false
export OS_IS_LINUX                    # Boolean: true/false
