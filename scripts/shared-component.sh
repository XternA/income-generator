#!/bin/sh

export RED='\033[1;91m'
export GREEN='\033[1;92m'
export BLUE='\033[1;96m'
export YELLOW='\033[1;93m'
export PINK='\033[1;95m'
export NC='\033[0m'

export ENV_FILE="$(pwd)/.env"
export ENV_DEPLOY_FILE="$(pwd)/.env.deploy"
export JSON_FILE="$(pwd)/apps.json"

# Declared util component ----------------
ARCH="sh scripts/arch.sh"
CLEANUP="sh scripts/cleanup.sh"
APP_SELECTION="sh scripts/app-selection.sh"
APP_CONFIG="sh scripts/config.sh"
BACKUP_RESTORE="sh scripts/backup-restore.sh"
SET_LIMIT="sh scripts/set-limit.sh"
UPDATE_CHECKER="sh scripts/check-tool-update.sh"
