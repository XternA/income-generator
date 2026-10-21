#!/bin/sh

# LAN guard: puts app containers behind a guard container that blocks the local
# network (see compose/compose.lan-guard.yml). On by default; `igm lan-guard off`
# stores LAN_GUARD=DISABLED in .env.system.

[ -n "$__CORE_LAN_GUARD_CACHED" ] && return
__CORE_LAN_GUARD_CACHED=1

. scripts/core/common.sh
# The compose file lists are built when app-manager.sh is sourced, which in
# start.sh happens before container-config.sh; load it here so the version
# check below sees the compose command.
. scripts/runtime/container-config.sh

# The overrides use `!reset`, which needs Docker Compose 2.24 or newer.
CORE_lan_guard_supported() {
    _ver=$($CONTAINER_COMPOSE version --short 2>/dev/null)
    _major=$(printf '%s' "${_ver#v}" | cut -d. -f1)
    _minor=$(printf '%s' "${_ver#v}" | cut -d. -f2)
    case "$_major$_minor" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$_major" -gt 2 ] || { [ "$_major" -eq 2 ] && [ "$_minor" -ge 24 ]; }
}

CORE_lan_guard_enabled() {
    [ "$(CORE_read_env LAN_GUARD "$ENV_SYSTEM_FILE")" != "DISABLED" ] && CORE_lan_guard_supported
}

# Prints the -f arguments that put the apps of the given compose groups
# (unlimited, hosting, local, single, service) behind the guard. Prints nothing
# when the guard is off or unsupported, which leaves the deployment unchanged.
CORE_lan_guard_compose_files() {
    CORE_lan_guard_enabled || return 0
    printf -- '-f %s ' "$COMPOSE_DIR/compose.lan-guard.yml"
    for _group in "$@"; do
        printf -- '-f %s ' "$COMPOSE_DIR/compose.$_group.lan-guard.yml"
    done
}

lan_guard_cli() {
    case "$1" in
        on)
            CORE_upsert_env LAN_GUARD ENABLED "$ENV_SYSTEM_FILE"
            printf "LAN guard enabled. Redeploy the applications to apply: igm redeploy\n"
            CORE_lan_guard_supported || printf "Note: Docker Compose 2.24 or newer is required; the guard stays inactive until then.\n"
            ;;
        off)
            CORE_upsert_env LAN_GUARD DISABLED "$ENV_SYSTEM_FILE"
            printf "LAN guard disabled. Redeploy the applications to apply: igm redeploy\n"
            printf "Applications will be able to reach your local network again.\n"
            ;;
        ""|status)
            if CORE_lan_guard_enabled; then
                printf "LAN guard: on (applications cannot reach your local network)\n"
            elif ! CORE_lan_guard_supported; then
                printf "LAN guard: inactive (requires Docker Compose 2.24 or newer)\n"
            else
                printf "LAN guard: off\n"
            fi
            ;;
        *)
            printf "Usage: igm lan-guard [on|off|status]\n"
            return 1
            ;;
    esac
}
