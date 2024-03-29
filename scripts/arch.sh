#!/bin/sh

ENV_FILE="$(pwd)/.env"
HOST="$(hostname)"
OS="$(uname -s)"
RAW_ARCH="$(uname -m)"
ARCH=$RAW_ARCH

if [ $(uname) = 'Linux' ]; then
    SED_INPLACE="sed -i"
elif [ $(uname) = 'Darwin' ]; then
    SED_INPLACE="sed -i .bak"
fi

case $ARCH in
    "armv7l")
        ARCH="arm32v7"
        DISPLAY_ARCH="$ARCH ($RAW_ARCH)"
        ;;
    "aarch64")
        ARCH="arm64v8"
        DISPLAY_ARCH="$ARCH ($RAW_ARCH)"
        ;;
    *)
        ARCH="latest"
        DISPLAY_ARCH=$RAW_ARCH
        ;;
esac

echo "Hostname:         $HOST"
echo "Platform:         $OS"
echo "Architecture:     $DISPLAY_ARCH\n"

if [ -f "$ENV_FILE" ]; then
    if grep -q "^DEVICE_ID=" "$ENV_FILE"; then
        $SED_INPLACE "s/^DEVICE_ID=.*/DEVICE_ID=$HOST/" "$ENV_FILE"
    else
        echo "DEVICE_ID=$HOST" >> "$ENV_FILE"
    fi
    if grep -q "^ARCH=" "$ENV_FILE"; then
        $SED_INPLACE "s/^ARCH=.*/ARCH=$ARCH/" "$ENV_FILE"
    else
        echo "ARCH=$ARCH" >> "$ENV_FILE"
    fi
else
    echo "DEVICE_ID=$HOST" >> "$ENV_FILE"
    echo "ARCH=$ARCH" >> "$ENV_FILE"
fi
