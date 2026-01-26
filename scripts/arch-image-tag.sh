#!/bin/sh

[ -n "$__ARCH_IMAGE_TAG_CACHED" ] && return
__ARCH_IMAGE_TAG_CACHED=1

APP_DATA=$(jq -r --arg ARCH "$OS_DOCKER_ARCH" '
    .[] | select(.image_tag != null or .service_tag != null) |
    {name: .name, image_tag: .image_tag[$ARCH], service_tag: .service_tag[$ARCH]} |
    "\(.name) \(.image_tag) \(.service_tag)"
' "$JSON_FILE")

run_arch_image_tag() {
    : > "$ENV_IMAGE_TAG_FILE"

    printf '%s\n' "$APP_DATA" | while read -r name image_tag service_tag; do
        [ "$image_tag" != "null" ] && printf '%s_TAG=:%s\n' "$name" "$image_tag" >> "$ENV_IMAGE_TAG_FILE"
        [ "$service_tag" != "null" ] && printf '%s_SERVICE_TAG=:%s\n' "$name" "$service_tag" >> "$ENV_IMAGE_TAG_FILE"
    done
}

# Init
run_arch_image_tag
