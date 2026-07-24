import os
import sys
import base64

script_dir = os.path.dirname(os.path.abspath(__file__))
main_swift_path = os.path.join(script_dir, "main.swift")
jobs_png_path = os.path.join(script_dir, "Jobs.png")

if not os.path.exists(main_swift_path):
    main_swift_path = "main.swift"

if not os.path.exists(jobs_png_path):
    jobs_png_path = "Jobs.png"

with open(main_swift_path, "r", encoding="utf-8") as f:
    swift_code = f.read()

swift_b64 = base64.b64encode(swift_code.encode("utf-8")).decode("utf-8")

if os.path.exists(jobs_png_path):
    with open(jobs_png_path, "rb") as f:
        jobs_png_b64 = base64.b64encode(f.read()).decode("utf-8")
else:
    jobs_png_b64 = ""

command_content = f"""#!/usr/bin/env python3
import os
import sys
import subprocess
import base64
import shutil
from pathlib import Path

VERSION = "v2.0.0"
CONTACT_EMAIL = "arunthomashyd@gmail.com"
APP_NAME = "JobsMonitor"
PLIST_LABEL = "com.aoh.jobsmonitor"

# ANSI Colors
C_APP = "\\033[1;36m"
C_OK  = "\\033[1;32m"
C_WARN= "\\033[1;33m"
C_ERR = "\\033[1;31m"
C_INF = "\\033[1;34m"
C_DIM = "\\033[2m"
C_RST = "\\033[0m"

SWIFT_B64 = \"\"\"{swift_b64}\"\"\"
JOBS_PNG_B64 = \"\"\"{jobs_png_b64}\"\"\"

def print_box_line(text, visible_len):
    padding = 54 - visible_len
    print(f"   {{C_DIM}}│{{C_RST}}{{text}}{{' ' * padding}}{{C_DIM}}│{{C_RST}}")

def print_header():
    print("\\033[2J\\033[H", end="")
    print(f"\\n    {{C_APP}}  Jobs Monitor{{C_RST}}  {{C_DIM}}{{VERSION}}{{C_RST}}")
    print(f"    {{C_DIM}}Built by Arun Thomas ({{CONTACT_EMAIL}}){{C_RST}}\\n")
    print(f"    {{C_DIM}}Native macOS Menu Bar App for Apple Job Postings.{{C_RST}}")
    print(f"   {{C_DIM}}──────────────────────────────────────────────────────────{{C_RST}}\\n")

def check_dependencies():
    print(f"    {{C_INF}}●{{C_RST}} Checking macOS build environment...")
    if not shutil.which("swiftc"):
        print(f"    {{C_ERR}}✖ swiftc (Swift compiler) not found! Please install Xcode Command Line Tools (`xcode-select --install`).{{C_RST}}")
        sys.exit(1)
    if not shutil.which("sips") or not shutil.which("iconutil"):
        print(f"    {{C_ERR}}✖ sips or iconutil tools not found.{{C_RST}}")
        sys.exit(1)
    print(f"    {{C_OK}}✔{{C_RST}} Developer build tools available.\\n")

def cleanup_old_install():
    home = Path.home()
    plist_path = home / "Library/LaunchAgents" / f"{{PLIST_LABEL}}.plist"
    old_plist1 = home / "Library/LaunchAgents/com.arunthomas.applejobsmonitor.plist"
    old_plist2 = home / "Library/LaunchAgents/com.arunthomas.jobsmonitor.plist"
    
    # Kill running processes
    subprocess.run(["pkill", "-f", "AppleJobsMonitor"], capture_output=True)
    subprocess.run(["pkill", "-f", "JobsMonitor"], capture_output=True)
    
    # Unload launch agents
    uid = os.getuid()
    for p in [plist_path, old_plist1, old_plist2]:
        if p.exists():
            subprocess.run(["launchctl", "bootout", f"gui/{{uid}}", str(p)], capture_output=True)
            subprocess.run(["launchctl", "unload", str(p)], capture_output=True)
            try: os.remove(p)
            except OSError: pass

def build_app_and_install():
    check_dependencies()
    cleanup_old_install()
    
    home = Path.home()
    app_dir = home / "Applications"
    target_app = app_dir / f"{{APP_NAME}}.app"
    app_dir.mkdir(parents=True, exist_ok=True)
    
    build_scratch = home / ".jobsmonitor_build"
    if build_scratch.exists():
        shutil.rmtree(build_scratch)
    build_scratch.mkdir(parents=True, exist_ok=True)
    
    print(f"    {{C_INF}}●{{C_RST}} Unpacking Swift source code...")
    main_swift = build_scratch / "main.swift"
    with open(main_swift, "w", encoding="utf-8") as f:
        f.write(base64.b64decode(SWIFT_B64).decode("utf-8"))
        
    print(f"    {{C_INF}}●{{C_RST}} Compiling native {{APP_NAME}} binary with Swift...")
    exec_path = build_scratch / APP_NAME
    res = subprocess.run([
        "swiftc", "-O", str(main_swift),
        "-o", str(exec_path),
        "-framework", "AppKit",
        "-framework", "ServiceManagement"
    ], capture_output=True, text=True)
    
    if res.returncode != 0:
        print(f"    {{C_ERR}}✖ Compilation failed:\\n{{res.stderr}}{{C_RST}}")
        sys.exit(1)
        
    print(f"    {{C_OK}}✔{{C_RST}} Binary compiled successfully.")
    
    # Build App Bundle structure
    contents_dir = target_app / "Contents"
    macos_dir = contents_dir / "MacOS"
    resources_dir = contents_dir / "Resources"
    
    shutil.rmtree(target_app, ignore_errors=True)
    macos_dir.mkdir(parents=True, exist_ok=True)
    resources_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy executable
    shutil.copy2(exec_path, macos_dir / APP_NAME)
    os.chmod(macos_dir / APP_NAME, 0o755)
    
    # Generate ICNS Icon from Jobs.png
    print(f"    {{C_INF}}●{{C_RST}} Generating multi-resolution AppIcon.icns from Jobs.png...")
    png_source = build_scratch / "Jobs.png"
    if JOBS_PNG_B64:
        with open(png_source, "wb") as f:
            f.write(base64.b64decode(JOBS_PNG_B64))
    
    if png_source.exists():
        iconset = build_scratch / "AppIcon.iconset"
        iconset.mkdir(exist_ok=True)
        
        sizes = [
            (16, "icon_16x16.png"),
            (32, "icon_16x16@2x.png"),
            (32, "icon_32x32.png"),
            (64, "icon_32x32@2x.png"),
            (128, "icon_128x128.png"),
            (256, "icon_128x128@2x.png"),
            (256, "icon_256x256.png"),
            (512, "icon_256x256@2x.png"),
            (512, "icon_512x512.png"),
            (1024, "icon_512x512@2x.png")
        ]
        
        for sz, filename in sizes:
            out_file = iconset / filename
            subprocess.run(["sips", "-z", str(sz), str(sz), str(png_source), "--out", str(out_file)], capture_output=True)
            
        icns_out = resources_dir / "AppIcon.icns"
        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns_out)], capture_output=True)
        shutil.copy2(png_source, resources_dir / "AppIcon.png")
        print(f"    {{C_OK}}✔{{C_RST}} AppIcon.icns compiled and embedded into bundle.")
        
    # Write Info.plist
    info_plist = contents_dir / "Info.plist"
    info_plist_content = f\"\"\"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>{{APP_NAME}}</string>
    <key>CFBundleIdentifier</key>
    <string>{{PLIST_LABEL}}</string>
    <key>CFBundleName</key>
    <string>Jobs Monitor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>{{VERSION}}</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>\"\"\"
    with open(info_plist, "w", encoding="utf-8") as f:
        f.write(info_plist_content)
        
    # Refresh Finder icon cache
    subprocess.run(["touch", str(target_app)], capture_output=True)
    
    # Configure Launch at Login via LaunchAgent
    print(f"    {{C_INF}}●{{C_RST}} Setting up Launch at Login...")
    launch_agent_dir = home / "Library/LaunchAgents"
    launch_agent_dir.mkdir(parents=True, exist_ok=True)
    plist_path = launch_agent_dir / f"{{PLIST_LABEL}}.plist"
    
    plist_content = f\"\"\"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{{PLIST_LABEL}}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{{target_app}}/Contents/MacOS/{{APP_NAME}}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>\"\"\"
    with open(plist_path, "w", encoding="utf-8") as f:
        f.write(plist_content)
        
    uid = os.getuid()
    subprocess.run(["launchctl", "unload", str(plist_path)], capture_output=True)
    subprocess.run(["launchctl", "load", str(plist_path)], capture_output=True)
    
    # Cleanup scratch
    shutil.rmtree(build_scratch, ignore_errors=True)
    
    print(f"    {{C_INF}}●{{C_RST}} Launching {{APP_NAME}}...")
    subprocess.run(["open", str(target_app)], capture_output=True)
    
    print(f"\\n    {{C_OK}}✔{{C_RST}} {{C_APP}}Installation Complete!{{C_RST}}\\n")
    print(f"{{C_DIM}}   ╭──────────────────────────────────────────────────────╮{{C_RST}}")
    print_box_line("", 0)
    print_box_line("  Jobs Monitor is now live in your macOS Menu Bar!", 50)
    print_box_line("  App bundle installed at: ~/Applications/JobsMonitor.app", 57)
    print_box_line("  Launch at Login has been automatically configured.", 52)
    print_box_line("", 0)
    print_box_line(f"  {{C_APP}}You can now safely quit this Terminal window.{{C_RST}}", 47)
    print_box_line("  (Press Cmd + Q or close the window)", 37)
    print_box_line("", 0)
    print(f"{{C_DIM}}   ╰──────────────────────────────────────────────────────╯{{C_RST}}\\n")
    
    applescript = \"\"\"
    try
        display alert " Jobs Monitor" message "Installation Complete! Jobs Monitor is now active in your menu bar with Launch at Login enabled." buttons {{"OK"}} default button "OK"
    end try
    tell application "Terminal"
        try
            close (every window whose name contains "JobsMonitor") saving no
        end try
    end tell
    \"\"\"
    subprocess.run(["osascript", "-e", applescript], capture_output=True)

def uninstall():
    print_header()
    print(f"    {{C_INF}}●{{C_RST}} Uninstalling Jobs Monitor...")
    cleanup_old_install()
    
    target_app = Path.home() / "Applications/JobsMonitor.app"
    if target_app.exists():
        shutil.rmtree(target_app, ignore_errors=True)
        
    print(f"\\n    {{C_OK}}✔{{C_RST}} {{C_APP}}Successfully uninstalled Jobs Monitor.{{C_RST}}\\n")
    applescript = \"\"\"
    try
        display alert " Jobs Monitor" message "Jobs Monitor has been uninstalled." buttons {{"OK"}} default button "OK"
    end try
    tell application "Terminal"
        try
            close (every window whose name contains "JobsMonitor") saving no
        end try
    end tell
    \"\"\"
    subprocess.run(["osascript", "-e", applescript], capture_output=True)

def main_menu():
    print_header()
    print(f"    {{C_INF}}●{{C_RST}} {{C_APP}}Select an option:{{C_RST}}\\n")
    print(f"       1)  Install / Compile Jobs Monitor (Complete Setup)")
    print(f"       2)  Uninstall Jobs Monitor")
    
    choice = input(f"\\n    {{C_APP}}►  Enter choice (1 or 2) [1]: {{C_RST}}").strip()
    print()
    
    if choice == "2":
        uninstall()
    else:
        build_app_and_install()

if __name__ == "__main__":
    main_menu()
"""

out_command = os.path.join(script_dir, "install-jobsmonitor.command")
with open(out_command, "w", encoding="utf-8") as f:
    f.write(command_content)

os.chmod(out_command, 0o755)
print("Generated install-jobsmonitor.command successfully!")
