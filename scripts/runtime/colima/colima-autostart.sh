#!/bin/sh

PLIST_DIR="$HOME/Library/LaunchAgents"
AUTOSTART_PLIST="$PLIST_DIR/com.igm.colima.autostart.plist"
SETENV_PLIST="$PLIST_DIR/com.igm.colima.setenv.plist"

install_startup_item() {
    BREW_PATH="$1"
    COLIMA_BIN="$BREW_PATH/colima"

    [ ! -f "$COLIMA_BIN" ] && exit 1

    mkdir -p "$PLIST_DIR"

    cat <<EOF > "$AUTOSTART_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.igm.colima.autostart</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>$COLIMA_BIN start; SOCK=\$HOME/.colima/default/docker.sock; r=0; while [ \$r -lt 2 ]; do i=0; while [ \$i -lt 20 ]; do [ -S "\$SOCK" ] &amp;&amp; $COLIMA_BIN status >/dev/null 2>&amp;1 &amp;&amp; exit 0; sleep 3; i=\$((i+1)); done; r=\$((r+1)); [ \$r -lt 2 ] &amp;&amp; $COLIMA_BIN start; done</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>$BREW_PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

    launchctl unload "$AUTOSTART_PLIST" >/dev/null 2>&1
    launchctl load "$AUTOSTART_PLIST"

    printf "\nColima autostart item created and loaded:\n"
    echo "${YELLOW}$AUTOSTART_PLIST${NC}"
    run_setenv
}

run_setenv() {
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
    if [ -f "$AUTOSTART_PLIST" ]; then
        launchctl unload "$AUTOSTART_PLIST" >/dev/null 2>&1
        rm -f "$AUTOSTART_PLIST"
        printf "\nColima autostart item unloaded and removed.\n"
    fi

    if [ -f "$SETENV_PLIST" ]; then
        launchctl unload "$SETENV_PLIST" >/dev/null 2>&1
        rm -f "$SETENV_PLIST"
        printf "Colima setenv item unloaded and removed.\n"
    fi
}

case "$1" in
    --install) install_startup_item $2 ;;
    --remove) remove_startup_item $2 ;;
esac