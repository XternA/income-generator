#!/bin/sh

# Setup Windows CLI wrapper that forwards Docker commands to WSL

. scripts/colours.sh

setup_docker_windows_wrappers() {
    printf "\n${BLUE}Setting up Windows Docker CLI wrapper...${NC}\n"

    win_appdata=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    [ -z "$win_appdata" ] && {
        printf "${YELLOW}Could not detect Windows APPDATA directory${NC}\n"
        return 1
    }

    wsl_appdata=$(wslpath "$win_appdata" 2>/dev/null)
    [ -z "$wsl_appdata" ] && {
        printf "${YELLOW}Could not convert Windows path to WSL path${NC}\n"
        return 1
    }

    igm_dir="$wsl_appdata/IGM"

    if [ ! -d "$igm_dir" ]; then
        mkdir -p "$igm_dir" || {
            printf "${YELLOW}Could not create IGM directory at: $igm_dir${NC}\n"
            return 1
        }
    fi

    # Create docker.bat wrapper
    cat > "$igm_dir/docker.bat" << 'EOF'
@echo off

where wsl >nul 2>&1 || (
    echo ERROR: WSL not found. Docker requires WSL to be installed.
    exit /b 1
)

wsl docker %*
exit /b %ERRORLEVEL%
EOF

    if [ -f "$igm_dir/docker.bat" ]; then
        printf "\nWindows CLI wrapper created successfully.\n"
        printf "Docker command usage extended outside of WSL.\n"
        return 0
    else
        printf "\n${YELLOW}Failed to create Windows CLI wrapper.${NC}\n"
        return 1
    fi
}

remove_docker_windows_wrappers() {
    win_appdata=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    [ -z "$win_appdata" ] && return 0

    wsl_appdata=$(wslpath "$win_appdata" 2>/dev/null)
    [ -z "$wsl_appdata" ] && return 0

    igm_dir="$wsl_appdata/IGM"

    [ ! -f "$igm_dir/docker.bat" ] && return 0

    printf "\n${BLUE}Removing Docker Windows wrapper...${NC}\n"
    rm -f "$igm_dir/docker.bat" 2>/dev/null

    if [ ! -f "$igm_dir/docker.bat" ]; then
        printf "\nDocker wrapper removed.\n"
        return 0
    else
        printf "\n${YELLOW}Failed to remove Docker wrapper.${NC}\n"
        return 1
    fi
}

# -- Main --------------------
if [ $# -gt 0 ]; then
    case "$1" in
        --setup) setup_docker_windows_wrappers ;;
        --remove) remove_docker_windows_wrappers ;;
    esac
fi
