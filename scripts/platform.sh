#!/bin/sh

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