#!/bin/sh

URL="https://api.github.com/repos/xterna/income-generator"

is_update_available() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    V1=$(echo "$1" | sed 's/^v//' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    V2=$(echo "$2" | sed 's/^v//' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    [ "$V2" -gt "$V1" ]
}

get_current_version() {
    ver=$(git describe --tags 2>/dev/null)
    echo "${ver%%-*}"
}

case "$1" in
    --force)
        printf "Forcing update to latest version...\n"
        { git fetch --quiet && git reset --hard --quiet && git pull --quiet; } 2>/dev/null
        printf "\nUpdate complete ✅\n"
        ;;
    --update)
        printf "Checking for new updates available...\n\n"

        git fetch --tags --quiet 2>/dev/null
        CURRENT=$(get_current_version)
        LATEST=$(curl -s --connect-timeout 3 --max-time 3 "$URL/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)

        if is_update_available "$CURRENT" "$LATEST"; then
            printf "New update available 🚀\n"
            printf "Current version: %s → Update to: %s\n\n" "$CURRENT" "$LATEST"
            printf "Do you want to update now? [Y/N]: "; read -r choice

            case "$choice" in
                [Yy]*)
                    printf "\nUpdating to latest version..."
                    git fetch --depth=1 origin tag "$LATEST" --quiet 2>/dev/null && git reset --hard "$LATEST" --quiet 2>/dev/null
                    if [ $? -eq 0 ]; then
                        sleep 1.2
                        printf "\rUpdate complete ✅            \n"
                        rm -f /tmp/igm_updater
                    else
                        printf "\rUpdate failed ❌              \n"
                        exit 1
                    fi
                    ;;
                *)
                    printf "\nUpdate skipped ❌\n"
                    ;;
            esac
        else
            echo "No update available ❌"
        fi
        ;;
    *)
        CACHE="/tmp/igm_updater"

        # Use cache if fresh (< 15 minutes = 900 seconds)
        if [ -f "$CACHE" ]; then
            CACHE_TIME=$(head -n 1 "$CACHE" 2>/dev/null)
            NOW=$(date +%s 2>/dev/null || echo 0)
            [ "$NOW" -gt 0 ] && [ "$CACHE_TIME" -gt 0 ] 2>/dev/null && [ $((NOW - CACHE_TIME)) -lt 900 ] && tail -n +2 "$CACHE" && exit 0
        fi

        git fetch --tags --quiet 2>/dev/null
        CURRENT=$(get_current_version)
        LATEST=$(curl -s --connect-timeout 1 --max-time 1 "$URL/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)

        # Store timestamp on first line, message on remaining lines
        NOW=$(date +%s 2>/dev/null)
        if is_update_available "$CURRENT" "$LATEST"; then
            {
                echo "$NOW"
                printf "\033[1m\033[5m\033[91m%s\033[0m\n" "New tool update available! 🚀"
            } > "$CACHE"
            tail -n +2 "$CACHE"
        else
            echo "$NOW" > "$CACHE"
        fi
        ;;
esac
