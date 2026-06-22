#!/bin/sh

. scripts/core/system.sh

CORE_persist_system_env

# Display system information
printf "Hostname:         $CORE_HOSTNAME
Platform:         $CORE_OS_DISPLAY ($CORE_OS_ID)
Distro Ver:       $CORE_OS_CODENAME $CORE_OS_DISTRO_VERSION
Architecture:     $CORE_OS_ARCH ($CORE_DOCKER_DISPLAY_ARCH)
"
