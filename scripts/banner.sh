#!/bin/sh

: "${BANNER_MODE:=default}"

case "$BANNER_MODE" in
    proxy)   _BANNER_TEXT="Income Generator Proxy Manager" ;;
    config)  _BANNER_TEXT="Income Generator Credentials Manager" ;;
    ip)      _BANNER_TEXT="Income Generator IP Quality Tool" ;;
    backup)  _BANNER_TEXT="Backup & Restore Config Manager" ;;
    *)       _BANNER_TEXT="Income Generator Application Manager" ;;
esac

[ -n "$__BANNER_CACHED" ] && return
__BANNER_CACHED=1

. scripts/colours.sh

display_banner() {
    clear
    printf "${_BANNER_TEXT}\n"
    printf "${GREEN}------------------------------------------${NC}\n"
    [ "$1" != "--noline" ] && echo
}
