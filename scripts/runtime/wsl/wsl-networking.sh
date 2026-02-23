#!/bin/sh

. scripts/banner.sh

get_wslconfig_path() {
    wsl_path=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')" 2>/dev/null)
    [ -n "$wsl_path" ] && printf "%s/.wslconfig" "$wsl_path"
}

check_wsl_version() {
    wsl_version=$(wsl.exe --version 2>/dev/null | tr -d '\000' | awk '/WSL [Vv]ersion/{gsub(/\r/,""); print $3; exit}')
    [ -z "$wsl_version" ] && return 1
    major=${wsl_version%%.*}
    [ "$major" -ge 2 ] 2>/dev/null
}

get_wsl_networking_status() {
    wslconfig_path=$(get_wslconfig_path)
    [ ! -f "$wslconfig_path" ] && { echo "not_set"; return 1; }
    awk '
        /^[[:space:]]*networkingMode[[:space:]]*=[[:space:]]*mirrored[[:space:]]*$/ { print "enabled"; found=1; exit }
        /^[[:space:]]*networkingMode[[:space:]]*=/ { print "disabled"; found=1; exit }
        END { if (!found) print "not_set" }
    ' "$wslconfig_path"
}

format_status() {
    case "$1" in
        enabled)  printf "${GREEN}ENABLED${NC}" ;;
        disabled) printf "${RED}DISABLED${NC}" ;;
        *)        printf "${YELLOW}NOT CONFIGURED${NC}" ;;
    esac
}

display_notice() {
    printf "\n${YELLOW}Note:${NC} WSL must be started otherwise nothing will run.\n"
    printf "If you run into networking issues, restart your machine.\n"
}

enable_wsl_mirrored_networking() {
    wslconfig_path=$(get_wslconfig_path)
    [ -z "$wslconfig_path" ] && { printf "${RED}Error:${NC} Could not determine .wslconfig path.\n"; return 1; }

    if [ -f "$wslconfig_path" ]; then
        cp "$wslconfig_path" "${wslconfig_path}.bak" 2>/dev/null
        awk '
            /^\[wsl2\]/ { in_wsl2=1; has_section=1; print; next }
            /^\[/ { in_wsl2=0; print; next }
            in_wsl2 && /^[[:space:]]*#?[[:space:]]*networkingMode[[:space:]]*=/ {
                if (!has_setting) print "networkingMode=mirrored"
                has_setting=1; next
            }
            in_wsl2 && !has_setting && NF && !/^[[:space:]]*#/ {
                print "networkingMode=mirrored"; has_setting=1
            }
            { print }
            END { if (!has_section) print "\n[wsl2]\nnetworkingMode=mirrored" }
        ' "$wslconfig_path" > "${wslconfig_path}.tmp" && mv "${wslconfig_path}.tmp" "$wslconfig_path"
    else
        printf "[wsl2]\nnetworkingMode=mirrored\n" > "$wslconfig_path"
    fi
}

disable_wsl_mirrored_networking() {
    wslconfig_path=$(get_wslconfig_path)
    [ ! -f "$wslconfig_path" ] && { printf "${YELLOW}No .wslconfig found, nothing to disable.${NC}\n"; return 0; }

    cp "$wslconfig_path" "${wslconfig_path}.bak" 2>/dev/null
    awk '!/^[[:space:]]*#?[[:space:]]*networkingMode[[:space:]]*=/' "$wslconfig_path" > "${wslconfig_path}.tmp" && mv "${wslconfig_path}.tmp" "$wslconfig_path"
}

prompt_wsl_shutdown() {
    printf "\n${YELLOW}WSL must be restarted for changes to take effect.${NC}\n"
    printf "This will temporarily stop all containers.\n\n"
    printf "Shutdown WSL now? (Y/N) [Default: N]: "; read -r restart_choice

    case "$restart_choice" in
        [Yy]*)F%
            printf "\nShutting down WSL...\n"
            printf "${GREEN}WSL shutdown initiated. ✓${NC}\n\nRun ${BLUE}igm show${NC} to start WSL and application containers.\n"
            display_notice
            wsl.exe --shutdown 2>/dev/null
            ;;
        *)
            printf "\n${BLUE}To activate changes later:${NC}\n"
            printf "  1. From Windows, run: ${GREEN}wsl --shutdown${NC}\n"
            printf "  2. Load WSL to start application containers: ${GREEN}igm show${NC}\n"
            ;;
    esac
    display_notice
}

handle_mirror_command() {
    check_wsl_version || {
        printf "${RED}WSL mirrored networking requires WSL 2.0.0+${NC}\n\n"
        printf "Your WSL version doesn't support this feature.\n"
        printf "Update WSL: ${GREEN}wsl --update${NC}\n"
        return 1
    }

    status=$(get_wsl_networking_status)

    case "$1" in
        status)
            printf "WSL Mirrored Networking: "
            format_status "$status"
            printf "\n"
            ;;
        "")
            display_banner
            printf "${GREEN}WSL Mirrored Networking${NC}\n\n"
            printf "Current Status: "
            format_status "$status"
            printf "\n\n${BLUE}About Mirrored Networking:${NC}\n"
            printf "  • Makes WSL ports accessible via ${GREEN}localhost${NC} on Windows\n"
            printf "  • Docker containers accessible at localhost:PORT\n"
            printf "  • No need to find WSL IP address\n"
            printf "  • Works for all applications, not just Docker\n\n"

            case "$status" in
                enabled)
                    printf "Disable mirrored networking? (Y/N): "; read -r choice
                    case "$choice" in
                        [Yy]) 
                            display_banner
                            disable_wsl_mirrored_networking 
                            printf "${GREEN}WSL mirrored networking disabled ✓${NC}\n"
                            prompt_wsl_shutdown
                            ;;
                        *) clear; exit 0 ;;
                    esac
                    ;;
                *)
                    printf "Enable mirrored networking? (Y/N): "; read -r choice
                    case "$choice" in
                        [Yy]) 
                            display_banner
                            enable_wsl_mirrored_networking 
                            printf "${GREEN}WSL mirrored networking enabled ✓${NC}\n"
                            prompt_wsl_shutdown
                            ;;
                        *) clear; exit 0 ;;
                    esac
                    ;;
            esac
            ;;
        *)
            display_banner
            printf "Usage: igm wsl mirror [status]\n\nCommands:\n"
            printf "  status   - Show current status\n"
            printf "  (none)   - Interactive toggle\n\n"
            printf "${RED}Unknown command: $1${NC}\n"
            return 1
            ;;
    esac
}

case "$0" in *wsl-networking.sh) handle_mirror_command "$1" ;; esac
