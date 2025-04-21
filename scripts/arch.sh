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

if [ -f /etc/os-release ]; then
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
  DISTRO=$(uname -s | tr A-Z a-z)
  CODENAME=""
  VERSION=""
fi

DISPLAY_ARCH="$RAW_ARCH ($ARCH)"

echo "Hostname:         $HOST"
echo "Platform:         $OS ($DISTRO)"
echo "Distro Ver:       $CODENAME $VERSION"
echo "Architecture:     $DISPLAY_ARCH"
echo

if [ -f "$ENV_SYSTEM_FILE" ]; then
    $SED_INPLACE "s/^DEVICE_ID=.*/DEVICE_ID=$HOST/" "$ENV_SYSTEM_FILE" || echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    $SED_INPLACE "s/^ARCH=.*/ARCH=$ARCH/" "$ENV_SYSTEM_FILE" || echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
else
    echo "DEVICE_ID=$HOST" >> "$ENV_SYSTEM_FILE"
    echo "ARCH=$ARCH" >> "$ENV_SYSTEM_FILE"
fi
