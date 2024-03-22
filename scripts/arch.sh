#!/bin/sh

ENV_FILE="$(pwd)/.env"
HOST="$(hostname)"
OS="$(uname -s)"
RAW_ARCH="$(uname -m)"
ARCH=$RAW_ARCH

case $ARCH in
    "armv7l")
        ARCH="arm32v7"
        ;;
    "aarch64")
        ARCH="arm64v8"
        ;;
esac

echo "Hostname:         $HOST"
echo "Platform:         $OS"
echo "Architecture:     $ARCH ($RAW_ARCH)\n"

if [ "$ARCH" != "arm32v7" ] && [ "$ARCH" != "arm64v8" ]; then
    ARCH="latest"
fi

if [ -f "$ENV_FILE" ]; then
    if grep -q "^DEVICE_ID=" "$ENV_FILE"; then
        sed -i "s/^DEVICE_ID=.*/DEVICE_ID=$HOST/" "$ENV_FILE"
    else
        echo "DEVICE_ID=$HOST" >> "$ENV_FILE"
    fi
    if grep -q "^ARCH=" "$ENV_FILE"; then
        sed -i "s/^ARCH=.*/ARCH=$ARCH/" "$ENV_FILE"
    else
        echo "ARCH=$ARCH" >> "$ENV_FILE"
    fi
else
    echo "DEVICE_ID=$HOST" >> "$ENV_FILE"
    echo "ARCH=$ARCH" >> "$ENV_FILE"
fi
