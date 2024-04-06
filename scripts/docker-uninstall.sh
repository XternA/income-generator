#!/bin/sh

has_docker=$(command -v docker > /dev/null 2>&1)

if [ "$(uname)" = "Linux" ]; then
    if [ -n "$WSL_DISTRO_NAME" ]; then
        OS="wsl"
        has_docker="$(where.exe docker 2> /dev/null >&1)"
    else
        OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    fi
elif [ "$(uname)" = "Darwin" ]; then
    OS="darwin"
fi

remove_centos() {
    sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_debian() {
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_fedora() {
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_sles() {
    sudo zypper remove -y docker docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_arch() {
    sudo pacman -Rns --noconfirm docker docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_darwin() {
    brew uninstall docker
}

remove_wsl() {
    echo "Uninstalling Docker via Winget is currently not supported as the uninstaller gets stuck. Use the standard Windows uninstall method instead."
    echo "\nDocker is still installed."
    exit
}

# -----[ Main ]----------------------------------------------------------
if [ "$has_docker" ]; then
    case $OS in
        centos | rhel)
            remove_centos
            ;;
        debian | ubuntu | raspbian)
            remove_debian
            ;;
        fedora)
            remove_fedora
            ;;
        sles)
            remove_sles
            ;;
        arch)
            remove_arch
            ;;
        darwin)
            remove_darwin
            ;;
        wsl)
            remove_wsl
            ;;
        *)
            echo "Unsupported Unix distribution: $OS"
            exit 1
            ;;
    esac
    echo
    echo "Docker has been uninstalled successfully."
else
    echo "Docker is not installed."
fi
