#!/bin/sh

set_if_not_defined() {
    [ -z "$EDITOR" ] && EDITOR=nano
}

sync_editor() {
    EDITOR="$(sed -n '/^EDITOR=/ { s/^EDITOR=//; p; q }' $ENV_SYSTEM_FILE)"
    [ -z "$EDITOR" ] && echo "EDITOR=nano" >> "$ENV_SYSTEM_FILE"
}

set_editor() {
    local editors="nvim vim vi nano"

    available_editors=""
    for editor in $editors; do
        command -v "$editor" >/dev/null 2>&1 && available_editors="$available_editors $editor"
    done

    if [ -z "$available_editors" ]; then
        printf "No suitable editors found. Install ${RED}nano${NC} editor first.\n\n"
        printf "Press Enter to continue..."; read -r input
        return
    fi

    sync_editor

    while true; do
        display_banner

        printf "Choose your default editor:\n\n"
        printf "Current editor: ${RED}$EDITOR${NC}\n\n"

        i=1
        for editor in $available_editors; do
            echo "$i) $editor"
            i=$((i + 1))
        done
        echo "0) No change"

        options="(1-$((i - 1)))"

        printf "\nSelect an option $options: "; read -r choice
        case $choice in
            [1-9])
                i=1
                for editor in $available_editors; do
                    if [ "$i" = "$choice" ]; then
                        $SED_INPLACE "s/^EDITOR=.*/EDITOR=$editor/" "$ENV_SYSTEM_FILE"

                        printf "\nEditor is now set to: ${GREEN}$editor${NC}\n"
                        printf "\nPress Enter to continue..."; read -r input

                        sync_editor
                        break
                    fi
                    i=$((i + 1))
                done
                ;;
            0) return ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r input
                ;;
        esac
    done
}

get_editor_description() {
    case "$EDITOR" in
        nvim|vim|vi) printf "Using ${RED}$EDITOR${NC} editor, don't forget to save changes after edit.\n" ;;
        nano) printf "After editing, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes.\n" ;;
        *) break ;;
    esac
}

run_editor() {
    set_if_not_defined
    "$EDITOR" "$@"
}

sync_editor