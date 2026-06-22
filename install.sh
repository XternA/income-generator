#!/bin/sh
# IGM — Income Generator Installer

set -e

REPO="XternA/income-generator"
REPO_URL="https://github.com/${REPO}.git"
BIN_NAME="igm"
IGM_HOME="${HOME}/.igm"
RELEASES_LATEST="https://api.github.com/repos/${REPO}/releases/latest"
RELEASES_API="https://api.github.com/repos/${REPO}/releases"
RELEASES_BASE="https://github.com/${REPO}/releases/download"

if [ -t 1 ]; then
    RED='\033[0;31m' GREEN='\033[0;32m' CYAN='\033[0;36m' BOLD='\033[1m' NC='\033[0m'
else
    RED='' GREEN='' CYAN='' BOLD='' NC=''
fi

info()  { printf "${CYAN}==>${NC} ${BOLD}%s${NC}\n" "$*"; }
ok()    { printf "${GREEN}  ✓${NC} %s\n" "$*"; }
fail()  { printf "${RED}  ✗ Error:${NC} %s\n" "$*" >&2; exit 1; }

check_dependencies() {
    if ! command -v git >/dev/null 2>&1; then
        printf "${RED}  ✗ Error:${NC} git is not installed.\n" >&2
        printf "  Install git and re-run this script.\n" >&2
        printf "  See: https://git-scm.com/downloads\n" >&2
        exit 1
    fi
}

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    case "$OS" in
        Linux)
            case "$ARCH" in
                x86_64)          PLATFORM="linux-amd64"  ;;
                aarch64 | arm64) PLATFORM="linux-arm64"  ;;
                armv7l | armv6l | armhf) PLATFORM="linux-arm32" ;;
                *)               fail "Unsupported Linux architecture: $ARCH" ;;
            esac
            ;;
        Darwin)
            case "$ARCH" in
                arm64)   PLATFORM="darwin-arm64" ;;
                x86_64)  PLATFORM="darwin-amd64" ;;
                *)       fail "Unsupported macOS architecture: $ARCH" ;;
            esac
            ;;
        *)
            fail "Unsupported OS: $OS. Windows users: install via WSL2 and re-run."
            ;;
    esac
}

download() {
    URL="$1"; DEST="$2"
    curl -fsSL --retry 3 --retry-delay 2 -o "$DEST" "$URL" || fail "Download failed: $URL"
}

try_download() {
    URL="$1"; DEST="$2"
    curl -fsSL --retry 2 --retry-delay 1 -o "$DEST" "$URL" 2>/dev/null
}

resolve_binary_release() {
    BINARY_NAME="${BIN_NAME}-${PLATFORM}"
    TMP_JSON="$(mktemp)"
    RELEASE_TAG=""

    # Try latest full release first — pre-releases are excluded
    if try_download "$RELEASES_LATEST" "$TMP_JSON"; then
        _tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TMP_JSON" | head -1)"
        if [ -n "$_tag" ] && grep -q "$BINARY_NAME" "$TMP_JSON"; then
            RELEASE_TAG="$_tag"
        fi
    fi

    # Fall back to scanning all releases if latest has no binary attached
    if [ -z "$RELEASE_TAG" ]; then
        download "$RELEASES_API" "$TMP_JSON"
        _tag=""
        _skip=0
        while IFS= read -r line; do
            case "$line" in
                *'"tag_name"'*)
                    _tag="$(printf '%s' "$line" | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
                    _skip=0
                    ;;
                *'"prerelease": true'*)
                    _skip=1
                    ;;
                *"$BINARY_NAME"*)
                    if [ -n "$_tag" ] && [ -z "$RELEASE_TAG" ] && [ "$_skip" = "0" ]; then
                        RELEASE_TAG="$_tag"
                    fi
                    ;;
            esac
        done < "$TMP_JSON"
    fi

    rm -f "$TMP_JSON"
    [ -n "$RELEASE_TAG" ] || fail "No binary release found for platform: $PLATFORM"
    ok "Latest binary release: $RELEASE_TAG"
}

verify_checksum() {
    BINARY="$1"; SUMS_FILE="$2"; FILENAME="$(basename "$BINARY")"
    EXPECTED="$(grep "[[:space:]]${FILENAME}$" "$SUMS_FILE" | awk '{print $1}')"
    [ -n "$EXPECTED" ] || fail "Checksum not found for ${FILENAME}."

    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL="$(sha256sum "$BINARY" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
        ACTUAL="$(shasum -a 256 "$BINARY" | awk '{print $1}')"
    else
        fail "Cannot verify checksum: sha256sum / shasum not found."
    fi

    [ "$ACTUAL" = "$EXPECTED" ] || fail "Checksum mismatch — binary may be corrupt. Aborting."
}

