#!/bin/sh

HOST="$(hostname)"
OS="$(uname -s)"
RAW_ARCH="$(uname -m)"

case $RAW_ARCH in
    arm64|aarch64)
        ARCH="arm64v8"
        ;;
    armv7l)
        ARCH="arm32v7"
        ;;
    *)
        ARCH="latest"
        ;;
esac

DISPLAY_ARCH="$RAW_ARCH ($ARCH)"

echo "Hostname:         $HOST"
echo "Platform:         $OS"
echo "Architecture:     $DISPLAY_ARCH\n"

if [ -f "$ENV_SYSTEM_FILE" ]; then
    $SED_INPLACE "/^DEVICE_ID=/c\DEVICE_ID=$HOST" "$ENV_SYSTEM_FILE" || echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    $SED_INPLACE "/^ARCH=/c\ARCH=$ARCH" "$ENV_SYSTEM_FILE" || echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
else
    echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
fi
