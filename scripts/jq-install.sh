#!/bin/sh

OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')

if ! command -v jq > /dev/null 2>&1; then
    echo "jq is not installed, attempting to install..."
    case $OS in
        centos | rhel)
            sudo yum install -y jq > /dev/null 2>&1
            ;;
        debian | ubuntu | raspbian)
            sudo apt install -y jq > /dev/null 2>&1
            ;;
        fedora)
            sudo dnf install -y jq > /dev/null 2>&1
            ;;
        sles)
            sudo zypper install -y jq > /dev/null 2>&1
            ;;
        arch)
            sudo pacman -Syu --noconfirm jq > /dev/null 2>&1
            ;;
        *)
            echo "Unsupported Linux distribution: $OS"
            exit 1
            ;;
    esac
    echo "JSON library jq have been installed successfully."
fi
