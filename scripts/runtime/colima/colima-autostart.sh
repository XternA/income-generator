#!/bin/sh

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.igm.colima.autostart.plist"

install_startup_item() {
    local BREW_PATH="$1"
    local COLIMA_BIN="$BREW_PATH/colima"

    [ ! -f "$COLIMA_BIN" ] && exit 1

    mkdir -p "$PLIST_DIR"

    # Write plist file
    cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.igm.colima.autostart</string>
    <key>ProgramArguments</key>
    <array>
        <string>$COLIMA_BIN</string>
        <string>start</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>$BREW_PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    launchctl unload "$PLIST_FILE" >/dev/null 2>&1
    launchctl load "$PLIST_FILE"

    printf "\nColima autostart item created and loaded:\n"
    echo "${YELLOW}$PLIST_FILE${NC}"
    run_setenv
}

run_setenv() {
    local SETENV_PLIST="$PLIST_DIR/com.igm.colima.setenv.plist"

    cat <<EOF > "$SETENV_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.igm.colima.setenv</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/launchctl</string>
        <string>setenv</string>
        <string>DOCKER_HOST</string>
        <string>unix://$HOME/.colima/default/docker.sock</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

    launchctl unload "$SETENV_PLIST" >/dev/null 2>&1
    launchctl load "$SETENV_PLIST"
    echo "${YELLOW}$SETENV_PLIST${NC}"
}

remove_startup_item() {
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" >/dev/null 2>&1
        rm -f "$PLIST_FILE"
        printf "\nColima autostart item unloaded and removed.\n"
    fi
}

case "$1" in
    --install) install_startup_item $2 ;;
    --remove) remove_startup_item $2 ;;
esac