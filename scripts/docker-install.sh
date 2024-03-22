#!/bin/sh

OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
ARCH=$(uname -m)

# CentOS/RHEL
install_centos() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Debian/Ubuntu/Raspbian
install_debian() {
    sudo apt update
    sudo apt install -y ca-certificates curl lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Fedora
install_fedora() {
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# SLES
install_sles() {
    sudo zypper install -y container-suseconnect
    sudo SUSEConnect -p sle-module-containers/15.3/x86_64
    sudo zypper install -y docker docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Arch Linux
install_arch() {
    sudo pacman -Syu --noconfirm docker docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# -----[ Main ]----------------------------------------------------------
case $OS in
    centos | rhel)
        install_centos
        ;;
    debian | ubuntu | raspbian)
        install_debian
        ;;
    fedora)
        install_fedora
        ;;
    sles)
        install_sles
        ;;
    arch)
        install_arch
        ;;
    *)
        echo "Unsupported Linux distribution: $OS"
        exit 1
        ;;
esac

sudo usermod -aG docker "$(whoami)"
echo
echo "Docker and Docker Compose have been installed successfully."