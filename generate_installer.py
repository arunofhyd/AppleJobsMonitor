import os
import sys
import base64
import json

script_dir = os.path.dirname(os.path.abspath(__file__))
main_swift_path = os.path.join(script_dir, "main.swift")
jobs_png_path = os.path.join(script_dir, "logo-jobsmonitor.png")
version_json_path = os.path.join(script_dir, "version.json")

if not os.path.exists(main_swift_path):
    main_swift_path = "main.swift"

if not os.path.exists(jobs_png_path):
    jobs_png_path = "logo-jobsmonitor.png"

app_version = "2.0.1"
if os.path.exists(version_json_path):
    try:
        with open(version_json_path, "r", encoding="utf-8") as f:
            vdata = json.load(f)
            app_version = vdata.get("version", "2.0.1")
    except Exception:
        pass

with open(main_swift_path, "r", encoding="utf-8") as f:
    swift_code = f.read()

swift_b64 = base64.b64encode(swift_code.encode("utf-8")).decode("utf-8")

jobs_png_b64 = ""
if os.path.exists(jobs_png_path):
    with open(jobs_png_path, "rb") as f:
        jobs_png_b64 = base64.b64encode(f.read()).decode("utf-8")

command_content = f"""#!/bin/bash
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

SWIFT_B64="{swift_b64}"
JOBS_PNG_B64="{jobs_png_b64}"

# ---- Apple Monochrome (White & Black) terminal styling -------------------
BOLD='\\033[1m'; DIM='\\033[2m'; NC='\\033[0m'
WHITE='\\033[38;5;255m'; GREY='\\033[38;5;245m'; DARK_GREY='\\033[38;5;239m'
YELLOW='\\033[38;5;220m'; RED='\\033[38;5;196m'

line() {{ printf "${{DARK_GREY}}────────────────────────────────────────────────────────────────────────────${{NC}}\\n"; }}
step() {{ printf "${{WHITE}}${{BOLD}}▸${{NC}} ${{BOLD}}%s${{NC}}\\n" "$1"; }}
ok()   {{ printf "  ${{WHITE}}${{BOLD}}✓${{NC}} %s\\n" "$1"; }}
warn() {{ printf "  ${{YELLOW}}!${{NC}} %s\\n" "$1"; }}
fail() {{ printf "  ${{RED}}✗ %s${{NC}}\\n" "$1"; }}

clear
printf "\\n"
printf "${{WHITE}}${{BOLD}}    Jobs Monitor${{NC}}\\n"
printf "${{GREY}}   Native macOS Menu Bar App for Apple Job Openings${{NC}}\\n"
printf "${{GREY}}   Built by Arun Thomas${{NC}}\\n\\n"
line
printf "\\n"

# ---- Step 1: Command Line Tools (compiler) -------------------------------
step "Checking for build tools…"
if ! command -v swiftc &> /dev/null; then
    warn "Apple's Command Line Tools are needed to build the app."
    printf "  ${{GREY}}A small official Apple installer will pop up. Please click ${{BOLD}}Install${{NC}}${{GREY}} and wait for it to finish.${{NC}}\\n\\n"
    xcode-select --install >/dev/null 2>&1
    printf "  ${{YELLOW}}When the installation is COMPLETE, press [Enter] here to continue…${{NC}}"
    read -r
    if ! command -v swiftc &> /dev/null; then
        fail "Build tools still not found."
        printf "  ${{GREY}}Please finish the Apple installer, then run this file again.${{NC}}\\n\\n"
        exit 1
    fi
fi
ok "Build tools ready."
printf "\\n"

# ---- Step 2: Workspace ----------------------------------------------------
step "Preparing a clean workspace…"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT
echo "$SWIFT_B64" | base64 -d > "$BUILD_DIR/main.swift"
if [ -n "$JOBS_PNG_B64" ]; then
    echo "$JOBS_PNG_B64" | base64 -d > "$BUILD_DIR/logo-jobsmonitor.png"
fi
ok "Workspace ready."
printf "\\n"

# ---- Step 3: Compiling the app -------------------------------------------
step "Compiling Jobs Monitor…"
if ! swiftc -O "$BUILD_DIR/main.swift" -o "$BUILD_DIR/$APP_NAME" -framework AppKit -framework ServiceManagement 2>/dev/null; then
    fail "Could not compile the application."
    printf "  ${{GREY}}Please check your system environment and try again.${{NC}}\\n\\n"
    exit 1
fi
ok "App compiled successfully."
printf "\\n"

# ---- Step 4: Building app bundle & app icon -------------------------------
step "Building app bundle & app icon…"
if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
    BUILD_DIR_LOCAL="$SCRIPT_DIR/Build"
    mkdir -p "$BUILD_DIR_LOCAL"
    TARGET_APP="$BUILD_DIR_LOCAL/$APP_NAME.app"
else
    TARGET_APP="/Applications/$APP_NAME.app"
    pkill -x "$APP_NAME" 2>/dev/null
fi
rm -rf "$TARGET_APP"

CONTENTS_DIR="$TARGET_APP/Contents"
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
    <string>{app_version}</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
ok "App bundle created."
printf "\\n"

if [ "$1" = "--ci" ] || [ "$CI" = "true" ]; then
    line
    printf "${{WHITE}}${{BOLD}}   ✓ CI Build Complete: $TARGET_APP${{NC}}\\n"
    line
    printf "\\n"
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
launchctl unload "$PLIST_PATH" 2>/dev/null
launchctl load "$PLIST_PATH" 2>/dev/null
touch "$TARGET_APP"
open "$TARGET_APP" --args --open-preferences
ok "Jobs Monitor installed & running."
printf "\\n"

line
printf "${{WHITE}}${{BOLD}}   ✓ Jobs Monitor is now installed and running in your menu bar.${{NC}}\\n"
line
printf "\\n"
"""

out_command = os.path.join(script_dir, "install-jobsmonitor.command")
with open(out_command, "w", encoding="utf-8") as f:
    f.write(command_content)

os.chmod(out_command, 0o755)
print("Generated install-jobsmonitor.command with CI Build support!")
