#!/bin/sh

has_docker=$(command -v docker 2> /dev/null 1>&1)

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

# CentOS/RHEL
install_centos() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Debian/Ubuntu/Raspbian
install_debian_ubuntu() {
    sudo apt update
    sudo apt install -y ca-certificates curl lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
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

# macOS
install_darwin() {
    brew install --cask docker
    echo "\nLaunching Docker Desktop in order to start the Docker Engine..."
    echo "Make sure Docker Engine is fully running before proceeding..."
    open -a Docker
}

# Windows WSL
install_wsl() {
    if [ -e "$(which winget.exe 2> /dev/null)" ]; then
        winget.exe install -e --id Docker.DockerDesktop
        $("/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe")
        echo "\nLaunching Docker Desktop in order to start the Docker Engine..."
        echo "Make sure Docker Engine is fully running before proceeding..."
    else
        echo "Winget Package Manager is not found. Make sure Winget is installed before trying again."
        echo "\nDocker is not installed.".
        exit
    fi
}

# -----[ Main ]----------------------------------------------------------
if [ ! "$has_docker" ]; then
    case $OS in
        centos | rhel)
            install_centos
            ;;
        debian | ubuntu | raspbian)
            install_debian_ubuntu
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
        darwin)
            install_darwin
            ;;
        wsl)
            install_wsl
            ;;
        *)
            echo "Unsupported Unix distribution: $OS"
            exit 1
            ;;
    esac
    if [ "$(uname)" = 'Linux' ]; then
        sudo usermod -aG docker "$(whoami)"
    fi
    echo
    echo "Docker has been installed successfully."
    echo "\nRestart if docker doesn't start properly."
else
    echo "Docker is already installed."
fi
