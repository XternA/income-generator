#!/bin/sh

. scripts/core/resources.sh

LIMIT_TYPE=${1:-${LIMIT_TYPE:-min}}
CORE_calculate_limits "$LIMIT_TYPE"

case "$LIMIT_TYPE" in
    base) __limit_label=BASE ;; 
    min) __limit_label=MIN ;; 
    low) __limit_label=LOW ;;
    mid) __limit_label=MID  ;; 
    max) __limit_label=MAX ;; 
    *) __limit_label="$LIMIT_TYPE" ;;
esac

STATS="Limit Type Applied:       ${YELLOW}${__limit_label}${NC}
Number of CPU Cores:      ${YELLOW}${CORE_CPU_CORES}${NC}
Total RAM:                ${YELLOW}${CORE_TOTAL_RAM_MB}${NC} ${YELLOW}MB${NC}
Calculated CPU Limit:     ${YELLOW}${CORE_CPU_LIMIT}${NC}
Calculated RAM Limit:     ${YELLOW}${CORE_RAM_LIMIT_MB} MB${NC}
Calculated Reservation:   ${YELLOW}${CORE_RAM_RESERVE_MB} MB${NC}"
