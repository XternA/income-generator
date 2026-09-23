#!/bin/sh

[ -n "$__CORE_VERSION_CACHED" ] && return
__CORE_VERSION_CACHED=1

. scripts/core/common.sh

CORE_GITHUB_API_URL="https://api.github.com/repos/xterna/income-generator"

CORE_is_git_repo() {
    [ -d "$ROOT_DIR/.git" ] || [ -d .git ]
}

CORE_get_current_version() {
    if CORE_is_git_repo; then
        _ver=$(git describe --tags 2>/dev/null)
        _clone_ver=$(echo "$_ver" | sed 's/-[0-9]*-g[0-9a-f]*$//')
        if [ -n "$_clone_ver" ]; then
            CORE_CURRENT_VERSION="$_clone_ver"
            return
        fi
    fi
    CORE_CURRENT_VERSION="$IGM_VERSION"
}

CORE_get_latest_version() {
    CORE_LATEST_VERSION=$(curl -s --connect-timeout 3 --max-time 3 "$CORE_GITHUB_API_URL/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)
}

CORE_is_update_available() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    _cv=$(printf '%s' "$1" | sed 's/^v//'); _lv=$(printf '%s' "$2" | sed 's/^v//')
    _cb=${_cv%%-*}; _lb=${_lv%%-*}
    _cv_n=$(printf '%s' "$_cb" | awk -F. '{printf "%d%03d%03d",$1,$2,$3}')
    _lv_n=$(printf '%s' "$_lb" | awk -F. '{printf "%d%03d%03d",$1,$2,$3}')
    [ "$_lv_n" -gt "$_cv_n" ] && return 0
    [ "$_lv_n" -lt "$_cv_n" ] && return 1
    case "$_cv" in *-*) _cp=${_cv#*-} ;; *) _cp="" ;; esac
    case "$_lv" in *-*) _lp=${_lv#*-} ;; *) _lp="" ;; esac
    [ -z "$_lp" ] && [ -n "$_cp" ] && return 0
    [ -n "$_lp" ] && [ -z "$_cp" ] && return 1
    _cs=$(printf '%s' "$_cp" | sed 's/^[^0-9]*//')
    _ls=$(printf '%s' "$_lp" | sed 's/^[^0-9]*//')
    _i=1
    while :; do
        _a=$(printf '%s' "$_cs" | awk -F'[^0-9]+' -v n="$_i" '{print $n}')
        _b=$(printf '%s' "$_ls" | awk -F'[^0-9]+' -v n="$_i" '{print $n}')
        [ -z "$_a" ] && [ -z "$_b" ] && return 1
        [ -z "$_b" ] && return 1
        [ -z "$_a" ] && return 0
        [ "$_b" -gt "$_a" ] && return 0
        [ "$_b" -lt "$_a" ] && return 1
        _i=$((_i + 1))
    done
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
