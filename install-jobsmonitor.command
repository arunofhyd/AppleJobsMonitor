#!/bin/bash
# =============================================================================
#  Jobs Monitor — Builder & Installer
#  Built by Arun Thomas · https://github.com/arunofhyd/JobsMonitor
#
#  This builds Jobs Monitor LOCALLY on your Mac and installs it to your
#  Applications folder. Because it's built on your own machine, macOS trusts
#  it natively — zero telemetry, zero "unidentified developer" warnings.
# =============================================================================

APP_NAME="JobsMonitor"
PLIST_LABEL="com.aoh.jobsmonitor"
REPO_RAW="https://raw.githubusercontent.com/arunofhyd/JobsMonitor/main"

# ---- Apple Monochrome (White & Black) terminal styling -------------------
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
WHITE='\033[38;5;255m'; GREY='\033[38;5;245m'; DARK_GREY='\033[38;5;239m'
YELLOW='\033[38;5;220m'; RED='\033[38;5;196m'

line() { printf "${DARK_GREY}────────────────────────────────────────────────────────────────────────────${NC}\n"; }
step() { printf "${WHITE}${BOLD}▸${NC} ${BOLD}%s${NC}\n" "$1"; }
ok()   { printf "  ${WHITE}${BOLD}✓${NC} %s\n" "$1"; }
warn() { printf "  ${YELLOW}!${NC} %s\n" "$1"; }
fail() { printf "  ${RED}✗ %s${NC}\n" "$1"; }

clear
printf "\n"
printf "${WHITE}${BOLD}    Jobs Monitor${NC}\n"
printf "${GREY}   Native macOS Menu Bar App for Apple Job Openings${NC}\n"
printf "${GREY}   Built by Arun Thomas${NC}\n\n"
line
printf "\n"

# ---- Step 1: Command Line Tools (compiler) -------------------------------
step "Checking for build tools…"
if ! xcode-select -p >/dev/null 2>&1; then
    warn "Apple's Command Line Tools are needed to build the app."
    printf "  ${GREY}A small official Apple installer will pop up. Please click ${BOLD}Install${NC}${GREY} and wait for it to finish.${NC}\n\n"
    xcode-select --install >/dev/null 2>&1
    printf "  ${YELLOW}When the installation is COMPLETE, press [Enter] here to continue…${NC}"
    read -r
    while ! xcode-select -p >/dev/null 2>&1; do
        printf "  ${GREY}Waiting for Command Line Tools installation to finish…${NC}\n"
        sleep 5
    done
fi

# ---- Workaround for CLT "redefinition of module 'SwiftBridging'" bug ------
_CLT_SWIFT="/Library/Developer/CommandLineTools/usr/include/swift"
_CLT_MODMAP="$_CLT_SWIFT/module.modulemap"
_CLT_BRIDGE="$_CLT_SWIFT/bridging.modulemap"

_NEED_BRIDGING_FIX=false
if [ -f "$_CLT_MODMAP" ] && [ -f "$_CLT_BRIDGE" ] &&    grep -q "module SwiftBridging" "$_CLT_MODMAP" 2>/dev/null &&    grep -q "module SwiftBridging" "$_CLT_BRIDGE" 2>/dev/null; then
    _NEED_BRIDGING_FIX=true
fi

if [ "$_NEED_BRIDGING_FIX" = true ]; then
    warn "Known compiler bug detected (SwiftBridging module conflict)."

    _XCODE_DEV=""
    for _candidate in         "/Applications/Xcode.app/Contents/Developer"         "/Applications/Xcode-beta.app/Contents/Developer"         "/Applications/Xcode_*.app/Contents/Developer"; do
        for _path in $_candidate; do
            if [ -d "${_path}/Toolchains/XcodeDefault.xctoolchain" ]; then
                _XCODE_DEV="${_path}"
                break 2
            fi
        done
    done

    if [ -n "$_XCODE_DEV" ]; then
        printf "  ${GREY}Using Xcode toolchain at ${_XCODE_DEV}${NC}\n"
        export DEVELOPER_DIR="${_XCODE_DEV}"
    else
        printf "  ${GREY}No Xcode installation found. Attempting one-time compiler repair…${NC}\n"
        printf "  ${YELLOW}Your admin password may be required:${NC}\n"

        _PATCHED="/tmp/module.modulemap.patched"
        python3 -c "
import re, sys
try:
    with open('$_CLT_MODMAP', 'r') as f:
        content = f.read()
    patched = re.sub(r'module\s+SwiftBridging\s*\{[^}]*\}', '', content)
    with open('$_PATCHED', 'w') as f:
        f.write(patched)
    sys.exit(0)
except Exception as e:
    sys.exit(1)
