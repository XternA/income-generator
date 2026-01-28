#!/bin/sh

[ -n "$DOCKER_UNINSTALL_CACHED" ] && return
DOCKER_UNINSTALL_CACHED=1

remove_centos() {
    sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

# Debian/Ubuntu/Raspbian
remove_debian_ubuntu() {
    printf "${BLUE}Uninstalling Docker Engine...${NC}\n\n"

    if sudo systemctl is-active docker >/dev/null 2>&1; then
        printf "Stopping Docker service...\n"
        sudo systemctl stop docker >/dev/null 2>&1 || true
        sudo systemctl disable docker >/dev/null 2>&1 || true
    fi

    printf "Removing Docker packages...\n"
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1 || true
    
    for bin in docker docker-compose; do
        path=$(command -v "$bin" 2>/dev/null || true)
        [ -n "$path" ] && sudo rm -f "$path" >/dev/null 2>&1 || true
    done

    printf "Cleaning up dependencies...\n"
    sudo apt-get autoremove -y >/dev/null 2>&1 || true

    hash -d docker 2>/dev/null || true
    hash -d docker-compose 2>/dev/null || true

    printf "Removing Docker data directory...\n"
    sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker $HOME/.docker

    printf "Removing Docker apt sources...\n"
    sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.asc

    if getent group docker >/dev/null 2>&1; then
        sudo gpasswd -d "$(id -un)" docker >/dev/null 2>&1 || true
    fi
    return 0
}

remove_fedora() {
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_arch() {
    sudo pacman -Rns --noconfirm docker docker-compose-plugin
    sudo rm -rf /var/lib/docker
}

remove_darwin() {
    brew uninstall --cask --force docker
    brew uninstall --formula --force docker
    brew cleanup
    brew autoremove
}

# -----[ Main ]----------------------------------------------------------
if [ "$HAS_CONTAINER_RUNTIME" ]; then
    case $OS_ID in
        centos | rhel)
            remove_centos
            ;;
        debian | ubuntu | raspbian)
            if [ "$OS_IS_WSL" = "true" ]; then
                . scripts/runtime/wsl/wsl-runtime.sh
                if _is_docker_desktop_installed; then
                    remove_docker_desktop
                else
                    . scripts/runtime/wsl/wsl-docker-wrapper.sh

                    remove_debian_ubuntu
                    remove_docker_windows_wrappers
                fi
            else
                remove_debian_ubuntu
            fi
            ;;
        fedora)
            remove_fedora
            ;;
        arch)
            remove_arch
            ;;
        darwin)
            remove_darwin
            ;;
        *)
            echo "Unsupported Unix distribution: $OS_ID"
            echo "You may need to uninstall Docker manually."
            exit 1
            ;;
    esac

    printf "\n${GREEN}Docker has been uninstalled successfully.${NC}\n"
else
    echo "Docker is not installed."
fi
