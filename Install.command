#!/bin/bash

#  Jobs Monitor - Installation Script
echo "=========================================="
echo "  Installing Jobs Monitor (v2.0.0)"
echo "=========================================="

APP_DIR="$HOME/Applications"
TARGET_APP="$APP_DIR/JobsMonitor.app"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p "$APP_DIR"

if [ -d "$SCRIPT_DIR/JobsMonitor.app" ]; then
    echo "📦 Copying JobsMonitor.app to $APP_DIR..."
    pkill -f AppleJobsMonitor || true
    pkill -f JobsMonitor || true
    rm -rf "$TARGET_APP"
    cp -R "$SCRIPT_DIR/JobsMonitor.app" "$APP_DIR/"
elif [ -d "$TARGET_APP" ]; then
    echo "📦 App bundle found at $TARGET_APP"
fi

# Configure Launch at Login via LaunchAgent
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENT_DIR/com.arunthomas.jobsmonitor.plist"
mkdir -p "$LAUNCH_AGENT_DIR"

# Clean up old launch agent if present
rm -f "$LAUNCH_AGENT_DIR/com.arunthomas.applejobsmonitor.plist" 2>/dev/null || true

cat << PLIST > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.arunthomas.jobsmonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TARGET_APP/Contents/MacOS/JobsMonitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
PLIST

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH" 2>/dev/null || true

echo "🚀 Launching Jobs Monitor..."
open "$TARGET_APP"

echo "=========================================="
echo "  ✅ Installation & Launch at Login Complete!"
echo "=========================================="
