#!/bin/sh

[ -n "$__CORE_RESOURCES_CACHED" ] && return
__CORE_RESOURCES_CACHED=1

. scripts/core/common.sh

CORE_detect_hardware() {
    [ -n "$__CORE_HW_DETECTED" ] && return
    __CORE_HW_DETECTED=1

    if [ "$OS_IS_LINUX" = "true" ]; then
        CORE_CPU_CORES=$(nproc)
        _total_ram_k=$(free -k | awk '/^Mem:/{print $2}')
    elif [ "$OS_IS_DARWIN" = "true" ]; then
        CORE_CPU_CORES=$(sysctl -n hw.physicalcpu)
        _total_ram_k=$(sysctl -n hw.memsize)
        _total_ram_k=$((_total_ram_k / 1024))
    fi

    CORE_TOTAL_RAM_MB=$((_total_ram_k / 1024))
    CORE_MAX_CPU_LIMIT=$((CORE_CPU_CORES / 2))
}

CORE_calculate_limits() {
    CORE_detect_hardware

    _default_cpu_limit=2
    _min_cpu_limit=0.5
    _alt_min_cpu_limit=0.8
    _default_ram_limit_mb=$((CORE_TOTAL_RAM_MB / 4))
    _bare_min_ram_limit_mb=$((CORE_TOTAL_RAM_MB / 8))

    case $1 in
        base)
            CORE_CPU_LIMIT="0.2"
            CORE_RAM_LIMIT_MB="350"
            CORE_ALT_MIN_CPU_LIMIT=$_alt_min_cpu_limit
            ;;
        min)
            CORE_CPU_LIMIT=$_min_cpu_limit
            CORE_RAM_LIMIT_MB=$_bare_min_ram_limit_mb
            CORE_ALT_MIN_CPU_LIMIT=$_alt_min_cpu_limit
            ;;
        low)
            CORE_CPU_LIMIT="$((_default_cpu_limit - 1)).0"
            CORE_RAM_LIMIT_MB=$((_bare_min_ram_limit_mb + (_default_ram_limit_mb - _bare_min_ram_limit_mb) / 2))
            CORE_ALT_MIN_CPU_LIMIT=$CORE_CPU_LIMIT
            ;;
        mid)
            CORE_CPU_LIMIT="$_default_cpu_limit.0"
            CORE_RAM_LIMIT_MB=$_default_ram_limit_mb
            CORE_ALT_MIN_CPU_LIMIT=$CORE_CPU_LIMIT
            ;;
        max)
            CORE_CPU_LIMIT="$((CORE_MAX_CPU_LIMIT + 1)).0"
            CORE_RAM_LIMIT_MB=$((_bare_min_ram_limit_mb + (_default_ram_limit_mb + _bare_min_ram_limit_mb) / 2))
            CORE_ALT_MIN_CPU_LIMIT=$CORE_CPU_LIMIT
            ;;
        *)
            return 1
            ;;
    esac

    CORE_LIMIT_TYPE="$1"
    CORE_RAM_RESERVE_MB=$((CORE_RAM_LIMIT_MB / 2))
    CORE_RAM_LIMIT="${CORE_RAM_LIMIT_MB}m"
    CORE_RAM_RESERVE="${CORE_RAM_RESERVE_MB}m"
}

CORE_persist_limits() {
    CORE_upsert_env "CPU_LIMIT" "$CORE_CPU_LIMIT" "$ENV_SYSTEM_FILE"
    CORE_upsert_env "RAM_LIMIT" "$CORE_RAM_LIMIT" "$ENV_SYSTEM_FILE"
    CORE_upsert_env "RAM_RESERVE" "$CORE_RAM_RESERVE" "$ENV_SYSTEM_FILE"
    CORE_upsert_env "ALT_MIN_CPU_LIMIT" "$CORE_ALT_MIN_CPU_LIMIT" "$ENV_SYSTEM_FILE"
}

CORE_read_resource_limit() {
    CORE_RESOURCE_LIMIT=$(CORE_read_env "RESOURCE_LIMIT" "$ENV_SYSTEM_FILE")
    [ -z "$CORE_RESOURCE_LIMIT" ] && CORE_RESOURCE_LIMIT="min"
}

CORE_set_resource_limit() {
    case "$1" in
        base|min|low|mid|max) ;;
        *) return 1 ;;
    esac
    CORE_upsert_env "RESOURCE_LIMIT" "$1" "$ENV_SYSTEM_FILE"
}

CORE_apply_limits() {
    _std=$(docker ps --filter "label=project=standard" --format '{{.Names}}' 2>/dev/null)
    if [ -n "$_std" ]; then
        printf '%s\n' "$_std" | xargs docker update \
            --cpus="$CORE_CPU_LIMIT" \
            --memory="$CORE_RAM_LIMIT" \
            --memory-swap="$CORE_RAM_LIMIT" \
            --memory-reservation="$CORE_RAM_RESERVE" \
            > /dev/null 2>&1 || true
    fi
    _proxy=$(docker ps --filter "label=project=proxy" --format '{{.Names}}' 2>/dev/null)
    if [ -n "$_proxy" ]; then
        printf '%s\n' "$_proxy" | xargs docker update \
            --cpus="$CORE_ALT_MIN_CPU_LIMIT" \
            --memory="$CORE_RAM_LIMIT" \
            --memory-swap="$CORE_RAM_LIMIT" \
            --memory-reservation="$CORE_RAM_RESERVE" \
            > /dev/null 2>&1 || true
    fi
}
