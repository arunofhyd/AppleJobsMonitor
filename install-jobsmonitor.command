#!/bin/bash
# =============================================================================
#  Jobs Monitor — Builder & Installer
#  Built by Arun Thomas · https://github.com/arunofhyd/JobsMonitor
#
#  This fetches the latest source code from GitHub and compiles Jobs Monitor
#  LOCALLY on your Mac into your Applications folder.
#  100% Native, 100% Private, zero telemetry.
# =============================================================================

APP_NAME="JobsMonitor"
PLIST_LABEL="com.aoh.jobsmonitor"
MAIN_SWIFT_URL="https://raw.githubusercontent.com/arunofhyd/JobsMonitor/main/main.swift"
LOGO_PNG_URL="https://raw.githubusercontent.com/arunofhyd/JobsMonitor/main/logo-jobsmonitor.png"

# Terminal Colors & Formatting
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

step() { printf "  ${BLUE}➔${NC} %s\n" "$1"; }
ok()   { printf "  ${GREEN}✔${NC} %s\n" "$1"; }
fail() { printf "  ${RED}✖${NC} %s\n" "$1"; }
line() { printf "${GREY}─────────────────────────────────────────────────────────────${NC}\n"; }

clear 2>/dev/null || true
printf "\n"
line
printf "${WHITE}${BOLD}    Jobs Monitor Installer${NC}\n"
line
printf "\n"

# ---- Step 1: Pre-flight Checks --------------------------------------------
step "Checking system prerequisites…"
if ! command -v swiftc >/dev/null 2>&1; then
    fail "Swift compiler (swiftc) not found."
    printf "\n  ${GREY}Please install Xcode Command Line Tools by running:${NC}\n"
    printf "    ${BOLD}xcode-select --install${NC}\n\n"
    exit 1
fi
ok "Prerequisites verified."
printf "\n"

# ---- Step 2: Workspace & Fetch Source --------------------------------------
step "Preparing temporary build workspace…"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

step "Fetching latest source code from GitHub…"
if ! curl -sSL "$MAIN_SWIFT_URL" -o "$BUILD_DIR/main.swift"; then
    fail "Could not fetch main.swift from GitHub. Please check your internet connection."
    exit 1
fi

curl -sSL "$LOGO_PNG_URL" -o "$BUILD_DIR/logo-jobsmonitor.png" 2>/dev/null || true
ok "Latest source code fetched successfully."
printf "\n"

# ---- Step 3: Compiling the app -------------------------------------------
step "Compiling Jobs Monitor…"
COMPILE_ERR="$(mktemp)"
if ! swiftc -O "$BUILD_DIR/main.swift" -o "$BUILD_DIR/$APP_NAME" -framework AppKit -framework ServiceManagement -framework UserNotifications -framework SwiftUI -framework Foundation 2>"$COMPILE_ERR"; then
    fail "Could not compile the application."
    if [ -s "$COMPILE_ERR" ]; then
        printf "  ${GREY}Compiler Error:${NC}\n"
        cat "$COMPILE_ERR" | sed 's/^/    /'
    fi
    rm -f "$COMPILE_ERR"
    printf "\n  ${GREY}Please verify Xcode Command Line Tools are active (run 'xcode-select --install' or 'sudo xcode-select -reset').${NC}\n\n"
    exit 1
fi
rm -f "$COMPILE_ERR"
ok "App compiled successfully."
printf "\n"

# ---- Step 4: Building app bundle & app icon -------------------------------
step "Building app bundle & app icon…"
if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BUILD_DIR_LOCAL="$SCRIPT_DIR/Build"
    mkdir -p "$BUILD_DIR_LOCAL"
    TARGET_APP="$BUILD_DIR_LOCAL/$APP_NAME.app"
else
    TARGET_APP="/Applications/$APP_NAME.app"
    pkill -x "$APP_NAME" 2>/dev/null || true
fi
rm -rf "$TARGET_APP"

mkdir -p "$TARGET_APP/Contents/MacOS"
mkdir -p "$TARGET_APP/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$TARGET_APP/Contents/MacOS/$APP_NAME"
chmod 755 "$TARGET_APP/Contents/MacOS/$APP_NAME"

if [ -f "$BUILD_DIR/logo-jobsmonitor.png" ]; then
    cp "$BUILD_DIR/logo-jobsmonitor.png" "$TARGET_APP/Contents/Resources/AppIcon.png"
fi

cat << EOF > "$TARGET_APP/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$PLIST_LABEL</string>
    <key>CFBundleName</key>
    <string>Jobs Monitor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1.5</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - --requirements '=designated => identifier "'"$PLIST_LABEL"'"' "$TARGET_APP" >/dev/null 2>&1 || true
ok "App bundle created."
printf "\n"

if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    line
    printf "${WHITE}${BOLD}   ✓ CI Build Complete: $TARGET_APP${NC}\n"
    line
    printf "\n"
    exit 0
fi

# ---- Step 5: Installing background agent & launching --------------------
step "Installing background agent & launching app…"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS_DIR"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_LABEL.plist"

cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TARGET_APP/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Reset first-launch flag so Preferences opens automatically after install
defaults delete "$PLIST_LABEL" has_launched_jobsmonitor 2>/dev/null || true
pkill -9 -x "$APP_NAME" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH" 2>/dev/null || true
touch "$TARGET_APP"
open "$TARGET_APP" --args --open-preferences
ok "Jobs Monitor installed & running."
printf "\n"

line
printf "${WHITE}${BOLD}   ✓ Jobs Monitor is now installed and running in your menu bar.${NC}\n"
line
printf "\n"