resolve_install_dir() {
    if [ -n "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" || fail "Cannot create install directory: $INSTALL_DIR"
        return
    fi
    LOCAL_BIN="${HOME}/.local/bin"
    if mkdir -p "$LOCAL_BIN" 2>/dev/null; then
        INSTALL_DIR="$LOCAL_BIN"
        return
    fi
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        INSTALL_DIR="/usr/local/bin"
        return
    fi
    fail "Cannot determine install directory. Set INSTALL_DIR=/path/to/bin before running."
}


dedup_path_entries() {
    for _profile in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile"; do
        [ -f "$_profile" ] || continue
        _count=$(grep -c "${INSTALL_DIR}" "$_profile" 2>/dev/null || echo 0)
        [ "$_count" -le 1 ] && continue
        _tmp="${_profile}.igm.$$"
        awk -v dir="${INSTALL_DIR}" 'index($0,dir){if(!seen++)print;next}1' "$_profile" > "$_tmp" && mv "$_tmp" "$_profile"
    done
}
ensure_in_path() {
    case ":$PATH:" in
        *":${INSTALL_DIR}:"*) return ;;
    esac
    case "${SHELL:-}" in
        */fish)
            SHELL_PROFILE="${HOME}/.config/fish/config.fish"
            grep -qF ".local/bin" "$SHELL_PROFILE" 2>/dev/null && return
            printf '\nfish_add_path "%s"\n' "$INSTALL_DIR" >> "$SHELL_PROFILE"
            ;;
        */zsh)
            SHELL_PROFILE="${HOME}/.zshrc"
            grep -qF ".local/bin" "$SHELL_PROFILE" 2>/dev/null && return
            printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_PROFILE"
            ;;
        *)
            SHELL_PROFILE="${HOME}/.bashrc"
            grep -qF ".local/bin" "$SHELL_PROFILE" 2>/dev/null && return
            printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_PROFILE"
            ;;
    esac
    ok "Added ${INSTALL_DIR} to PATH in ${SHELL_PROFILE}"
    printf "  ${BOLD}Run:${NC} source %s\n" "$SHELL_PROFILE"
}

setup_repo() {
    if [ -d "${IGM_HOME}/.git" ]; then
        info "Checking for updates..."
        git -C "$IGM_HOME" fetch --depth 1 origin main --quiet || true
        git -C "$IGM_HOME" reset --hard origin/main --quiet || true
        ok "Up to date"
    elif [ -d "$IGM_HOME" ]; then
        info "Setting up..."
        git -C "$IGM_HOME" init --quiet || fail "Setup failed."
        git -C "$IGM_HOME" remote add origin "$REPO_URL" || fail "Setup failed."
        git -C "$IGM_HOME" fetch --depth 1 origin main --quiet || fail "Setup failed."
        git -C "$IGM_HOME" checkout -b main FETCH_HEAD --quiet || fail "Setup failed."
        git -C "$IGM_HOME" branch --set-upstream-to=origin/main main --quiet || true
        ok "Done"
    else
        info "Setting up..."
        git clone --depth 1 "$REPO_URL" "$IGM_HOME" --quiet || fail "Setup failed."
        ok "Done"
    fi
}

strip_legacy_alias() {
    ALIAS_FOUND=0
    for _profile in \
        "${HOME}/.bashrc" \
        "${HOME}/.zshrc" \
        "${HOME}/.profile" \
        "${HOME}/.bash_aliases" \
        "${HOME}/.config/fish/config.fish"
    do
        [ -f "$_profile" ] || continue
        if grep -q "alias igm=.*start\.sh" "$_profile" 2>/dev/null; then
            _tmp="${_profile}.igm.$$"
            sed '/alias igm=.*start\.sh/d' "$_profile" > "$_tmp" && mv "$_tmp" "$_profile"
            ALIAS_FOUND=1
        fi
    done
}

main() {
    printf "\n${BOLD}IGM — Income Generator Installer${NC}\n\n"

    check_dependencies
    detect_platform
    ok "Platform: $PLATFORM"

    setup_repo

    info "Finding latest binary release..."
    resolve_binary_release

    resolve_install_dir
    ok "Install path: ${INSTALL_DIR}/${BIN_NAME}"

    BINARY_URL="${RELEASES_BASE}/${RELEASE_TAG}/${BINARY_NAME}"
    SUMS_URL="${RELEASES_BASE}/${RELEASE_TAG}/SHA256SUMS"

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    info "Downloading ${BINARY_NAME} (${RELEASE_TAG})..."
    download "$BINARY_URL" "${TMP_DIR}/${BINARY_NAME}"
    ok "Downloaded"

    info "Verifying checksum..."
    download "$SUMS_URL" "${TMP_DIR}/SHA256SUMS"
    verify_checksum "${TMP_DIR}/${BINARY_NAME}" "${TMP_DIR}/SHA256SUMS"
    ok "Checksum verified"

    info "Installing to ${INSTALL_DIR}/${BIN_NAME}..."
    if [ -w "$INSTALL_DIR" ]; then
        rm -f "${INSTALL_DIR}/${BIN_NAME}"
        cp "${TMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BIN_NAME}"
        chmod +x "${INSTALL_DIR}/${BIN_NAME}"
    else
        sudo rm -f "${INSTALL_DIR}/${BIN_NAME}"
        sudo cp "${TMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BIN_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${BIN_NAME}"
    fi

    if [ "$OS" = "Darwin" ]; then
        xattr -c "${INSTALL_DIR}/${BIN_NAME}" 2>/dev/null || true
        codesign --force --sign - "${INSTALL_DIR}/${BIN_NAME}" 2>/dev/null || true
    fi

    ok "Installed ${BIN_NAME} ${RELEASE_TAG}"

    dedup_path_entries
    ensure_in_path
    strip_legacy_alias

    if "${INSTALL_DIR}/${BIN_NAME}" version >/dev/null 2>&1; then
        ok "Verified: $(${INSTALL_DIR}/${BIN_NAME} version)"
    fi

    if [ "$ALIAS_FOUND" = "1" ]; then
        printf "\nExisting IGM alias detected. To run the new IGM, unregister the alias:\n"
        printf "\n  ${BOLD}unalias igm; hash -r${NC}\n"
        printf "\nOr open a new terminal.\n"
    fi

    printf "\n${GREEN}${BOLD}Done.${NC}\n\n"
    printf "Run ${BOLD}\"igm\"${NC} to start Income Generator tool.\n\n"
}

main "$@"
