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
    # Strip only the git describe suffix (-N-ghash), preserve pre-release (-beta.X)
    CORE_CURRENT_VERSION=$(echo "$_ver" | sed 's/-[0-9]*-g[0-9a-f]*$//')
}

CORE_get_latest_version() {
    CORE_LATEST_VERSION=$(curl -s --connect-timeout 3 --max-time 3 "$CORE_GITHUB_API_URL/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
}

CORE_is_update_available() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    _cv=$(echo "$1" | sed 's/^v//'); _lv=$(echo "$2" | sed 's/^v//')
    # Compare base versions (MAJOR.MINOR.PATCH)
    _cb=$(echo "$_cv" | cut -d- -f1); _lb=$(echo "$_lv" | cut -d- -f1)
    _cv_n=$(echo "$_cb" | awk -F. '{printf "%d%03d%03d",$1,$2,$3}')
    _lv_n=$(echo "$_lb" | awk -F. '{printf "%d%03d%03d",$1,$2,$3}')
    [ "$_lv_n" -gt "$_cv_n" ] && return 0
    [ "$_lv_n" -lt "$_cv_n" ] && return 1
    # Same base — compare pre-release suffix numerically
    _cp=$(echo "$_cv" | grep -oE '\-.*$' || true)
    _lp=$(echo "$_lv" | grep -oE '\-.*$' || true)
    [ -z "$_lp" ] && [ -n "$_cp" ] && return 0
    [ -n "$_lp" ] && [ -z "$_cp" ] && return 1
    _cn=$(echo "$_cp" | grep -oE '[0-9]+$' || echo 0)
    _ln=$(echo "$_lp" | grep -oE '[0-9]+$' || echo 0)
    [ "$_ln" -gt "$_cn" ]
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
