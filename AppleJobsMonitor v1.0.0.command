#!/bin/sh
''''command -v python3 >/dev/null 2>&1 && exec python3 "$0" "$@" # '''
''''
msg="Apple Jobs Monitor requires a lightweight Python 3 runtime (~40MB) to monitor Apple roles in the background.\n\nWould you like to automatically download and open the official Python installer now?"

choice=$(osascript -e '
try
    set res to display alert " Python 3 Required" message "'"$msg"'" buttons {"Cancel", "Download & Open Installer"} default button "Download & Open Installer"
    return button returned of res
on error
    return "Cancel"
end try
' 2>/dev/null)

if [ "$choice" = "button returned:Download & Open Installer" ] || [ "$choice" = "Download & Open Installer" ]; then
    echo "Downloading official Python 3 installer (~40MB)..."
    curl -L -o /tmp/Python_Installer.pkg "https://www.python.org/ftp/python/3.12.4/python-3.12.4-macos11.pkg" 2>/dev/null || \
    curl -L -o /tmp/Python_Installer.pkg "https://www.python.org/ftp/python/3.11.9/python-3.11.9-macos11.pkg" 2>/dev/null
    
    if [ -f /tmp/Python_Installer.pkg ]; then
        echo "Opening Python 3 installer..."
        open /tmp/Python_Installer.pkg
    else
        echo "Opening Python download page in browser..."
        open "https://www.python.org/downloads/mac-osx/"
    fi
else
    echo "Python installation cancelled."
fi
exit 1
'''
import json, os, re, smtplib, ssl, subprocess, sys, urllib.request, urllib.error
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

# ── Global Constants ───────────────────────────────────────────────────────────
VERSION       = "v1.0.0"
CONTACT_EMAIL = "arunthomashyd@gmail.com"

# ── Configuration ──────────────────────────────────────────────────────────────
APP_DIR = Path(os.path.expanduser("~/Library/Application Support/AppleJobsMonitor"))
APP_DIR.mkdir(parents=True, exist_ok=True)
STATE_FILE = APP_DIR / "seen_jobs.json"
LOG_FILE   = APP_DIR / "monitor.log"

# You can change this URL to any search URL from jobs.apple.com
JOBS_URL = "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest"

# Fill via environment variables or edit directly:
TO_EMAIL   = os.getenv("APPLE_JOBS_TO_EMAIL",   CONTACT_EMAIL)
FROM_EMAIL = os.getenv("APPLE_JOBS_FROM_EMAIL",  CONTACT_EMAIL)
SMTP_HOST  = os.getenv("APPLE_JOBS_SMTP_HOST",   "smtp.gmail.com")
SMTP_PORT  = int(os.getenv("APPLE_JOBS_SMTP_PORT", "587"))
SMTP_USER  = os.getenv("APPLE_JOBS_SMTP_USER",   FROM_EMAIL)
SMTP_PASS  = os.getenv("APPLE_JOBS_SMTP_PASS",   "")   # ← set your app-password

# ── Helpers ────────────────────────────────────────────────────────────────────
def log(msg, echo=True):
    try:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{ts}] {msg}"
        if echo:
            print(line)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception as e:
        if echo:
            print(f"Log writing warning: {e}")

def load_state():
    if STATE_FILE.exists():
        try:
            data = json.loads(STATE_FILE.read_text(encoding="utf-8"))
            return set(data.get("seen_ids", [])), data.get("last_daily_popup", ""), data.get("last_popup_time", "")
        except Exception as e:
            log(f"State read error ({e}), starting fresh.", echo=False)
    return set(), "", ""

def save_state(seen_ids, last_daily_popup, last_popup_time=""):
    try:
        data = {
            "seen_ids": list(seen_ids),
            "last_daily_popup": last_daily_popup,
            "last_popup_time": last_popup_time
        }
        tmp_file = APP_DIR / "seen_jobs.json.tmp"
        tmp_file.write_text(json.dumps(data, indent=2), encoding="utf-8")
        os.replace(tmp_file, STATE_FILE)
    except Exception as e:
        log(f"State save warning: {e}", echo=False)