" 2>/dev/null

        if [ -f "$_PATCHED" ]; then
            if sudo cp "$_CLT_MODMAP" "${_CLT_MODMAP}.bak" 2>/dev/null &&                sudo cp "$_PATCHED"    "$_CLT_MODMAP"        2>/dev/null; then
                ok "Compiler repaired (removed duplicate SwiftBridging from module.modulemap)."
            else
                fail "Could not auto-repair (sudo required). Please run this manually, then re-run this installer:"
                printf "\n"
                printf "  ${BOLD}  sudo cp '$_CLT_MODMAP' '${_CLT_MODMAP}.bak'${NC}\n"
                printf "  ${BOLD}  sudo cp '$_PATCHED' '$_CLT_MODMAP'${NC}\n\n"
                printf "  ${GREY}Or reinstall Command Line Tools cleanly:${NC}\n"
                printf "  ${BOLD}  sudo rm -rf /Library/Developer/CommandLineTools${NC}\n"
                printf "  ${BOLD}  xcode-select --install${NC}\n\n"
                exit 1
            fi
        else
            fail "Could not prepare patch. Please reinstall Command Line Tools:"
            printf "  ${BOLD}  sudo rm -rf /Library/Developer/CommandLineTools${NC}\n"
            printf "  ${BOLD}  xcode-select --install${NC}\n\n"
            exit 1
        fi
    fi
fi

ok "Build tools ready."
printf "\n"

# ---- Step 2: Workspace ----------------------------------------------------
step "Preparing a clean workspace…"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    cp main.swift "$BUILD_DIR/main.swift"
    cp logo-jobsmonitor.png "$BUILD_DIR/logo-jobsmonitor.png" 2>/dev/null || true
else
    curl -sSL "$REPO_RAW/main.swift" -o "$BUILD_DIR/main.swift"
    curl -sSL "$REPO_RAW/logo-jobsmonitor.png" -o "$BUILD_DIR/logo-jobsmonitor.png"
fi

APP_VERSION=$(grep -m1 'let APP_VERSION =' "$BUILD_DIR/main.swift" | cut -d'"' -f2)
if [ -z "$APP_VERSION" ]; then APP_VERSION="2.1.3"; fi

ok "Workspace ready. Version: $APP_VERSION"
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
    BUILD_APP="$BUILD_DIR_LOCAL/$APP_NAME.app"
else
    BUILD_APP="$BUILD_DIR/$APP_NAME.app"
    pkill -x "$APP_NAME" 2>/dev/null
fi
rm -rf "$BUILD_APP"

CONTENTS_DIR="$BUILD_APP/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod 755 "$MACOS_DIR/$APP_NAME"

PNG_SOURCE="$BUILD_DIR/logo-jobsmonitor.png"
if [ -f "$PNG_SOURCE" ]; then
    ICONSET="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"
    sips -s format png -z 16 16 "$PNG_SOURCE" --out "$ICONSET/icon_16x16.png" &>/dev/null
    sips -s format png -z 32 32 "$PNG_SOURCE" --out "$ICONSET/icon_16x16@2x.png" &>/dev/null
    sips -s format png -z 32 32 "$PNG_SOURCE" --out "$ICONSET/icon_32x32.png" &>/dev/null
    sips -s format png -z 64 64 "$PNG_SOURCE" --out "$ICONSET/icon_32x32@2x.png" &>/dev/null
    sips -s format png -z 128 128 "$PNG_SOURCE" --out "$ICONSET/icon_128x128.png" &>/dev/null
    sips -s format png -z 256 256 "$PNG_SOURCE" --out "$ICONSET/icon_128x128@2x.png" &>/dev/null
    sips -s format png -z 256 256 "$PNG_SOURCE" --out "$ICONSET/icon_256x256.png" &>/dev/null
    sips -s format png -z 512 512 "$PNG_SOURCE" --out "$ICONSET/icon_512x512.png" &>/dev/null
    sips -s format png -z 512 512 "$PNG_SOURCE" --out "$ICONSET/icon_512x512@2x.png" &>/dev/null
    sips -s format png -z 1024 1024 "$PNG_SOURCE" --out "$ICONSET/icon_512x512@2x.png" &>/dev/null
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns" &>/dev/null
    cp "$PNG_SOURCE" "$RESOURCES_DIR/AppIcon.png"
fi

cat << EOF > "$CONTENTS_DIR/Info.plist"
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
    <string>$APP_VERSION</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
codesign --force --deep --sign - --requirements '=designated => identifier "'"$PLIST_LABEL"'"' "$BUILD_APP" >/dev/null 2>&1 || true

if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    TARGET_APP="$BUILD_APP"
    ok "App bundle created."
    printf "\n"
    line
    printf "${WHITE}${BOLD}   ✓ CI Build Complete: $TARGET_APP${NC}\n"
    line
    printf "\n"
    exit 0
else
    TARGET_APP="/Applications/$APP_NAME.app"
    if [ -w "/Applications" ] || [ -w "$TARGET_APP" ]; then
        rm -rf "$TARGET_APP" 2>/dev/null
        cp -R "$BUILD_APP" "/Applications/"
    else
        osascript -e "do shell script \"rm -rf '$TARGET_APP'; cp -R '$BUILD_APP' '/Applications/'\" with administrator privileges" >/dev/null 2>&1
    fi
    xattr -dr com.apple.quarantine "$TARGET_APP" >/dev/null 2>&1 || true
    ok "App bundle created & installed to Applications."
    printf "\n"
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
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH" 2>/dev/null
touch "$TARGET_APP"
open "$TARGET_APP" --args --open-preferences
ok "Jobs Monitor installed & running."
printf "\n"

line
printf "${WHITE}${BOLD}   ✓ Jobs Monitor is now installed and running in your menu bar.${NC}\n"
line
printf "\n"
