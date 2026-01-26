#!/bin/sh

[ -n "$__ARCH_PLATFORM_RUNTIME_CACHED" ] && return
__ARCH_PLATFORM_RUNTIME_CACHED=1

run_platform_override() {
    : > "$ENV_PLATFORM_OVERRIDE_FILE"

    jq -r --arg arch "$OS_DOCKER_ARCH" '
        .[] | select(.platform_override != null) |
        . as $app |
        .platform_override | to_entries[] |
        select(.value | index($arch) != null) |
        "\($app.name) \(.key)"
    ' "$JSON_FILE" | while read -r app_name platform; do
        printf "%s_PLATFORM=linux/%s\n" "$app_name" "$platform" >> "$ENV_PLATFORM_OVERRIDE_FILE"
    done
}

# Init
run_platform_override
