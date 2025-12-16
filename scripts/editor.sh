#!/bin/sh

[ -n "$__EDITOR_SH" ] && return
__EDITOR_SH=1

VSCODE_MACOS_CLI=""

find_vscode_macos() {
    # Search common macOS app locations
    for app_dir in "/Applications" "$HOME/Applications"; do
        vscode_app="$app_dir/Visual Studio Code.app"
        if [ -d "$vscode_app" ]; then
            vscode_cli="$vscode_app/Contents/Resources/app/bin/code"
            [ -x "$vscode_cli" ] && echo "$vscode_cli" && return 0
        fi
    done

    # Fallback: use mdfind (Spotlight) to find VS Code anywhere
    if command -v mdfind >/dev/null 2>&1; then
        vscode_app="$(mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == 'Visual Studio Code'" 2>/dev/null | head -n 1)"
        if [ -n "$vscode_app" ]; then
            vscode_cli="$vscode_app/Contents/Resources/app/bin/code"
            [ -x "$vscode_cli" ] && echo "$vscode_cli" && return 0
        fi
    fi

    return 1
}

get_editor_display_name() {
    case "$1" in
        nvim) display_name="NeoVim" ;;
        vim) display_name="Vim" ;;
        vi) display_name="Vi" ;;
        nano) display_name="Nano" ;;
        code) display_name="VS Code" ;;
        *) display_name="$1" ;;
    esac
}

set_if_not_defined() {
    [ -z "$EDITOR" ] && EDITOR=nano
}

sync_editor() {
    while IFS='=' read -r key value; do
        case "$key" in
            EDITOR) EDITOR="$value"; break ;;
        esac
    done < "$ENV_SYSTEM_FILE"

    if [ -z "$EDITOR" ]; then
        EDITOR=nano
        printf 'EDITOR=nano\n' >> "$ENV_SYSTEM_FILE"
    fi
}

set_editor() {
    editors="nvim vim vi nano"

    available_editors=""
    for editor in $editors; do
        command -v "$editor" >/dev/null 2>&1 && available_editors="$available_editors $editor"
    done

    if command -v code >/dev/null 2>&1; then
        available_editors="$available_editors code"
    elif [ "$OS_IS_DARWIN" = "true" ]; then
        VSCODE_MACOS_CLI="$(find_vscode_macos)"
        [ -n "$VSCODE_MACOS_CLI" ] && available_editors="$available_editors code"
    fi

    if [ -z "$available_editors" ]; then
        printf "No suitable editors found. Install ${RED}nano${NC} editor first.\n\n"
        printf "Press Enter to continue..."; read -r _
        return
    fi

    sync_editor

    while :; do
        display_banner

        printf "Choose your default editor:\n\n"
        get_editor_display_name "$EDITOR"
        printf "Current editor: ${RED}$display_name${NC}\n\n"

        i=1
        for editor in $available_editors; do
            get_editor_display_name "$editor"
            echo "$i) $display_name"
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
                        EDITOR="$editor"

                        get_editor_display_name "$editor"
                        printf "\nEditor is now set to: ${GREEN}$display_name${NC}\n"
                        printf "\nPress Enter to continue..."; read -r _
                        break
                    fi
                    i=$((i + 1))
                done
                ;;
            0) return ;;
            *)
                printf "\nInvalid option. Please select a valid option $options.\n"
                printf "\nPress Enter to continue..."; read -r _
                ;;
        esac
    done
}

get_editor_description() {
    case "$EDITOR" in
        nvim|vim|vi) printf "Using ${RED}$EDITOR${NC} editor, don't forget to save changes after edit.\n" ;;
        nano) printf "After editing, press '${BLUE}CTRL + X${NC}' and press '${BLUE}Y${NC}' to save changes.\n" ;;
        code) printf "VS Code will open in a new window. Save your changes and ${BLUE}close the tab${NC} to continue.\n" ;;
        *) break ;;
    esac
}

run_editor() {
    set_if_not_defined

    case "$EDITOR" in
        code)
            if command -v code >/dev/null 2>&1; then
                code --wait "$@"
            elif [ "$OS_IS_DARWIN" = "true" ]; then
                # Detect VS Code on macOS if not already set
                [ -z "$VSCODE_MACOS_CLI" ] && VSCODE_MACOS_CLI="$(find_vscode_macos)"
                [ -n "$VSCODE_MACOS_CLI" ] && "$VSCODE_MACOS_CLI" --wait "$@"
            fi
            ;;
        *)
            "$EDITOR" "$@"
            ;;
    esac
}

sync_editor