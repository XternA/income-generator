#!/bin/sh

set -u
umask 077

IGM_HOME="${IGM_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"

MODE=""
case "${1:-}" in
    -d|-ds) MODE=unlock ;;
    -e|-es) MODE=lock ;;
esac
[ -n "$MODE" ] || { echo "usage: encryptor.sh -d|-e [path]" >&2; exit 2; }

if [ -n "${2:-}" ]; then
    VAULT="$2"
    RUN="$2"
else
    VAULT="$IGM_HOME/.env"
    RUN="$IGM_HOME/.env.run"
fi
KEY_FILE="$VAULT.key"
LOCK_DIR="$VAULT.lock"

_crypto=""
crypto_ok() {
    [ "$_crypto" = "1" ] && return 0
    [ "$_crypto" = "0" ] && return 1
    _crypto=0
    if command -v openssl >/dev/null 2>&1; then
        _in="$IGM_HOME/.env.probe.$$"
        _out="$_in.enc"
        printf 'probe' > "$_in" 2>/dev/null || return 1
        if printf '%s' probe | openssl enc -aes-256-cbc -salt -pbkdf2 -pass stdin \
                -in "$_in" -out "$_out" 2>/dev/null \
           && printf '%s' probe | openssl enc -d -aes-256-cbc -pbkdf2 -pass stdin \
                -in "$_out" 2>/dev/null | cmp -s - "$_in"; then
            _crypto=1
        fi
        rm -f "$_in" "$_out" 2>/dev/null
    fi
    [ "$_crypto" = "1" ]
}

encrypt_to() {
    printf '%s' "$3" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass stdin \
        -in "$1" -out "$2" 2>/dev/null
}

decrypt_to() {
    printf '%s' "$3" | openssl enc -d -aes-256-cbc -pbkdf2 -pass stdin \
        -in "$1" -out "$2" 2>/dev/null
}

key_line() { sed -n "$1p" "$KEY_FILE" 2>/dev/null; }

is_openssl() {
    [ -f "$1" ] || return 1
    dd if="$1" bs=1 count=8 2>/dev/null | grep -q '^Salted__$'
}

acquire() {
    _try=0
    while [ "$_try" -lt 20 ]; do
        if mkdir "$LOCK_DIR" 2>/dev/null; then
            if ! printf '%s' "$$" > "$LOCK_DIR/pid" 2>/dev/null; then
                rm -rf "$LOCK_DIR" 2>/dev/null
                return 1
            fi
            return 0
        fi
        _p=$(sed -n '1p' "$LOCK_DIR/pid" 2>/dev/null)
        case "$_p" in
            ''|*[!0-9]*) ;;
            *) kill -0 "$_p" 2>/dev/null || { rm -rf "$LOCK_DIR" 2>/dev/null; continue; } ;;
        esac
        sleep 0.1
        _try=$((_try + 1))
    done
    return 1
}

release() {
    _p=$(sed -n '1p' "$LOCK_DIR/pid" 2>/dev/null)
    if [ "$_p" = "$$" ]; then
        rm -rf "$LOCK_DIR" 2>/dev/null
    fi
    return 0
}

gc() {
    for _f in "$IGM_HOME"/.env.tmp.* "$IGM_HOME"/.env.run.tmp.* \
              "$IGM_HOME"/.env.magic.* "$IGM_HOME"/.env.probe.* \
              "$IGM_HOME"/.env.probe.*.enc "$IGM_HOME"/.env.key.tmp.*; do
        [ -e "$_f" ] || continue
        _p=${_f##*.}
        case "$_p" in
            ''|*[!0-9]*) rm -f "$_f" 2>/dev/null ;;
            *) kill -0 "$_p" 2>/dev/null || rm -f "$_f" 2>/dev/null ;;
        esac
    done
    if [ -d "$LOCK_DIR" ]; then
        _p=$(sed -n '1p' "$LOCK_DIR/pid" 2>/dev/null)
        case "$_p" in
            ''|*[!0-9]*) rm -rf "$LOCK_DIR" 2>/dev/null ;;
            *) kill -0 "$_p" 2>/dev/null || rm -rf "$LOCK_DIR" 2>/dev/null ;;
        esac
    fi
    return 0
}

unlock() {
    if [ "$RUN" != "$VAULT" ] && [ -e "$RUN" ] && [ -s "$RUN" ]; then
        return 0
    fi

    [ -e "$VAULT" ] || { : > "$RUN" 2>/dev/null; return 0; }

    if ! is_openssl "$VAULT"; then
        [ "$RUN" = "$VAULT" ] && return 0
        mv "$VAULT" "$RUN" 2>/dev/null
        return 0
    fi

    crypto_ok || return 1

    _tmp="$VAULT.tmp.$$"
    for _k in "$(key_line 1)" "$(key_line 2)"; do
        [ -n "$_k" ] || continue
        if decrypt_to "$VAULT" "$_tmp" "$_k" && [ -s "$_tmp" ]; then
            chmod 600 "$_tmp" 2>/dev/null
            mv "$_tmp" "$RUN"
            return 0
        fi
    done
    rm -f "$_tmp" 2>/dev/null
    echo "igm: credential vault could not be decrypted — key missing or mismatched ($KEY_FILE)" >&2
    return 1
}

lock() {
    [ -e "$RUN" ] || return 0
    [ -s "$RUN" ] || { rm -f "$RUN" 2>/dev/null; return 0; }

    if ! crypto_ok; then
        if [ "$RUN" != "$VAULT" ]; then
            _tmp="$VAULT.tmp.$$"
            mv "$RUN" "$_tmp" && mv "$_tmp" "$VAULT"
        fi
        return 0
    fi

    if ! acquire; then
        echo "igm: credential vault locked by another process — not re-encrypted" >&2
        return 1
    fi

    _newkey=$(openssl rand -base64 32 2>/dev/null)
    case "$_newkey" in
        ''|*[!A-Za-z0-9+/=]*) release; return 1 ;;
    esac

    _tmp="$VAULT.tmp.$$"
    if ! encrypt_to "$RUN" "$_tmp" "$_newkey"; then
        rm -f "$_tmp" 2>/dev/null
        release
        return 1
    fi

    _keytmp="$KEY_FILE.tmp.$$"
    if ! printf '%s\n' "$_newkey" "$(key_line 1)" > "$_keytmp" 2>/dev/null \
        || ! chmod 600 "$_keytmp" 2>/dev/null \
        || ! mv "$_keytmp" "$KEY_FILE" 2>/dev/null; then
        rm -f "$_keytmp" "$_tmp" 2>/dev/null
        echo "igm: could not persist the vault key — vault left unchanged" >&2
        release
        return 1
    fi
    mv "$_tmp" "$VAULT"
    [ "$RUN" = "$VAULT" ] || rm -f "$RUN" 2>/dev/null

    release
    return 0
}

gc

rc=0
case "$MODE" in
    unlock) unlock || rc=$? ;;
    lock)   lock   || rc=$? ;;
esac

gc
exit $rc
