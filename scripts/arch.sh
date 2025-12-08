#!/bin/sh

. scripts/system-detect.sh

OS="$OS_DISPLAY"
RAW_ARCH="$OS_RAW_ARCH"
ARCH="$OS_DOCKER_ARCH"

if [ "$OS_IS_DARWIN" = "true" ]; then
    DISTRO="$OS"
    OS="$(sw_vers -productName)"
    VERSION="$(sw_vers -productVersion)"
    CODENAME=$(
        awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/ {printf "%s", substr($NF, 1, length($NF)-1)}' \
        /System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf
    )
elif [ -f /etc/os-release ]; then
    while IFS='=' read -r key val; do
        val=${val%\"}; val=${val#\"}
        case "$key" in
            ID) DISTRO=$val ;;
            VERSION_CODENAME|UBUNTU_CODENAME) [ -z "$CODENAME" ] && CODENAME=$val ;;
            VERSION_ID) VERSION=$val ;;
        esac
    done < /etc/os-release
elif [ -f /etc/lsb-release ]; then
    while IFS='=' read -r key val; do
        val=${val%\"}; val=${val#\"}
        case "$key" in
            DISTRIB_ID) DISTRO=$(echo "$val" | tr A-Z a-z) ;;
            DISTRIB_CODENAME) CODENAME=$val ;;
            DISTRIB_RELEASE) VERSION=$val ;;
        esac
    done < /etc/lsb-release
elif [ -f /etc/issue ]; then
    read -r DISTRO VERSION _ < /etc/issue
    DISTRO=$(echo "$DISTRO" | tr A-Z a-z)
    CODENAME=""
else
    DISTRO=$(echo "$OS" | tr A-Z a-z)
    CODENAME=""
    VERSION=""
fi

if [ -f "$ENV_SYSTEM_FILE" ]; then
    $SED_INPLACE "s/^DEVICE_ID=.*/DEVICE_ID=$HOST/" "$ENV_SYSTEM_FILE" || echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    $SED_INPLACE "s/^ARCH=.*/ARCH=$ARCH/" "$ENV_SYSTEM_FILE" || echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
else
    echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
fi

# Display system information
printf "Hostname:         $HOST
Platform:         $OS ($DISTRO)
Distro Ver:       $CODENAME $VERSION
Architecture:     $RAW_ARCH ($OS_DISPLAY_ARCH)
"
