#!/bin/sh

[ -n "$__CORE_COMMON_CACHED" ] && return
__CORE_COMMON_CACHED=1

clear_screen() { printf '\033[2J\033[H'; }

CORE_upsert_env() {
    _key="$1" _val="$2" _file="$3"
    if [ ! -f "$_file" ]; then
        printf '%s=%s\n' "$_key" "$_val" >> "$_file"
        return
    fi
    grep -qxF "${_key}=${_val}" "$_file" 2>/dev/null && return
    if grep -q "^${_key}=" "$_file" 2>/dev/null; then
        CORE_env_set "$_file" "$_key" "$_val"
    else
        printf '%s=%s\n' "$_key" "$_val" >> "$_file"
    fi
}

CORE_read_env() {
    _key="$1" _file="$2"
    [ -f "$_file" ] && grep "^${_key}=" "$_file" 2>/dev/null | cut -d '=' -f2
}

CORE_require_unlocked_vault() {
    "$@" && return 0
    printf '%s\n' "igm: credentials could not be unlocked — stopping before anything is overwritten." >&2
    printf '%s\n' "     See ~/.igm/.env.key and the recovery notes." >&2
    return 1
}

CORE_reorder_config_file() {
    [ -s "$ENV_FILE" ] || return 0

    if [ -z "$ordered_app_metadata" ]; then
        ordered_app_metadata=$(jq -r 'to_entries | map({
            name: .value.name,
            props: (.value.properties // [] | map(ltrimstr("#")) | join(",")),
            order: .key
        }) | .[] | "\(.name)|\(.props)|\(.order)"' "$JSON_FILE")
    fi

    expected_order=$(printf '%s\n' "$ordered_app_metadata" | awk -F'|' '{apps = apps (apps ? "," : "") $1} END {print apps}')

    awk -F'=' -v expected="$expected_order" '
    /^[A-Z0-9_]+=/ {
        split($1, parts, "_")
        if (parts[1] != prev && parts[1] != "") {
            apps = apps (apps ? "," : "") parts[1]
            prev = parts[1]
        }
    }
    END { exit (apps == expected ? 0 : 1) }
    ' "$ENV_FILE" && return 0

    TEMP_ENV=".igm_config_reorg_$$"
    trap 'rm -f "$TEMP_ENV"; exit' INT TERM EXIT

    printf '%s\n' "$ordered_app_metadata" | awk -F'|' -v envfile="$ENV_FILE" '
        {
            app = $1
            split($2, prop_arr, ",")
            app_props[app] = $2
            app_order[app] = $3

            for (i in prop_arr) {
                if (prop_arr[i] != "") {
                    prop_to_app[prop_arr[i]] = app
                }
            }
        }

        END {
            while ((getline line < envfile) > 0) {
                if (line ~ /^[A-Z0-9_]+=/) {
                    idx = index(line, "=")
                    key = substr(line, 1, idx - 1)
                    value = substr(line, idx + 1)

                    if (key in prop_to_app) {
                        app = prop_to_app[key]
                    } else {
                        split(key, parts, "_")
                        app = parts[1]
                    }

                    app_creds[app] = (app in app_creds) ? app_creds[app] "\n" key "=" value : key "=" value
                    app_has_creds[app] = 1
                } else if (line !~ /^[[:space:]]*$/) {
                    extras = extras (extras ? "\n" : "") line
                }
            }
            close(envfile)

            max_order = 0
            for (app in app_order) {
                ordered[app_order[app]] = app
                max_order = (app_order[app] > max_order) ? app_order[app] : max_order
            }

            first_app = 1
            for (i = 0; i <= max_order; i++) {
                if (!(i in ordered)) continue
                app = ordered[i]

                if (!(app in app_has_creds) || app_props[app] == "") continue

                if (!first_app) print ""
                first_app = 0

                n_props = split(app_props[app], props, ",")
                n_creds = split(app_creds[app], creds, "\n")

                delete cred_map
                for (j = 1; j <= n_creds; j++) {
                    idx = index(creds[j], "=")
                    cred_key = substr(creds[j], 1, idx - 1)
                    cred_val = substr(creds[j], idx + 1)
                    cred_map[cred_key] = cred_val
                }

                for (j = 1; j <= n_props; j++) {
                    if (props[j] in cred_map)
                        print props[j] "=" cred_map[props[j]]
                }

                delete app_has_creds[app]
            }

            for (app in app_has_creds) {
                if (!first_app) print ""
                first_app = 0
                print app_creds[app]
            }

            if (extras != "") {
                if (!first_app) print ""
                print extras
            }
        }
    ' > "$TEMP_ENV" || { rm -f "$TEMP_ENV"; return 1; }
    [ -s "$TEMP_ENV" ] || { rm -f "$TEMP_ENV"; return 1; }

    chmod 600 "$TEMP_ENV" 2>/dev/null || { rm -f "$TEMP_ENV"; return 1; }
    mv "$TEMP_ENV" "$ENV_FILE"
    rm -f "$TEMP_ENV"
}

CORE_env_set() {
    _file="$1" _key="$2" _val="$3"
    [ -f "$_file" ] || return 1
    _tmp="$_file.tmp.$$"
    { printf '%s\n' "$_val"; cat "$_file" 2>/dev/null; } | awk -v entry="$_key" -F "=" '
        NR == 1 { input = $0; next }
        $1 == entry { print entry "=" input; next }
        { print }
    ' >"$_tmp" || { rm -f "$_tmp"; return 1; }
    [ -s "$_tmp" ] || { rm -f "$_tmp"; return 1; }
    chmod 600 "$_tmp" 2>/dev/null || { rm -f "$_tmp"; return 1; }
    mv "$_tmp" "$_file"
}

CORE_env_append() {
    printf '%s=%s\n' "$2" "$3" >> "$1"
}

CORE_write_json() {
    _file="$1"; shift
    _tmp="$_file.tmp.$$"
    jq --indent 4 "$@" "$_file" >"$_tmp" 2>/dev/null \
        || { rm -f "$_tmp"; return 1; }
    [ -s "$_tmp" ] || { rm -f "$_tmp"; return 1; }
    jq empty "$_tmp" >/dev/null 2>&1 || { rm -f "$_tmp"; return 1; }
    mv "$_tmp" "$_file"
}
