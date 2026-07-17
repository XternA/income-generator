#!/bin/sh

. scripts/core/version.sh

TUI_MODE=0
for _arg in "$@"; do
    [ "$_arg" = "--tui" ] && TUI_MODE=1
done

case "$1" in
    --force)
        if ! CORE_is_git_repo; then
            printf "Self-update not available in this installation.\n"
            exit 1
        fi
        printf "Forcing update to latest version...\n"
        { git fetch --quiet && git reset --hard --quiet && git pull --quiet; } 2>/dev/null
        printf "\nUpdate complete ✅\n"
        exit 0
        ;;
    --update)
        printf "Checking for new updates available...\n\n"

        CORE_is_git_repo && git fetch --tags --quiet 2>/dev/null
        CORE_get_current_version
        CURRENT=$CORE_CURRENT_VERSION
        CORE_get_latest_version
        LATEST=$CORE_LATEST_VERSION

        if CORE_is_update_available "$CURRENT" "$LATEST"; then
            printf "New update available 🚀\n"
            printf "Current version: %s → Update to: %s\n\n" "$CURRENT" "$LATEST"

            printf "Do you want to update now? [Y/N]: "; read -r choice

            case "$choice" in
                [Yy]*)
                    printf "\nUpdating to latest version..."
                    git fetch --depth=1 origin "+refs/tags/$LATEST:refs/tags/$LATEST" --force --quiet 2>/dev/null && git reset --hard "$LATEST" --quiet 2>/dev/null
                    if [ $? -eq 0 ]; then
                        sleep 1.2
                        printf "\rUpdate complete ✅            \n"
                        rm -f /tmp/igm_updater
                        exit 0
                    else
                        printf "\rUpdate failed ❌              \n"
                        exit 1
                    fi
                    ;;
                *)
                    printf "\nUpdate skipped ❌\n"
                    exit 1
                    ;;
            esac
        else
            echo "No update available ❌"
            exit 1
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

        CORE_is_git_repo && git fetch --tags --quiet 2>/dev/null
        CORE_get_current_version
        CURRENT=$CORE_CURRENT_VERSION
        CORE_get_latest_version
        LATEST=$CORE_LATEST_VERSION

        # Store timestamp on first line, message on remaining lines
        NOW=$(date +%s 2>/dev/null)
        if CORE_is_update_available "$CURRENT" "$LATEST"; then
            {
                echo "$NOW"
                printf "\033[1;5;31m%s\033[0m\n" "New tool update available! 🚀\n"
            } > "$CACHE"
            tail -n +2 "$CACHE"
        else
            echo "$NOW" > "$CACHE"
        fi
        ;;
esac
