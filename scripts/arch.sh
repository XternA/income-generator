#!/bin/sh

if [ -f "$ENV_SYSTEM_FILE" ]; then
    $SED_INPLACE "s/^DEVICE_ID=.*/DEVICE_ID=$HOSTNAME/" "$ENV_SYSTEM_FILE" || echo "DEVICE_ID=$HOSTNAME" >> "$ENV_SYSTEM_FILE"
    $SED_INPLACE "s/^ARCH=.*/ARCH=$OS_DOCKER_ARCH/" "$ENV_SYSTEM_FILE" || echo "ARCH=$OS_DOCKER_ARCH" >> "$ENV_SYSTEM_FILE"
else
    echo "DEVICE_ID=$HOSTNAME" >> "$ENV_SYSTEM_FILE"
    echo "ARCH=$OS_DOCKER_ARCH" >> "$ENV_SYSTEM_FILE"
fi

# Display system information
printf "Hostname:         $HOSTNAME
Platform:         $OS_DISPLAY ($OS_ID)
Distro Ver:       $OS_CODENAME $OS_DISTRO_VERSION
Architecture:     $OS_ARCH ($OS_DOCKER_DISPLAY_ARCH)
"
