#!/bin/sh

get_platform() {
    OS="$(uname)"
    if [ "$OS" = "Linux" ]; then
        if [ -n "$WSL_DISTRO_NAME" ]; then
            OS="wsl"
        else
            OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
        fi
    elif [ "$OS" = "Darwin" ]; then
        OS="darwin"
    fi
    echo "$OS"
}

get_arch() {
    uname -m
}

is_arm() {
    arch=$(uname -m)
    case "$arch" in
        armv5l|armv6l|armv7l|armv8l|aarch64|arm64) echo true ;;
        *) echo false ;;
    esac
}

case "$1" in
    --platform) get_platform ;;
    --arch) get_arch ;;
    --is-arm) is_arm ;;
esac