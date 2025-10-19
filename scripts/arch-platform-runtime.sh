#!/bin/sh

case $(uname -m) in
    x86_64|amd64) ARCH=amd64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    armv7l|armv6l) ARCH=arm32 ;;
esac

run_platform_override() {
    : > "$ENV_PLATFORM_OVERRIDE_FILE"
    extract_all_app_data .platform_override | while read -r app_name array; do
        [ "x$array" = "xnull" ] && continue

        clean=${array#\{}; clean=${clean%\}}; clean=$(echo "$clean" | tr -d '"')
        key=${clean%%:*}; values=${clean#*:}; values=${values#\[}; values=${values%\]}

        old_ifs=$IFS
        IFS=','
        for arch in $values; do
            if [ "$arch" = "$ARCH" ]; then
                printf "%s_PLATFORM=linux/%s\n" "$app_name" "$key" >> "$ENV_PLATFORM_OVERRIDE_FILE"
            fi
        done
        IFS=$old_ifs
    done
}

# Init
run_platform_override
