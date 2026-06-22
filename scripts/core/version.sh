#!/bin/sh

[ -n "$__CORE_VERSION_CACHED" ] && return
__CORE_VERSION_CACHED=1

. scripts/core/common.sh

CORE_GITHUB_API_URL="https://api.github.com/repos/xterna/income-generator"

CORE_is_git_repo() {
    [ -d "$ROOT_DIR/.git" ] || [ -d .git ]
}

CORE_get_current_version() {
    if [ -n "$IGM_VERSION" ]; then
        CORE_CURRENT_VERSION="$IGM_VERSION"
        return
    fi
    _ver=$(git describe --tags 2>/dev/null)
    CORE_CURRENT_VERSION="${_ver%%-*}"
}

CORE_get_latest_version() {
    CORE_LATEST_VERSION=$(curl -s --connect-timeout 3 --max-time 3 "$CORE_GITHUB_API_URL/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
}

CORE_is_update_available() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    _v1=$(echo "$1" | sed 's/^v//' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    _v2=$(echo "$2" | sed 's/^v//' | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')
    [ "$_v2" -gt "$_v1" ]
}

CORE_check_update() {
    CORE_get_current_version
    CORE_get_latest_version
    if CORE_is_update_available "$CORE_CURRENT_VERSION" "$CORE_LATEST_VERSION"; then
        CORE_UPDATE_AVAILABLE="true"
    else
        CORE_UPDATE_AVAILABLE="false"
    fi
}
