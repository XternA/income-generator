#!/bin/sh

[ -n "$__APP_CREDENTIAL_VALIDATOR_CACHED" ] && return
__APP_CREDENTIAL_VALIDATOR_CACHED=1

validate_app_credentials() {
    app_name="$1"
    list_missing="${2:-}"

    # Handle service apps - check parent app credentials
    case "$app_name" in
        *_SERVICE) app_name="${app_name%_SERVICE}" ;;
    esac

    # Get required credentials from cached index
    required_creds=$(printf '%s\n' "$APP_PROPERTIES_INDEX" | awk -F= -v app="$app_name" '$1 == app {print $2; exit}')

    # No credentials required = validation passes
    [ -z "$required_creds" ] && return 0

    if [ ! -f "$ENV_FILE" ]; then
        [ "$list_missing" = "--list" ] && echo "$required_creds"
        return 1
    fi

    # Load ENV file once (not per credential)
    env_content=$(cat "$ENV_FILE" 2>/dev/null) || {
        [ "$list_missing" = "--list" ] && echo "$required_creds"
        return 1
    }

    # Check each credential and collect missing ones
    missing_creds=""
    for cred in $required_creds; do
        case "$env_content" in
            *"${cred}"=?*)
                # Found with non-empty value, continue
                ;;
            *)
                # Missing or empty
                missing_creds="$missing_creds $cred"
                ;;
        esac
    done

    # Output missing if requested
    if [ -n "$missing_creds" ]; then
        [ "$list_missing" = "--list" ] && echo "${missing_creds# }"
        return 1
    fi

    return 0 # All credentials present
}
