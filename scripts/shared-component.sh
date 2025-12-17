#!/bin/sh

[ -n "$__SHARED_COMPONENT_CACHED" ] && return
__SHARED_COMPONENT_CACHED=1

if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ]; then
    export RED='\033[1;38;2;255;105;135m'
    export GREEN='\033[1;38;2;120;255;180m'
    export BLUE='\033[1;38;2;150;240;255m'
    export YELLOW='\033[1;38;2;255;190;80m'
    export PINK='\033[1;38;2;255;121;198m'
    export GREY='\033[38;2;50;50;50m'
else
    export RED='\033[1;91m'
    export GREEN='\033[1;92m'
    export BLUE='\033[1;96m'
    export YELLOW='\033[1;93m'
    export PINK='\033[1;95m'
    export GREY='\033[90m'
fi
export NC='\033[0m'

# Shared path files
export ROOT_DIR=$(pwd)
export ENV_FILE="$ROOT_DIR/.env"
export ENV_SYSTEM_FILE="$ROOT_DIR/.env.system"
export ENV_DEPLOY_FILE="$ROOT_DIR/.env.deploy"
export ENV_DEPLOY_PROXY_FILE="$ROOT_DIR/.env.deploy.proxy"
export ENV_IMAGE_TAG_FILE="$ROOT_DIR/.env.image.tag"
export ENV_PLATFORM_OVERRIDE_FILE="$ROOT_DIR/.env.platform.override"
export JSON_FILE="$ROOT_DIR/apps.json"
export COMPOSE_DIR="$ROOT_DIR/compose"
export PROXY_FILE="$ROOT_DIR/proxies.txt"
export PROXY_INSTALL_LIMIT="$ROOT_DIR/.env.proxy.limit"

# Shared Docker labels for scoped operations
export IGM_PROJECT_LABEL="project=standard"
export IGM_PROXY_PROJECT_LABEL="project=proxy"

# Shared system files
export SYSTEM_ENV_FILES="
--env-file $ENV_FILE
--env-file $ENV_SYSTEM_FILE
--env-file $ENV_IMAGE_TAG_FILE
--env-file $ENV_PLATFORM_OVERRIDE_FILE
"

# Pre-source components ----------------
. scripts/system-detect.sh

# Declared util component ----------------
export SYS_INFO="sh scripts/arch.sh"
export ENCRYPTOR="sh scripts/encryptor.sh"
export CLEANUP="sh scripts/cleanup.sh"
export POST_OPS="sh scripts/post-operation.sh"
export APP_SELECTION="sh scripts/app-selection.sh"
export APP_CONFIG="sh scripts/app-config.sh"
export BACKUP_RESTORE="sh scripts/backup-restore.sh"
export SET_LIMIT="sh scripts/set-limit.sh"
export UPDATE_CHECKER="sh scripts/check-tool-update.sh"
export VIEW_CONFIG="sh scripts/config-viewer.sh"

# Declared quick util operation ----------------
export ENCRYPT_CRED="$ENCRYPTOR -es $ENV_FILE"
export DECRYPT_CRED="$ENCRYPTOR -ds $ENV_FILE"

# Declare tool alias ----------------
case "$OS_DISPLAY" in
    Linux) export SED_INPLACE="sed -i" ;;
    Darwin) export SED_INPLACE="gsed -i" ;;
esac
