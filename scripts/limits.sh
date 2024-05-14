#!/bin/sh

ENV_FILE="$(pwd)/.env"
LIMIT_TYPE=${1:-min}

# ANSI color codes
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

if [ $(uname) = 'Linux' ]; then
    CPU_CORES=$(nproc)
    TOTAL_RAM=$(free -k | awk '/^Mem:/{print $2}')
    SED_INPLACE="sed -i"
elif [ $(uname) = 'Darwin' ]; then
    CPU_CORES=$(sysctl -n hw.physicalcpu)
    TOTAL_RAM=$(sysctl -n hw.memsize)
    TOTAL_RAM=$((TOTAL_RAM / 1050))
    SED_INPLACE="sed -i .bak"
fi
TOTAL_RAM_MB=$((TOTAL_RAM / 1024))

# Calculate default and bare minimum CPU and RAM limits
DEFAULT_CPU_LIMIT=2               # Default CPU limit
MIN_CPU_LIMIT=0.5                 # Minimum CPU limit
ALT_MIN_CPU_LIMIT=0.8             # Min required CPU Limit for some process.
MAX_CPU_LIMIT=$((CPU_CORES / 2))  # Maximum CPU limit set to half the available cores

DEFAULT_RAM_LIMIT_MB=$((TOTAL_RAM_MB / 4))   # Use 25% of total RAM
BARE_MIN_RAM_LIMIT_MB=$((TOTAL_RAM_MB / 8))  # Use 12.5% of total RAM

# Determine which limits to use based on the command-line argument
case $LIMIT_TYPE in
    base)
        CPU_LIMIT_STR="0.2"
        RAM_LIMIT_MB="320"
        ALT_MIN_CPU_LIMIT=$ALT_MIN_CPU_LIMIT
        ;;
    min)
        CPU_LIMIT_STR=$MIN_CPU_LIMIT
        RAM_LIMIT_MB=$BARE_MIN_RAM_LIMIT_MB
        ALT_MIN_CPU_LIMIT=$ALT_MIN_CPU_LIMIT
        ;;
    low)
        CPU_LIMIT_STR="$((DEFAULT_CPU_LIMIT - 1)).0"
        RAM_LIMIT_MB=$((BARE_MIN_RAM_LIMIT_MB + (DEFAULT_RAM_LIMIT_MB - BARE_MIN_RAM_LIMIT_MB) / 2))
        ALT_MIN_CPU_LIMIT=$CPU_LIMIT_STR
        ;;
    mid)
        CPU_LIMIT_STR="$DEFAULT_CPU_LIMIT.0"
        RAM_LIMIT_MB=$DEFAULT_RAM_LIMIT_MB
        ALT_MIN_CPU_LIMIT=$CPU_LIMIT_STR
        ;;
    max)
        CPU_LIMIT_STR="$((MAX_CPU_LIMIT + 1)).0"
        RAM_LIMIT_MB=$((BARE_MIN_RAM_LIMIT_MB + (DEFAULT_RAM_LIMIT_MB + BARE_MIN_RAM_LIMIT_MB) / 2))
        ALT_MIN_CPU_LIMIT=$CPU_LIMIT_STR
        ;;
    *)
        echo "Invalid argument. Use 'base', 'min', 'low', 'mid', or 'max'."
        exit 1
        ;;
esac

RAM_RESERVE=$((RAM_LIMIT_MB / 2))

# Display calculated limits with colored numbers and indentation
printf "Limit Type Applied:       ${YELLOW}%s${NC}\n" "$(echo "${LIMIT_TYPE}" | tr '[:lower:]' '[:upper:]')"
printf "Number of CPU Cores:      ${YELLOW}%s${NC}\n" "$CPU_CORES"
printf "Total RAM:                ${YELLOW}%s${NC} ${YELLOW}MB${NC}\n" "$TOTAL_RAM_MB"

printf "Calculated CPU Limit:     ${YELLOW}%s${NC}\n" "$CPU_LIMIT_STR"
printf "Calculated RAM Limit:     ${YELLOW}%s MB${NC}\n" "$RAM_LIMIT_MB"
printf "Calculated Reservation:   ${YELLOW}%s MB${NC}\n" "${RAM_RESERVE}"

# Remove color codes before writing to .env file
RAM_LIMIT="${RAM_LIMIT_MB}m"
RAM_RESERVE="${RAM_RESERVE}m"

if [ -f "$ENV_FILE" ]; then
    if grep -q "^CPU_LIMIT=" "$ENV_FILE"; then
        $SED_INPLACE "s/^CPU_LIMIT=.*/CPU_LIMIT=$CPU_LIMIT_STR/" "$ENV_FILE"
    else
        echo "CPU_LIMIT=$CPU_LIMIT_STR" >> "$ENV_FILE"
    fi

    if grep -q "^RAM_LIMIT=" "$ENV_FILE"; then
        $SED_INPLACE "s/^RAM_LIMIT=.*/RAM_LIMIT=$RAM_LIMIT/" "$ENV_FILE"
    else
        echo "RAM_LIMIT=$RAM_LIMIT" >> "$ENV_FILE"
    fi

    if grep -q "^RAM_RESERVE=" "$ENV_FILE"; then
        $SED_INPLACE "s/^RAM_RESERVE=.*/RAM_RESERVE=$RAM_RESERVE/" "$ENV_FILE"
    else
        echo "RAM_RESERVE=$RAM_RESERVE" >> "$ENV_FILE"
    fi

    if grep -q "^ALT_MIN_CPU_LIMIT=" "$ENV_FILE"; then
        $SED_INPLACE "s/^ALT_MIN_CPU_LIMIT=.*/ALT_MIN_CPU_LIMIT=$ALT_MIN_CPU_LIMIT/" "$ENV_FILE"
    else
        echo "ALT_MIN_CPU_LIMIT=$ALT_MIN_CPU_LIMIT" >> "$ENV_FILE"
    fi
else
    echo "CPU_LIMIT=$CPU_LIMIT_STR" >> "$ENV_FILE"
    echo "RAM_LIMIT=$RAM_LIMIT" >> "$ENV_FILE"
    echo "RAM_RESERVE=$RAM_RESERVE" >> "$ENV_FILE"
    echo "ALT_MIN_CPU_LIMIT=$ALT_MIN_CPU_LIMIT" >> "$ENV_FILE"
fi
