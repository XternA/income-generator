#!/bin/sh

INSTALLED="false"

install_homebrew() {
    if ! command -v brew > /dev/null 2>&1; then
        echo "Homebrew is not installed, attempting to install..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        printf "Homebrew have been installed successfully.\n\n"
        INSTALLED="true"
    fi
}

install_sed() {
    if ! command -v gsed > /dev/null 2>&1; then
        echo "Binary 'gsed' is not installed, attempting to install..."
        brew install gnu-sed > /dev/null 2>&1
        printf "GNU 'sed' have been installed successfully.\n\n"
        INSTALLED="true"
    fi
}

install_jq() {
    if ! command -v jq > /dev/null 2>&1; then
        echo "Binary 'jq' is not installed, attempting to install..."
        case $OS_ID in
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
            darwin)
                brew install jq > /dev/null 2>&1
                ;;
            *)
                echo "Unsupported Unix distribution: $OS"
                exit 1
                ;;
        esac
        printf "JSON library 'jq' have been installed successfully.\n\n"
        INSTALLED="true"
    fi
}

# Entrypoint - Install dependencies
[ "$OS_IS_DARWIN" = "true" ] && install_homebrew && install_sed
install_jq
[ "$INSTALLED" = "true" ] && sleep 2.5