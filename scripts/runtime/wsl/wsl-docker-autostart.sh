#!/bin/sh

# Setup WSL Docker daemon to autostart on Windows boot

. scripts/colours.sh

TASK_NAME='DockerAutostart'

check_wsl_autostart() {
    schtasks.exe /Query /TN "$TASK_NAME" >/dev/null 2>&1
}

setup_wsl_docker_autostart() {
    printf "\n${BLUE}Setting up WSL Docker autostart...${NC}\n\n"

    check_wsl_autostart && printf "${GREEN}WSL Docker autostart already enabled.${NC}\n" && return 0

    WIN_TEMP=$(cmd.exe /c "echo %TEMP%" 2>/dev/null | tr -d '\r\n')
    WSL_PS="$(wslpath "$WIN_TEMP" 2>/dev/null)/igm_task_setup.ps1"

    cat > "$WSL_PS" << PSEOF
try {
    \$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    \$service = New-Object -ComObject Schedule.Service
    \$service.Connect()
    \$taskDef = \$service.NewTask(0)
    \$taskDef.RegistrationInfo.Author = 'IGM'
    \$taskDef.Principal.UserId = \$userId
    \$taskDef.Principal.LogonType = 2
    \$taskDef.Principal.RunLevel = 0
    \$trigger = \$taskDef.Triggers.Create(9)
    \$trigger.UserId = \$userId
    \$trigger.Enabled = \$true
    \$action = \$taskDef.Actions.Create(0)
    \$action.Path = 'wsl.exe'
    \$action.Arguments = '--exec /init'
    \$taskDef.Settings.DisallowStartIfOnBatteries = \$false
    \$taskDef.Settings.StopIfGoingOnBatteries = \$false
    \$taskDef.Settings.ExecutionTimeLimit = 'PT5M'
    \$taskDef.Settings.Hidden = \$true
    \$service.GetFolder('\').RegisterTaskDefinition('$TASK_NAME', \$taskDef, 6, \$userId, \$null, 2) | Out-Null
} catch {
    exit 1
}
PSEOF

    printf "Administrator permission is required to register task schedule.\nPlease approve UAC prompt if prompted.\n\n"
    powershell.exe -ExecutionPolicy Bypass -Command \
        "Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden \
        -ArgumentList '-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden \
        -File \"$WIN_TEMP\\igm_task_setup.ps1\"'"

    rm -f "$WSL_PS"

    if check_wsl_autostart; then
        printf "WSL Docker autostart enabled.\nDocker will now autostart on boot.\n"
        return 0
    fi
    printf "${YELLOW}Warning: Failed to setup autostart.\nDocker will work, but you'll need to open WSL once after Windows reboot.${NC}\n"
    return 1
}

remove_wsl_docker_autostart() {
    printf "\n${BLUE}Removing WSL Docker autostart...${NC}\n\n"

    ! check_wsl_autostart && printf "WSL Docker autostart not enabled.\n" && return 0

    printf "Administrator permission is required to remove task schedule.\nPlease approve UAC prompt if prompted.\n\n"
    powershell.exe -ExecutionPolicy Bypass -Command \
        "Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden \
        -ArgumentList '-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden \
        -Command \"Unregister-ScheduledTask -TaskName ''$TASK_NAME'' -Confirm:\$false\"'"

    if ! check_wsl_autostart; then
        printf "WSL Docker autostart removed.\n"
        return 0
    fi
    printf "${RED}Error: Failed to remove autostart task.${NC}\n"
    return 1
}

# -- Main --------------------
if [ $# -gt 0 ]; then
    case "$1" in
        --setup) setup_wsl_docker_autostart ;;
        --remove) remove_wsl_docker_autostart ;;
    esac
fi
