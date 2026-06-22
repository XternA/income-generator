#!/bin/sh

[ -n "$__CORE_COMMON_CACHED" ] && return
__CORE_COMMON_CACHED=1

clear_screen() { printf '\033[2J\033[H'; }

CORE_upsert_env() {
    _key="$1" _val="$2" _file="$3"
    if [ ! -f "$_file" ]; then
        printf '%s=%s\n' "$_key" "$_val" >> "$_file"
        return
    fi
    grep -q "^${_key}=${_val}$" "$_file" 2>/dev/null && return
    if grep -q "^${_key}=" "$_file" 2>/dev/null; then
        $SED_INPLACE "s|^${_key}=.*|${_key}=${_val}|" "$_file"
    else
        printf '%s=%s\n' "$_key" "$_val" >> "$_file"
    fi
}

CORE_read_env() {
    _key="$1" _file="$2"
    [ -f "$_file" ] && grep "^${_key}=" "$_file" 2>/dev/null | cut -d '=' -f2
}
