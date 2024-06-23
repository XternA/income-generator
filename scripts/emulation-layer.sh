#!/bin/sh

command="docker run --rm --privileged aptman/qus -s -- -p x86_64"
cron="@reboot $command"
current_crontab=$(crontab -l 2>/dev/null)

add_cron_job() {
    if ! echo "$current_crontab" | grep -Fxq "$cron"; then
        (echo "$current_crontab"; echo "$cron") | crontab -
        echo "\nQEMU emulation layer added."
    else
        echo "\nQEMU emulation layer already exist."
    fi
}

remove_cron_job() {
    if echo "$current_crontab" | grep -Fxq "$cron"; then
        new_crontab=$(echo "$current_crontab" | grep -Fv "$cron")
        echo "$new_crontab" | crontab -
        echo "\nQEMU emulation layer removed."
    fi
}

# Main scripts
if [ "$(uname -m)" != "x86_64" ]; then
    case "$1" in
        --add) add_cron_job ;;
        --remove) remove_cron_job ;;
        *) ;;
    esac
fi
