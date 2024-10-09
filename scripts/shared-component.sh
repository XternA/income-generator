#!/bin/sh

export RED='\033[1;91m'
export GREEN='\033[1;92m'
export BLUE='\033[1;96m'
export YELLOW='\033[1;93m'
export PINK='\033[1;95m'
export NC='\033[0m'

export CONTAINER_ALIAS="docker"
export ROOT_DIR=$(pwd)
export ENV_FILE="$ROOT_DIR/.env"
export ENV_SYSTEM_FILE="$ROOT_DIR/.env.system"
export ENV_DEPLOY_FILE="$ROOT_DIR/.env.deploy"
export JSON_FILE="$ROOT_DIR/apps.json"
export COMPOSE_DIR="$ROOT_DIR/compose"
export PROXY_FILE="$ROOT_DIR/proxies.txt"

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
