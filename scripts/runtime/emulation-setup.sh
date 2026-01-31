#!/bin/sh

is_emulation_registered() {
    [ -f /proc/sys/fs/binfmt_misc/qemu-x86_64 ]
}

setup_emulation() {
    printf "${BLUE}Setting up QEMU emulation layer...${NC}\n\n"

    if is_emulation_registered; then
        printf "${GREEN}QEMU emulation already configured.${NC}\n\n"
        return 0
    fi

    case "$OS_ID" in
        ubuntu|debian|raspbian)
            sudo apt update -qq && \
            sudo apt install -y qemu-user-static binfmt-support
            # Debian-based distros auto-register via binfmt-support
            ;;
        fedora)
            sudo dnf install -y qemu-user-static && \
            sudo systemctl restart systemd-binfmt.service
            ;;
        centos|rhel)
            sudo yum install -y qemu-user-static && \
            sudo systemctl restart systemd-binfmt.service
            ;;
        *)
            printf "\nUnsupported Unix distribution: $OS_ID\n"
            printf "You will need to set up QEMU emulation manually.\n\n"
            ;;
    esac

    if is_emulation_registered; then
        printf "\n${GREEN}QEMU emulation layer configured successfully!${NC}\n\n"
        return 0
    else
        printf "\nFailed to set up QEMU emulation layer.\n"
        printf "You will need to set up QEMU emulation manually.\n\n"
        return 1
    fi
}

remove_emulation() {
    printf "${BLUE}Removing QEMU emulation layer...${NC}\n\n"

    if ! is_emulation_registered; then
        printf "${GREEN}QEMU emulation already removed.${NC}\n"
        return 0
    fi

    case "$OS_ID" in
        ubuntu|debian|raspbian)
            sudo apt purge -y qemu-user-static binfmt-support >/dev/null 2>&1 || true && \
            sudo apt autoremove -y >/dev/null 2>&1
            ;;
        fedora|centos|rhel)
            sudo systemctl stop systemd-binfmt.service 2>/dev/null && \
            sudo systemctl disable systemd-binfmt.service 2>/dev/null
            ;;
        *)
            printf "Unsupported Unix distribution: $OS_ID\n"
            printf "You may need to remove QEMU emulation manually.\n"
            return 1
            ;;
    esac

    printf "${GREEN}QEMU emulation layer removed.${NC}\n"
    return 0
}

# Main script
if [ "$OS_IS_ARM" = "true" ] && [ "$OS_IS_DARWIN" = "false" ]; then
    case "$1" in
        --setup) setup_emulation ;;
        --remove) remove_emulation ;;
    esac
fi
