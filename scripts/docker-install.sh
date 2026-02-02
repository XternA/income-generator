#!/bin/sh

[ -n "$__DOCKER_INSTALL_CACHED" ] && return
__DOCKER_INSTALL_CACHED=1

# CentOS/RHEL
install_centos() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    sudo systemctl enable --now docker || return 1
    return 0
}

# Debian/Ubuntu/Raspbian
install_debian_ubuntu() {
    printf "${BLUE}Installing Docker Engine...${NC}\n\n"

    sudo apt update -qq
    sudo apt install -y ca-certificates curl || return 1
    sudo install -m 0755 -d /etc/apt/keyrings || return 1
    sudo curl -fsSL "https://download.docker.com/linux/$OS_ID/gpg" -o /etc/apt/keyrings/docker.asc || return 1
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    printf '%s\n' \
        'Types: deb' \
        "URIs: https://download.docker.com/linux/$OS_ID" \
        "Suites: $OS_CODENAME" \
        'Components: stable' \
        'Signed-By: /etc/apt/keyrings/docker.asc' |
    sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null

    sudo apt update -qq
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1

    # Systemd handling (with WSL-specific error messages)
    if sudo systemctl start docker && sudo systemctl enable docker 2>/dev/null; then
        if [ "$OS_IS_WSL" = "true" ]; then
            printf "\n${GREEN}Docker Engine installed natively in WSL.${NC}\n"
            printf "${GREEN}Systemd will automatically start Docker on WSL boot.${NC}\n"

            # Setup Windows CLI wrappers
            . scripts/runtime/wsl/wsl-docker-wrapper.sh
            setup_docker_windows_wrappers
        fi
    else
        if [ "$OS_IS_WSL" = "true" ]; then
            printf "\n${YELLOW}Warning: Could not enable systemd auto-start.${NC}\n"
            printf "${YELLOW}You may need to enable systemd in ${RED}/etc/wsl.conf${NC}\n"
            printf "\n${BLUE}Docker installed successfully but requires manual start.${NC}\n"
        else
            return 1
        fi
    fi
    return 0
}

install_fedora() {
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    sudo systemctl enable --now docker || return 1
    return 0
}

# macOS
install_darwin() {
    brew install --cask docker || return 1
    echo "\nLaunching Docker Desktop in order to start the Docker Engine..."
    echo "Make sure Docker Engine is fully running before proceeding..."
    open -a Docker
    return 0
}

# -----[ Main ]----------------------------------------------------------
if [ ! "$HAS_CONTAINER_RUNTIME" ]; then
    install_failed=0

    case $OS_ID in
        centos|rhel)
            install_centos || install_failed=1
            ;;
        debian|ubuntu|raspbian)
            if [ "$OS_IS_WSL" = "true" ]; then
                . scripts/runtime/wsl/wsl-runtime.sh
                setup_wsl_runtime || install_failed=1
            else
                install_debian_ubuntu || install_failed=1
            fi
            ;;
        fedora)
            install_fedora || install_failed=1
            ;;
        darwin)
            install_darwin || install_failed=1
            ;;
        *)
            echo "Unsupported Unix distribution: $OS_ID"
            echo "You may need to install Docker manually."
            exit 1
            ;;
    esac

    if [ $install_failed -eq 0 ]; then
        if [ "$OS_IS_LINUX" = "true" ]; then
            sudo usermod -aG docker "$(id -un)"
            printf "\nRestart your terminal or log out/in to apply Docker group changes.\n"
        fi
        printf "\n${GREEN}Docker has been installed successfully.${NC}\n"
    fi

    [ $install_failed -eq 1 ] && exit 1
else
    echo "Docker is already installed."
fi