def fetch_html(url, retries=3):
    headers = {
        "User-Agent": ("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) "
                       "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                       "Version/17.5 Safari/605.1.15"),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers=headers)
            ctx = ssl.create_default_context()
            with urllib.request.urlopen(req, timeout=30, context=ctx) as r:
                return r.read().decode("utf-8", errors="replace")
        except Exception as e:
            if "CERTIFICATE_VERIFY_FAILED" in str(e) or "self-signed certificate" in str(e) or isinstance(e, urllib.error.URLError):
                try:
                    req = urllib.request.Request(url, headers=headers)
                    ctx = ssl._create_unverified_context()
                    with urllib.request.urlopen(req, timeout=30, context=ctx) as r:
                        return r.read().decode("utf-8", errors="replace")
                except Exception as inner_e:
                    if attempt == retries:
                        raise inner_e
            if attempt == retries:
                raise

def parse_jobs(html, echo=True):
    jobs = []

    # Strategy 1: SSR hydration blob
    m = re.search(
        r'window\.__staticRouterHydrationData\s*=\s*JSON\.parse\("(.+?)"\);\s*<',
        html, re.DOTALL)
    if m:
        try:
            raw_json = json.loads('"' + m.group(1) + '"')
            data  = json.loads(raw_json)
            for loader_val in data.get("loaderData", {}).values():
                if not isinstance(loader_val, dict):
                    continue
                for key in ("searchResults", "roles", "results", "roleList"):
                    roles = loader_val.get(key) or loader_val.get("data", {}).get(key)
                    if isinstance(roles, list) and roles:
                        return [_norm(r) for r in roles]
        except Exception as e:
            log(f"Hydration parse error: {e}", echo=echo)

    # Strategy 2: inline JSON blobs
    for blob in re.finditer(r'\{[^{}]*"positionId"[^{}]*\}', html):
        try:
            jobs.append(_norm(json.loads(blob.group())))
        except Exception:
            pass

    # Strategy 3: JSON-LD
    if not jobs:
        for jld in re.finditer(
                r'<script[^>]+type="application/ld\+json"[^>]*>(.*?)</script>',
                html, re.DOTALL | re.IGNORECASE):
            try:
                obj = json.loads(jld.group(1))
                t = obj.get("@type", "")
                if t == "ItemList":
                    for item in obj.get("itemListElement", []):
                        jobs.append(_norm(item.get("item", {})))
                elif t == "JobPosting":
                    jobs.append(_norm(obj))
            except Exception:
                pass
    return jobs

def _norm(raw):
    if not isinstance(raw, dict):
        return {"id": "", "title": "—", "team": "", "location": "India", "posted": "", "url": JOBS_URL}
    
    pid = raw.get("positionId") or raw.get("id")
    if not pid and isinstance(raw.get("identifier"), dict):
        pid = raw["identifier"].get("value")
    elif not pid:
        pid = raw.get("identifier")
        
    team_val = raw.get("team")
    if isinstance(team_val, dict):
        team_str = team_val.get("teamName", "")
    else:
        team_str = str(team_val) if team_val else ""

    return {
        "id":       str(pid or "").strip(),
        "title":    str(raw.get("postingTitle") or raw.get("title") or raw.get("name") or raw.get("jobTitle") or "—").strip(),
        "team":     team_str.strip(),
        "location": _loc(raw),
        "posted":   str(raw.get("postingDate") or raw.get("datePosted") or "").strip(),
        "url":      _job_url(raw),
    }

def _loc(raw):
    if not isinstance(raw, dict):
        return "India"
    locs = raw.get("locations") or raw.get("jobLocation") or []
    if isinstance(locs, list) and locs:
        f = locs[0]
        if isinstance(f, dict):
            if f.get("name"):
                return str(f["name"])
            city = f.get('city', '')
            country = f.get('countryCode', '') or f.get('addressCountry', '') or f.get('countryName', '')
            return f"{city}, {country}".strip(", ") or "India"
        return str(f)
    if isinstance(locs, dict):
        if locs.get("name"):
            return str(locs["name"])
        addr = locs.get("address")
        if isinstance(addr, dict) and addr.get("addressLocality"):
            return str(addr["addressLocality"])
        return str(locs)
    return str(locs) if locs else "India"

def _job_url(raw):
    if not isinstance(raw, dict):
        return JOBS_URL
    pid = raw.get("positionId") or raw.get("id", "")
    return f"https://jobs.apple.com/en-us/details/{pid}" if pid else str(raw.get("url", JOBS_URL))

# ── Email & Dashboard ──────────────────────────────────────────────────────────
def get_dashboard_html(jobs_list, greeting, subtitle, location_title, jobs_url):
    rows = ""
    for j in jobs_list:
        rows += f"""
        <tr>
          <td class="cell">
            <a href="{j['url']}" class="job-link">{j['title']}</a>
            <br><span class="text-muted">{j['team'] or ''}</span>
          </td>
          <td class="cell">{j['location']}</td>
          <td class="cell text-muted">{j['posted'] or '—'}</td>
        </tr>"""

    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
  :root {{
    --bg-page: #f5f5f7;
    --bg-card: #ffffff;
    --text-main: #1d1d1f;
    --text-sec: #86868b;
    --border: #d2d2d7;
    --header-bg: #000000;
    --header-text: #f5f5f7;
    --btn-bg: #0071e3;
    --btn-text: #ffffff;
    --link: #0071e3;
  }}
  @media (prefers-color-scheme: dark) {{
    :root {{
      --bg-page: #000000;
      --bg-card: #1c1c1e;
      --text-main: #f5f5f7;
      --text-sec: #86868b;
      --border: #38383a;
      --header-bg: #1c1c1e;
      --header-text: #f5f5f7;
      --btn-bg: #f5f5f7;
      --btn-text: #000000;
      --link: #2997ff;
    }}
  }}
  body {{ margin:0; padding:0; background:var(--bg-page); font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',Helvetica,Arial,sans-serif; color:var(--text-main); }}
  .container {{ max-width:1200px; width:90%; margin:32px auto; background:var(--bg-card); border-radius:18px; overflow:hidden; border:1px solid var(--border); box-shadow:0 4px 24px rgba(0,0,0,0.04); }}
  .header {{ background:var(--header-bg); padding:28px 32px; border-bottom:1px solid var(--border); }}
  .header-title {{ color:var(--header-text); font-size:22px; font-weight:600; letter-spacing:-0.01em; }}
  .header-sub {{ color:var(--text-sec); font-size:13px; margin-top:4px; }}
  .content {{ padding:28px 32px; }}
  .greeting {{ font-size:16px; margin:0 0 20px; }}
  table {{ width:100%; border-collapse:collapse; }}
  th {{ padding:12px 8px; text-align:left; font-size:12px; color:var(--text-sec); text-transform:uppercase; border-bottom:1px solid var(--border); font-weight:600; letter-spacing:0.02em; }}
  .cell {{ padding:16px 8px; border-bottom:1px solid var(--border); font-size:14px; }}
  .job-link {{ color:var(--link); font-weight:600; text-decoration:none; font-size:15px; }}
  .job-link:hover {{ text-decoration:underline; }}
  .text-muted {{ color:var(--text-sec); font-size:13px; }}
  .btn-wrapper {{ margin-top:32px; text-align:center; }}
  .btn {{ display:inline-block; background:var(--btn-bg); color:var(--btn-text); text-decoration:none; padding:12px 24px; border-radius:980px; font-size:15px; font-weight:600; }}
  .footer {{ padding:16px 32px; background:var(--bg-page); border-top:1px solid var(--border); text-align:center; color:var(--text-sec); font-size:12px; }}
</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="header-title"> Apple Jobs · {location_title}</div>
      <div class="header-sub">{subtitle}</div>
    </div>
    <div class="content">
      <p class="greeting">{greeting}</p>
      <table>
        <thead><tr><th>Role</th><th>Location</th><th>Posted</th></tr></thead>
        <tbody>{rows}</tbody>
      </table>
      <div class="btn-wrapper">
        <a href="{jobs_url}" class="btn">View All Apple Jobs →</a>
      </div>
    </div>
    <div style="padding: 24px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border);">
      <strong style="color: var(--text-main); font-size: 14px;">How Apple Jobs Monitor Works:</strong>
      <ul style="margin: 12px 0 16px 0; padding-left: 20px; line-height: 1.6;">
        <li><strong style="color: var(--text-main);">Runs Silently:</strong> You don't need to keep any apps or windows open. The monitor runs completely invisibly in the background.</li>
        <li><strong style="color: var(--text-main);">Checks Every 2 Hours & Morning:</strong> It checks Apple Careers every two hours and at 10:00 AM every weekday.</li>
        <li><strong style="color: var(--text-main);">Starts Automatically:</strong> If you restart your Mac, the monitor automatically wakes up and resumes checking as soon as you log in.</li>
        <li><strong style="color: var(--text-main);">Instant Alerts:</strong> The moment a brand new role is posted, a notification pops up on your screen so you can be the first to apply.</li>
        <li><strong style="color: var(--text-main);">Daily Check-in:</strong> Even if no new jobs are posted, it shows you this dashboard once per day to confirm it's keeping watch!</li>
      </ul>
      <div style="background: var(--bg-card); border: 1px solid var(--border); border-radius: 12px; padding: 16px 20px; margin-top: 12px;">
        <strong style="color: var(--text-main); font-size: 13px; display: block; margin-bottom: 8px;">💡 Power Feature: Track Any Role, Team, or City Worldwide (Option 3)</strong>
        <span style="line-height: 1.6; display: block;">
          You aren't limited to default locations! You can monitor <strong>any custom search filter globally</strong>:
          <br>1. Open <a href="https://jobs.apple.com/en-us/search" target="_blank" style="color: var(--link); text-decoration: underline;">jobs.apple.com</a> and set your preferred filters (e.g. <em>"AI Engineer" in London</em>, <em>"Hardware" in Cupertino</em>, or <em>"Design" in Tokyo</em>).
          <br>2. Copy the full link from your browser's address bar.
          <br>3. Launch <code>AppleJobsMonitor.command</code>, select <strong>Option 3</strong>, and paste your URL. The monitor will now track your custom search 24/7!
        </span>
      </div>
    </div>
    <div class="footer">
      Apple Jobs Monitor {VERSION} · Built by Arun Thomas · Contact: {CONTACT_EMAIL}<br>
      {datetime.now().strftime("%d %b %Y, %I:%M %p")}
    </div>
  </div>
</body></html>"""

def build_email(new_jobs, jobs_url, location_title):
    count   = len(new_jobs)
    subject = f" {count} New Apple Job{'s' if count > 1 else ''} in {location_title}"

    plain_lines = [
        f"Hi Arun,",
        f"{count} new Apple role{'s have' if count>1 else ' has'} been posted for {location_title}:"
    ]
    for j in new_jobs:
        plain_lines += [
            f"• {j['title']}",
            f"  Team:     {j['team'] or '—'}",
            f"  Location: {j['location']}",
            f"  Posted:   {j['posted'] or '—'}",
            f"  Link:     {j['url']}",
            ""
        ]
    plain_lines += ["View all:", jobs_url, "", "— Apple Jobs Monitor"]
    plain = "\n".join(plain_lines)

    greeting = f"Hi Arun 👋 — {count} new role{'s have' if count>1 else ' has'} just been posted for <strong>{location_title}</strong>:"
    subtitle = f"{count} new opening{'s' if count>1 else ''} detected"
    html = get_dashboard_html(new_jobs, greeting, subtitle, location_title, jobs_url)

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"Apple Jobs Monitor <{FROM_EMAIL}>"
    msg["To"]      = TO_EMAIL
    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html,  "html"))
    return msg

def send_email(msg, echo=True):
    if not SMTP_PASS:
        log("SMTP_PASS not set. Email dispatch skipped.", echo=echo)
        return
    ctx = ssl.create_default_context()
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
        s.ehlo(); s.starttls(context=ctx); s.login(SMTP_USER, SMTP_PASS)
        s.sendmail(FROM_EMAIL, TO_EMAIL, msg.as_string())
    log(f"Email sent via SMTP to {TO_EMAIL}", echo=echo)

def notify_dashboard(title, message, html_content):
    try:
        dashboard_path = APP_DIR / "dashboard.html"
        dashboard_path.write_text(html_content, encoding="utf-8")
        
        t = title.replace('"', '\"').replace("'", "'")
        m = message.replace('"', '\"').replace("'", "'")
        
        # 1. Native macOS Notification Banner
        notif_script = f'display notification "{m}" with title "{t}" sound name "Glass"'
        subprocess.run(["osascript", "-e", notif_script], capture_output=True)
        
        # 2. Native macOS Alert Popup Box (opens browser ONLY when "View Dashboard" is clicked)
        alert_script = f"""
        try
            set response to display alert "{t}" message "{m}" buttons {{"Dismiss", "View Dashboard"}} default button "View Dashboard" giving up after 300
            if button returned of response is "View Dashboard" then
                do shell script "open '{dashboard_path}'"
            end if
        end try
        """
        subprocess.run(["osascript", "-e", alert_script], capture_output=True)
    except Exception as e:
        log(f"Notification display warning: {e}", echo=False)

# ── Main ───────────────────────────────────────────────────────────────────────
def main(jobs_url, location_title, is_install=False):
    echo_log = not is_install
    log(f"── Apple Jobs Monitor starting for {location_title} ──", echo=echo_log)
    
    if not is_install and datetime.today().weekday() >= 5:
        log("It's the weekend. Exiting.", echo=echo_log)
        return

    try:
        html = fetch_html(jobs_url)
    except Exception as e:
        log(f"Fetch error: {e}", echo=echo_log); sys.exit(1)

    jobs     = parse_jobs(html, echo=echo_log)
    log(f"Fetched {len(jobs)} role(s) from Apple Jobs.", echo=echo_log)

    seen_ids, last_daily_popup, last_popup_time = load_state()
    
    today_str = datetime.today().strftime("%Y-%m-%d")
    now_time_str = datetime.now().strftime("%I:%M %p")

    if is_install:
        new_jobs = jobs
    else:
        new_jobs = [j for j in jobs if j.get("id") and j["id"] not in seen_ids]

    if not new_jobs:
        if not is_install and last_daily_popup == today_str:
            time_info = f" (last shown at {last_popup_time})" if last_popup_time else ""
            log(f"No new jobs found. Daily popup already shown today{time_info}. Exiting silently.", echo=echo_log)
            return
            
        log("No new jobs found. Displaying last 10 jobs in dashboard.", echo=echo_log)
        recent_jobs = jobs[:10]
        
        greeting = f"No new openings found since last check, but here are the last 10 job postings for <strong>{location_title}</strong>:"
        d_subtitle = "Most recent openings"
        html_content = get_dashboard_html(recent_jobs, greeting, d_subtitle, location_title, jobs_url)
        
        if not is_install:
            notify_dashboard(
                " Apple Jobs Monitor", 
                "No new openings found since last check, but check the last few on the dashboard.", 
                html_content
            )
        else:
            dashboard_path = APP_DIR / "dashboard.html"
            dashboard_path.write_text(html_content, encoding="utf-8")

        save_state(seen_ids, today_str, now_time_str)
        return

    log(f"🆕 {len(new_jobs)} job(s) ready for dashboard:", echo=echo_log)
    for j in new_jobs:
        log(f"   [{j.get('id')}] {j.get('title')} – {j.get('location')}", echo=echo_log)

    try:
        if not is_install:
            send_email(build_email(new_jobs, jobs_url, location_title), echo=echo_log)
    except Exception as e:
        log(f"Email error: {e}", echo=echo_log)

    if is_install:
        greeting = f"Hi Arun 👋 — Welcome to <strong>Apple Jobs Monitor</strong>! Here is your preview dashboard of current openings for <strong>{location_title}</strong>:"
        d_subtitle = f"{len(new_jobs)} active role{'s' if len(new_jobs)>1 else ''} currently tracked"
    else:
        greeting = f"Hi Arun 👋 — {len(new_jobs)} new role{'s have' if len(new_jobs)>1 else ' has'} just been posted since last check for <strong>{location_title}</strong>:"
        d_subtitle = f"{len(new_jobs)} new opening{'s' if len(new_jobs)>1 else ''} found since last check"
        alert_title = f" {len(new_jobs)} New Apple Job{'s' if len(new_jobs)>1 else ''}!"
        alert_msg = f"{len(new_jobs)} new opening{'s' if len(new_jobs)>1 else ''} found since last check. Your dashboard is ready."

    html_content = get_dashboard_html(new_jobs, greeting, d_subtitle, location_title, jobs_url)

    if not is_install:
        notify_dashboard(
            alert_title,
            alert_msg,
            html_content
        )
    else:
        dashboard_path = APP_DIR / "dashboard.html"
        dashboard_path.write_text(html_content, encoding="utf-8")

    seen_ids.update(j["id"] for j in new_jobs if j.get("id"))
    save_state(seen_ids, today_str, now_time_str)
    log("State saved. Done.", echo=echo_log)

def toggle_install():
    plist_path = os.path.expanduser("~/Library/LaunchAgents/com.applejobsmonitor.plist")
    script_path = os.path.abspath(__file__)
    
    # ANSI Terminal Colors
    C_APP = "\033[1m"   # Bold Default
    C_DIM = "\033[2m"   # Faint/Dim
    C_OK  = "\033[32m"  # Green
    C_ERR = "\033[31m"  # Red
    C_INF = "\033[34m"  # Blue
    C_RST = "\033[0m"   # Reset
    
    def print_box_line(text, visible_len):
        padding = 52 - visible_len
        print(f"{C_DIM}   │{C_RST}{text}{' ' * padding}{C_DIM}│{C_RST}")

    # Clear screen and print header
    print("\033[2J\033[H", end="")
    print(f"\n    {C_APP}  Apple Jobs Monitor{C_RST}  {C_DIM}{VERSION}{C_RST}")
    print(f"    {C_DIM}Built by Arun Thomas ({CONTACT_EMAIL}){C_RST}\n")
    print(f"    {C_DIM}Automated background monitoring for Apple roles.{C_RST}")
    print(f"   {C_DIM}──────────────────────────────────────────────────────────{C_RST}\n")
    
    def cleanup_existing():
        uid = os.getuid()
        if os.path.exists(plist_path):
            subprocess.run(["launchctl", "bootout", f"gui/{uid}", plist_path], capture_output=True)
            subprocess.run(["launchctl", "unload", plist_path], capture_output=True)
            try: os.remove(plist_path)
            except OSError: pass
            try: os.remove(STATE_FILE)
            except OSError: pass

    print(f"    {C_INF}●{C_RST} {C_APP}Select an option:{C_RST}\n")
    print(f"       1)  India (All Locations)")
    print(f"       2)  Hyderabad (Specific City)")
    print(f"       3)  Custom Search (Paste your own Apple Jobs search URL)")
    print(f"       4)  Uninstall Monitor")
    
    choice = input(f"\n    {C_APP}►  Enter choice (1, 2, 3, or 4) [1]: {C_RST}").strip()
    print()
    
    if choice == "4":
        cleanup_existing()
        print(f"    {C_OK}✔{C_RST} {C_APP}Successfully uninstalled.{C_RST}\n")
        print(f"{C_DIM}   ╭────────────────────────────────────────────────────╮{C_RST}")
        print_box_line("", 0)
        print_box_line("  The background service has been completely", 44)
        print_box_line("  removed. You will no longer receive daily alerts.", 51)
        print_box_line("", 0)
        print_box_line(f"  {C_APP}You can now safely quit this Terminal window.{C_RST}", 47)
        print_box_line("  (Press Cmd + Q or close the window)", 37)
        print_box_line("", 0)
        print(f"{C_DIM}   ╰────────────────────────────────────────────────────╯{C_RST}\n")
        
        applescript = '''
        try
            display alert " Apple Jobs Monitor" message "Monitor has been uninstalled.\n\nYou can now close the Terminal." buttons {"OK"} default button "OK"
        end try
        tell application "Terminal"
            try
                close (every window whose name contains "AppleJobsMonitor") saving no
            end try
        end tell
        '''
        subprocess.run(["osascript", "-e", applescript], capture_output=True)
        return

    cleanup_existing()

    if choice == "2":
        target_url = "https://jobs.apple.com/en-us/search?location=hyderabad-HY1&sort=newest"
        target_title = "Hyderabad"
    elif choice == "3":
        target_url = input(f"    {C_APP}Paste your search URL: {C_RST}").strip()
        target_title = "Custom Search"
        if not target_url.startswith("http"):
            print(f"    {C_ERR}Invalid URL. Defaulting to India.{C_RST}")
            target_url = "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest"
            target_title = "India"
    else:
        target_url = "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest"
        target_title = "India"
            
    print(f"    {C_INF}●{C_RST} {C_APP}Installing background service for {target_title}...{C_RST}")
    os.makedirs(os.path.dirname(plist_path), exist_ok=True)
    
    escaped_url = target_url.replace("&", "&amp;")
    
    plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.applejobsmonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>{sys.executable}</string>
        <string>{script_path}</string>
        <string>--check</string>
        <string>--url</string>
        <string>{escaped_url}</string>
        <string>--title</string>
        <string>{target_title}</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
    </array>
    <key>StartInterval</key>
    <integer>7200</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>{APP_DIR}/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>{APP_DIR}/launchd.error.log</string>
</dict>
</plist>"""
    with open(plist_path, "w", encoding="utf-8") as f:
        f.write(plist_content)
        
    print(f"    {C_INF}●{C_RST} {C_APP}Loading service into launchd...{C_RST}")
    uid = os.getuid()
    res = subprocess.run(["launchctl", "bootstrap", f"gui/{uid}", plist_path], capture_output=True)
    if res.returncode != 0:
        subprocess.run(["launchctl", "load", plist_path], capture_output=True)
    
    print(f"    {C_INF}●{C_RST} {C_APP}Initializing state and preparing dashboard...{C_RST}")
    try:
        main(target_url, target_title, is_install=True)
    except Exception as e:
        log(f"Initial setup error: {e}", echo=False)

    print(f"\n    {C_OK}✔{C_RST} {C_APP}Successfully activated!{C_RST}\n")
    
    print(f"{C_DIM}   ╭────────────────────────────────────────────────────╮{C_RST}")
    print_box_line("", 0)
    print_box_line("  The monitor will now run completely automatically", 51)
    print_box_line("  in the background every 2 hours.", 34)
    print_box_line("", 0)
    print_box_line(f"  {C_APP}You can now safely quit this Terminal window.{C_RST}", 47)
    print_box_line("  (Press Cmd + Q or close the window)", 37)
    print_box_line("", 0)
    print(f"{C_DIM}   ╰────────────────────────────────────────────────────╯{C_RST}\n")
    
    dashboard_path = APP_DIR / "dashboard.html"
    applescript = f'''
    try
        set res to display alert " Apple Jobs Monitor" message "Successfully activated for {target_title}!\n\nBackground monitoring is active." buttons {{"Dismiss", "View Dashboard"}} default button "View Dashboard" giving up after 300
        if button returned of res is "View Dashboard" then
            do shell script "open '{dashboard_path}'"
        end if
    end try
    tell application "Terminal"
        try
            close (every window whose name contains "AppleJobsMonitor") saving no
        end try
    end tell
    '''
    subprocess.run(["osascript", "-e", applescript], capture_output=True)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--url", default=JOBS_URL)
    parser.add_argument("--title", default="India")
    args, unknown = parser.parse_known_args()
    
    if args.check:
        main(args.url, args.title)
    else:
        toggle_install()
