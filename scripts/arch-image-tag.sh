#!/bin/sh

APP_DATA=$(jq -r --arg ARCH "$OS_DOCKER_ARCH" '
    .[] | select(.image_tag != null or .service_tag != null) |
    {name: .name, image_tag: .image_tag[$ARCH], service_tag: .service_tag[$ARCH]} |
    "\(.name) \(.image_tag) \(.service_tag)"
' "$JSON_FILE")

run_arch_image_tag() {
    : > "$ENV_IMAGE_TAG_FILE"
    echo "$APP_DATA" | while read -r name image_tag service_tag; do
        if [ "$image_tag" != "null" ]; then
            image_tag=":${image_tag}"
            tag_name="${name}_TAG"
            if grep -q "^${tag_name}=" "$ENV_IMAGE_TAG_FILE"; then
                $SED_INPLACE "s/^${tag_name}=.*/${tag_name}=${image_tag}/" "$ENV_IMAGE_TAG_FILE"
            else
                echo "${tag_name}=${image_tag}" >> "$ENV_IMAGE_TAG_FILE"
            fi
        fi

        if [ "$service_tag" != "null" ]; then
            service_tag=":${service_tag}"
            tag_name="${name}_SERVICE_TAG"
            if grep -q "^${tag_name}=" "$ENV_IMAGE_TAG_FILE"; then
                $SED_INPLACE "s/^${tag_name}=.*/${tag_name}=${service_tag}/" "$ENV_IMAGE_TAG_FILE"
            else
                echo "${tag_name}=${service_tag}" >> "$ENV_IMAGE_TAG_FILE"
            fi
        fi
    done
}

# Init
run_arch_image_tag
