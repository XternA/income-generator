#!/bin/sh

OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')

remove_docker_centos() {
    sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_docker_debian() {
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_docker_fedora() {
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_docker_sles() {
    sudo zypper remove -y docker docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_docker_arch() {
    sudo pacman -Rns --noconfirm docker docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

# -----[ Main ]----------------------------------------------------------
case $OS in
    centos | rhel)
        remove_docker_centos
        ;;
    debian | ubuntu | raspbian)
        remove_docker_debian
        ;;
    fedora)
        remove_docker_fedora
        ;;
    sles)
        remove_docker_sles
        ;;
    arch)
        remove_docker_arch
        ;;
    *)
        echo "Unsupported Linux distribution: $OS"
        exit 1
        ;;
esac
echo
echo "Docker and Docker Compose have been successfully removed."
