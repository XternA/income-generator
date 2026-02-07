#!/bin/sh

# Setup WSL Docker daemon to autostart on Windows boot

. scripts/colours.sh

check_wsl_autostart() {
    # Check if Task Scheduler task exists
    schtasks.exe /Query /TN "DockerAutostart" >/dev/null 2>&1
    return $?
}

# Create Windows startup batch script
_create_wsl_startup_script() {
    # Get Windows APPDATA path
    appdata_path=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    if [ -z "$appdata_path" ]; then
        echo "${RED}Failed to get Windows APPDATA path${NC}"
        return 1
    fi

    # Convert to WSL path
    igm_dir=$(wslpath "$appdata_path")/IGM
    script_path="$igm_dir/wsl-docker-start.bat"

    mkdir -p "$igm_dir" 2>/dev/null || {
        echo "${RED}Failed to create IGM directory${NC}"
        return 1
    }

    # Create startup script
    cat > "$script_path" << 'BATCH_EOF'
@echo off
REM IGM WSL Docker Auto-Start Script
REM Starts WSL silently and ensures Docker daemon is running

wsl.exe --exec sh -c "sudo systemctl start docker 2>/dev/null; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do docker info >/dev/null 2>&1 && break || sleep 2; done" >nul 2>&1

exit /b 0
BATCH_EOF

    if [ ! -f "$script_path" ]; then
        echo "${RED}Failed to create startup script${NC}"
        return 1
    fi

    # Return Windows path for Task Scheduler
    echo "$appdata_path\\IGM\\wsl-docker-start.bat"
    return 0
}

_register_task_scheduler() {
    win_script_path="$1"

    if [ -z "$win_script_path" ]; then
        echo "${RED}Invalid script path${NC}"
        return 1
    fi

    result=$(powershell.exe -ExecutionPolicy Bypass -Command "
        try {
            # Use COM interface for full control over task properties
            \$service = New-Object -ComObject Schedule.Service
            \$service.Connect()

            # Get root task folder
            \$folder = \$service.GetFolder('\')

            # Create new task definition
            \$taskDef = \$service.NewTask(0)

            # Set registration info (Author)
            \$taskDef.RegistrationInfo.Author = 'IGM'

            # Set principal (user context, non-elevated)
            \$taskDef.Principal.UserId = \$env:USERNAME
            \$taskDef.Principal.LogonType = 3  # Interactive
            \$taskDef.Principal.RunLevel = 0   # Limited (non-elevated)

            # Set trigger (at logon)
            \$trigger = \$taskDef.Triggers.Create(9)  # 9 = Logon trigger
            \$trigger.UserId = \$env:USERNAME
            \$trigger.Enabled = \$true

            # Set action (execute batch file)
            \$action = \$taskDef.Actions.Create(0)  # 0 = Execute action
            \$action.Path = \$env:APPDATA + '\IGM\wsl-docker-start.bat'

            # Set settings (COM interface property names)
            \$taskDef.Settings.DisallowStartIfOnBatteries = \$false
            \$taskDef.Settings.StopIfGoingOnBatteries = \$false
            \$taskDef.Settings.ExecutionTimeLimit = 'PT5M'  # 5 minutes
            \$taskDef.Settings.Enabled = \$true
            \$taskDef.Settings.Hidden = \$true

            # Register task (6 = CREATE_OR_UPDATE, null = no password needed for current user)
            \$folder.RegisterTaskDefinition('DockerAutostart', \$taskDef, 6, \$null, \$null, 3) | Out-Null

            Write-Host 'SUCCESS'
            exit 0
        } catch {
            Write-Host \"ERROR: \$(\$_.Exception.Message)\"
            exit 1
        }
    " 2>&1)

    if echo "$result" | grep -q "SUCCESS"; then
        return 0
    else
        echo "${RED}Failed to register Task Scheduler task${NC}"
        echo "${YELLOW}$result${NC}"
        return 1
    fi
}

setup_wsl_docker_autostart() {
    printf "\n${BLUE}Setting up WSL Docker autostart...${NC}\n\n"

    if check_wsl_autostart; then
        echo "${GREEN}WSL Docker autostart already enabled.${NC}"
        return 0
    fi

    # Create startup script
    win_script_path=$(_create_wsl_startup_script)
    if [ $? -ne 0 ] || [ -z "$win_script_path" ]; then
        echo "${YELLOW}Warning: Failed to create startup script${NC}"
        echo "${YELLOW}Docker will work, but you'll need to open WSL once after Windows reboot${NC}"
        return 1
    fi

    # Register task
    if ! _register_task_scheduler "$win_script_path"; then
        echo "${YELLOW}Warning: Failed to register autostart task${NC}"
        echo "${YELLOW}Docker will work, but you'll need to open WSL once after Windows reboot${NC}"
        return 1
    fi

    printf "WSL Docker autostart enabled.\nDocker will now autostart on boot.\n"
    return 0
}

remove_wsl_docker_autostart() {
    printf "\n${BLUE}Removing WSL Docker autostart...${NC}\n\n"

    if ! check_wsl_autostart; then
        echo "WSL Docker autostart not enabled."
        return 0
    fi

    # Remove Task Scheduler task
    schtasks.exe /Delete /TN "DockerAutostart" /F >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "${YELLOW}Warning: Failed to remove autostart task${NC}"
        return 1
    fi

    # Remove startup script
    appdata_path=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    if [ -n "$appdata_path" ]; then
        igm_dir=$(wslpath "$appdata_path")/IGM
        script_path="$igm_dir/wsl-docker-start.bat"
        rm -f "$script_path" 2>/dev/null
    fi

    echo "WSL Docker autostart removed."
    return 0
}

# -- Main --------------------
if [ $# -gt 0 ]; then
    case "$1" in
        --setup) setup_wsl_docker_autostart ;;
        --remove) remove_wsl_docker_autostart ;;
    esac
fi
