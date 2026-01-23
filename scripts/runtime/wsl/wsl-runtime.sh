#!/bin/sh

[ -n "$__WSL_RUNTIME_CACHED" ] && return
__WSL_RUNTIME_CACHED=1

. scripts/banner.sh

_find_docker_desktop_path() {
    for mount in /mnt/*; do
        [ ! -d "$mount" ] && continue

        exe_path="$mount/Program Files/Docker/Docker/Docker Desktop.exe"
        if [ -x "$exe_path" ]; then
            echo "$exe_path"
            return 0
        fi
    done
    return 1
}

_is_docker_desktop_installed() {
    # Check for Docker Desktop indicators
    if command -v winget.exe >/dev/null 2>&1; then
        if winget.exe list --id Docker.DockerDesktop 2>/dev/null | grep -q "Docker.DockerDesktop"; then
            return 0
        fi
    fi

    # Fallback: Search all mount points for executable
    _find_docker_desktop_path >/dev/null
}

_install_docker_desktop() {
    printf "${BLUE}Installing Docker Desktop via Winget...${NC}\n\n"

    # Check if winget is available
    if ! command -v winget.exe >/dev/null 2>&1; then
        printf "${RED}Error: Winget Package Manager not found.${NC}\n"
        printf "${YELLOW}Winget is required to install Docker Desktop.${NC}\n\n"
        printf "Install Winget from: ${BLUE}https://aka.ms/getwinget${NC}\n"
        return 1
    fi

    if winget.exe install -e --id Docker.DockerDesktop; then
        printf "\n${BLUE}Launching Docker Desktop...${NC}\n\n"

        # Launch Docker Desktop
        docker_desktop_exe=$(_find_docker_desktop_path)
        if [ -n "$docker_desktop_exe" ]; then
            "$docker_desktop_exe" >/dev/null 2>&1 &
            printf "${YELLOW}Make sure Docker Engine is fully running before proceeding.${NC}\n"
            printf "${YELLOW}Check the system tray for Docker Desktop status.${NC}\n"
        else
            printf "${YELLOW}Docker Desktop installed but could not auto-launch.${NC}\n"
            printf "${YELLOW}Please launch it manually from the Windows Start menu.${NC}\n"
        fi
    else
        printf "\n${RED}Docker Desktop installation failed.${NC}\n"
        printf "${YELLOW}Try install manually or use native WSL Docker option.${NC}\n"
        return 1
    fi
}

_uninstall_docker_desktop() {
    printf "${BLUE}Uninstalling Docker Desktop...${NC}\n\n"

    printf "Stopping Docker Desktop processes...\n"
    taskkill.exe /IM "Docker Desktop.exe" /T >/dev/null 2>&1 || true
    taskkill.exe /F /IM "Docker Desktop.exe" >/dev/null 2>&1 || true
    taskkill.exe /F /IM "com.docker.backend.exe" >/dev/null 2>&1 || true
    taskkill.exe /F /IM "vpnkit.exe" >/dev/null 2>&1 || true
    taskkill.exe /F /IM "dockerd.exe" >/dev/null 2>&1 || true
    sleep 2

    printf "\nUnregistering Docker Desktop WSL distro...\n"
    wsl.exe --unregister docker-desktop 2>/dev/null || true
    wsl.exe --unregister docker-desktop-data 2>/dev/null || true
    sleep 1

    printf "\nAttempting uninstall via Winget...\n"
    uninstall_failed=0

    if command -v timeout >/dev/null 2>&1; then
        timeout 60 winget.exe uninstall --id Docker.DockerDesktop --silent --force --accept-source-agreements --disable-interactivity 2>/dev/null || uninstall_failed=1
    else
        winget.exe uninstall --id Docker.DockerDesktop --silent --force --accept-source-agreements --disable-interactivity 2>/dev/null || uninstall_failed=1
    fi

    # Step 4: Fallback to direct installer if winget failed
    if [ $uninstall_failed -eq 1 ]; then
        printf "${YELLOW}Winget uninstall failed, trying direct installer...${NC}\n"

        for mount in /mnt/*; do
            [ ! -d "$mount" ] && continue
            installer_path="$mount/Program Files/Docker/Docker/Docker Desktop Installer.exe"

            if [ -f "$installer_path" ]; then
                if command -v timeout >/dev/null 2>&1; then
                    timeout 60 "$installer_path" uninstall --quiet 2>/dev/null || uninstall_failed=2
                else
                    "$installer_path" uninstall --quiet 2>/dev/null || uninstall_failed=2
                fi
                break
            fi
        done
        [ $uninstall_failed -eq 1 ] && uninstall_failed=2
    fi

    # Remove binaries injected into WSL
    printf "\nRemoving Docker binaries from WSL...\n"
    for bin in docker docker-compose; do
        path=$(command -v "$bin" 2>/dev/null || true)
        [ -n "$path" ] && sudo rm -f "$path" >/dev/null 2>&1 || true
    done

    printf "\nRemoving Docker data directory from WSL...\n"
    sudo rm -rf /var/lib/docker-desktop $HOME/.docker

    if [ $uninstall_failed -eq 0 ]; then
        printf "\n${YELLOW}You may need to restart your system to complete the removal.${NC}\n"
        return 0
    elif [ $uninstall_failed -eq 1 ]; then
        printf "\n${YELLOW}Automated uninstall partially completed.${NC}\n"
        printf "${YELLOW}Some components may require manual removal.${NC}\n\n"
        _show_docker_desktop_warning
        return 1
    else
        printf "\n${RED}Automated uninstall failed.${NC}\n\n"
        _show_docker_desktop_warning
        return 1
    fi
}

_show_docker_desktop_warning() {
    printf "${YELLOW}Docker Desktop for Windows Detected${NC}\n\n"
    printf "Docker Desktop must be uninstalled from Windows, not WSL.\n\n"

    printf "${BLUE}Manual Removal Steps:${NC}\n"
    printf "1. Open Windows Settings > Apps > Installed apps\n"
    printf "2. Search for 'Docker Desktop'\n"
    printf "3. Click the three dots > Uninstall\n\n"

    printf "${YELLOW}Note: Winget uninstaller may get stuck. Use Windows Settings instead.${NC}\n\n"
    printf "Docker Desktop is still installed.\n"
    return 1
}

_confirm_docker_desktop_removal() {
    printf "${GREEN}Docker Desktop detected.${NC}\n\n"
    printf "${YELLOW}Warning: This will remove Docker and all container data.${NC}\n"
    printf "${YELLOW}All containers, images, volumes, and networks will be deleted.${NC}\n\n"

    printf "Do you want to proceed? (Y/N): "; read -r confirm

    case $confirm in
        [Yy]*)
            return 0
            ;;
        *)
            printf "\nYou can also manually uninstall it from Windows.\n"
            printf "\n${RED}Docker Desktop removal cancelled.${NC}\n"
            return 1
            ;;
    esac
}

setup_wsl_runtime() {
    options="(1-2)"
    
    while true; do
        display_banner

        printf "${BLUE}Choose a Docker installation method:${NC}\n\n"

        printf "${GREEN}1. Native Docker Engine${NC} ${GREY}(Recommended)${NC}\n"
        printf "   - Runs directly in WSL (no Windows dependency)\n"
        printf "   - Lower resource usage and faster startup\n"
        printf "   - Requires systemd support in WSL\n\n"

        printf "${GREEN}2. Docker Desktop for Windows ${GREY}(Deprecated)${NC}\n"
        printf "   - GUI application with Windows integration\n"
        printf "   - Higher resource usage\n"
        printf "   - Requires Winget Package Manager\n\n"
        
        printf "${GREEN}0. Cancel Installation${NC}\n\n"

        printf "Select an option $options: "; read -r option

        case $option in
            0)
                printf "\n${RED}Docker installation cancelled.${NC}\n"
                return 1
                ;;
            1)  
                display_banner
                install_debian_ubuntu
                install_result=$?
                [ $install_result -eq 0 ] && return 0 || return 1
                ;;
            2)
                display_banner
                _install_docker_desktop
                install_result=$?
                [ $install_result -eq 0 ] && return 0 || return 1
                ;;
            *)
                printf "\n${RED}Invalid option. Please select a valid option $options.${NC}\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}

remove_docker_desktop() {
    display_banner

    if _confirm_docker_desktop_removal; then
        display_banner
        _uninstall_docker_desktop
        return $?
    else
        return 1
    fi
}
