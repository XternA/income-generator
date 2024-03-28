#!/bin/sh

if [ $(uname) = 'Linux' ]; then
    OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
elif [ $(uname) = 'Darwin' ]; then
    OS='darwin'
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

# -----[ Main ]----------------------------------------------------------
if command -v docker > /dev/null 2>&1; then
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
        *)
            echo "Unsupported Unix distribution: $OS"
            exit 1
            ;;
    esac
    echo
    echo "Docker have been successfully removed."
else
    echo "Docker doesn't exist."
fi
