import AppKit
import Foundation
import ServiceManagement

// ── Global Single-Source Constants ─────────────────────────────────────────────
let APP_VERSION = "2.0.2"
let CONTACT_EMAIL = "arunthomashyd@gmail.com"
let GITHUB_REPO_URL = "https://github.com/arunofhyd/JobsMonitor"
let VERSION_CHECK_URL = "https://raw.githubusercontent.com/arunofhyd/JobsMonitor/main/version.json"
let LATEST_RELEASE_URL = "https://github.com/arunofhyd/JobsMonitor/releases/latest"
let COMMAND_DOWNLOAD_URL = "https://raw.githubusercontent.com/arunofhyd/JobsMonitor/refs/heads/main/install-jobsmonitor.command"

let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("JobsMonitor")
let stateFile = appDir.appendingPathComponent("seen_jobs.json")
let settingsFile = appDir.appendingPathComponent("settings.json")
let dashboardFile = appDir.appendingPathComponent("dashboard.html")
let logFile = appDir.appendingPathComponent("monitor.log")

// ── Location Preset Items ──────────────────────────────────────────────────────
struct LocationPreset {
    let name: String
    let code: String
}

let countryPresets: [LocationPreset] = [
    LocationPreset(name: "India", code: "india-INDC"),
    LocationPreset(name: "United States", code: "united-states-USA"),
    LocationPreset(name: "United Kingdom", code: "united-kingdom-GBR"),
    LocationPreset(name: "Canada", code: "canada-CAN"),
    LocationPreset(name: "Australia", code: "australia-AUS"),
    LocationPreset(name: "Germany", code: "germany-DEU"),
    LocationPreset(name: "France", code: "france-FRA"),
    LocationPreset(name: "Japan", code: "japan-JPN"),
    LocationPreset(name: "Singapore", code: "singapore-SGP"),
    LocationPreset(name: "China mainland", code: "china-mainland-CHN"),
    LocationPreset(name: "Ireland", code: "ireland-IRL"),
    LocationPreset(name: "Switzerland", code: "switzerland-CHE"),
    LocationPreset(name: "Netherlands", code: "netherlands-NLD"),
    LocationPreset(name: "Sweden", code: "sweden-SWE"),
    LocationPreset(name: "Spain", code: "spain-ESP"),
    LocationPreset(name: "Italy", code: "italy-ITA"),
    LocationPreset(name: "South Korea", code: "south-korea-KOR"),
    LocationPreset(name: "Taiwan", code: "taiwan-TWN"),
    LocationPreset(name: "United Arab Emirates", code: "united-arab-emirates-ARE"),
    LocationPreset(name: "Brazil", code: "brazil-BRA"),
    LocationPreset(name: "Mexico", code: "mexico-MEX"),
    LocationPreset(name: "Israel", code: "israel-ISR"),
    LocationPreset(name: "Poland", code: "poland-POL"),
    LocationPreset(name: "Austria", code: "austria-AUT"),
    LocationPreset(name: "Belgium", code: "belgium-BEL"),
    LocationPreset(name: "Denmark", code: "denmark-DNK"),
    LocationPreset(name: "New Zealand", code: "new-zealand-NZL"),
    LocationPreset(name: "Vietnam", code: "vietnam-VNM"),
    LocationPreset(name: "Thailand", code: "thailand-THA"),
    LocationPreset(name: "Malaysia", code: "malaysia-MYS")
]

let cityPresets: [LocationPreset] = [
    LocationPreset(name: "Hyderabad", code: "hyderabad-HY1"),
    LocationPreset(name: "Bengaluru", code: "bengaluru-BEN"),
    LocationPreset(name: "Chennai", code: "chennai-CHE"),
    LocationPreset(name: "Gurugram", code: "gurugram-GUR"),
    LocationPreset(name: "Mumbai", code: "mumbai-MUM"),
    LocationPreset(name: "Cupertino", code: "cupertino-CUP"),
    LocationPreset(name: "Austin", code: "austin-AUS"),
    LocationPreset(name: "San Francisco", code: "san-francisco-SFO"),
    LocationPreset(name: "Seattle", code: "seattle-SEA"),
    LocationPreset(name: "San Diego", code: "san-diego-SAN"),
    LocationPreset(name: "New York", code: "new-york-NYC"),
    LocationPreset(name: "Boston", code: "boston-BOS"),
    LocationPreset(name: "Los Angeles", code: "los-angeles-LAX"),
    LocationPreset(name: "Chicago", code: "chicago-CHI"),
    LocationPreset(name: "London", code: "london-LON"),
    LocationPreset(name: "Cambridge", code: "cambridge-CAM"),
    LocationPreset(name: "Vancouver", code: "vancouver-VAN"),
    LocationPreset(name: "Toronto", code: "toronto-TOR"),
    LocationPreset(name: "Munich", code: "munich-MUC"),
    LocationPreset(name: "Berlin", code: "berlin-BER"),
    LocationPreset(name: "Paris", code: "paris-PAR"),
    LocationPreset(name: "Zurich", code: "zurich-ZUR"),
    LocationPreset(name: "Cork", code: "cork-COR"),
    LocationPreset(name: "Tokyo", code: "tokyo-TYO"),
    LocationPreset(name: "Singapore", code: "singapore-SGP"),
    LocationPreset(name: "Sydney", code: "sydney-SYD"),
    LocationPreset(name: "Melbourne", code: "melbourne-MEL"),
    LocationPreset(name: "Seoul", code: "seoul-SEL"),
    LocationPreset(name: "Taipei", code: "taipei-TPE")
]

let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

let timeOptions: [(hour: Int, minute: Int, title: String)] = {
    var opts: [(Int, Int, String)] = []
    for h in 0..<24 {
        for m in [0, 30] {
            let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            let ampm = h >= 12 ? "PM" : "AM"
            let minStr = String(format: "%02d", m)
            let title = "\(hour12):\(minStr) \(ampm)"
            opts.append((h, m, title))
        }
    }
    return opts
}()

// ── Settings Model ─────────────────────────────────────────────────────────────
struct AppSettings: Codable {
    var locationMode: Int // 0: Country, 1: City, 2: Custom Search URL
    var countryIndex: Int
    var cityIndex: Int
    var customUrl: String
    var checkIntervalMinutes: Int // 5, 15, 30, 60, 120, 240, 360
    var popupDismissSeconds: Int // 10, 30, 60, 180, 300, 600, 0
    var enableDailyCheck: Bool
    var dailyCheckHour: Int // 0..23
    var dailyCheckMinute: Int // 0..59
    var activeDays: [Bool] // 7 booleans for [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
    var launchAtLogin: Bool
    
    static var defaultConfig: AppSettings {
        return AppSettings(
            locationMode: 0,
            countryIndex: 0,
            cityIndex: 0,
            customUrl: "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest",
            checkIntervalMinutes: 120,
            popupDismissSeconds: 300,
            enableDailyCheck: true,
            dailyCheckHour: 10,
            dailyCheckMinute: 0,
            activeDays: [false, true, true, true, true, true, false],
            launchAtLogin: true
        )
    }
    
    var activeUrl: String {
        switch locationMode {
        case 1:
            let idx = (cityIndex >= 0 && cityIndex < cityPresets.count) ? cityIndex : 0
            return "https://jobs.apple.com/en-us/search?location=\(cityPresets[idx].code)&sort=newest"
        case 2:
            return customUrl.isEmpty ? "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest" : customUrl
        default:
            let idx = (countryIndex >= 0 && countryIndex < countryPresets.count) ? countryIndex : 0
            return "https://jobs.apple.com/en-us/search?location=\(countryPresets[idx].code)&sort=newest"
        }
    }
    
    var locationTitle: String {
        switch locationMode {
        case 1:
            let idx = (cityIndex >= 0 && cityIndex < cityPresets.count) ? cityIndex : 0
            return cityPresets[idx].name
        case 2:
            return "Custom Search"
        default:
            let idx = (countryIndex >= 0 && countryIndex < countryPresets.count) ? countryIndex : 0
            return countryPresets[idx].name
        }
    }
}

func loadSettings() -> AppSettings {
    try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
    if let data = try? Data(contentsOf: settingsFile),
       let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
        return settings
    }
    let def = AppSettings.defaultConfig
    saveSettings(def)
    return def
}

func saveSettings(_ settings: AppSettings) {
    try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
    if let data = try? JSONEncoder().encode(settings) {
        try? data.write(to: settingsFile)
    }
}

// ── Launch at Login Helper ──────────────────────────────────────────────────────
func configureLaunchAtLogin(enabled: Bool) {
    if #available(macOS 13.0, *) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                logMessage("Registered Launch at Login via SMAppService")
            } else {
                try SMAppService.mainApp.unregister()
                logMessage("Unregistered Launch at Login via SMAppService")
            }
        } catch {
            logMessage("SMAppService registration notice: \(error.localizedDescription)")
            setupLaunchAgent(enabled: enabled)
        }
    } else {
        setupLaunchAgent(enabled: enabled)
    }
}

func setupLaunchAgent(enabled: Bool) {
    let launchAgentsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("LaunchAgents")
    let plistFile = launchAgentsDir.appendingPathComponent("com.aoh.jobsmonitor.plist")
    
    if enabled {
        try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        let execPath = "/Users/arunthomas/Applications/JobsMonitor.app/Contents/MacOS/JobsMonitor"
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.aoh.jobsmonitor</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        try? plistContent.write(to: plistFile, atomically: true, encoding: .utf8)
        logMessage("Installed LaunchAgent plist at \(plistFile.path)")
    } else {
        try? FileManager.default.removeItem(at: plistFile)
        logMessage("Removed LaunchAgent plist")
    }
}

// ── Logging ────────────────────────────────────────────────────────────────────
func logMessage(_ msg: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "[\(formatter.string(from: Date()))] \(msg)\n"
    print(line, terminator: "")
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
}

// ── Vector Menu Bar Icon (Apple Logo Inside Magnifying Glass) ─────────────────
func createVectorMenuIcon() -> NSImage {
    let size = NSSize(width: 20, height: 18)
    let img = NSImage(size: size, flipped: false) { rect in
        NSColor.black.setStroke()
        NSColor.black.setFill()
        
        // 1. Draw Lens Circle (Center at 7.5, 9.5, radius 6.0)
        let lensRect = NSRect(x: 1.5, y: 3.5, width: 12, height: 12)
        let lensPath = NSBezierPath(ovalIn: lensRect)
        lensPath.lineWidth = 1.6
        lensPath.stroke()
        
        // 2. Draw Handle starting precisely on the outer perimeter (12.2, 4.8)
        let handlePath = NSBezierPath()
        handlePath.move(to: NSPoint(x: 12.2, y: 4.8))
        handlePath.line(to: NSPoint(x: 17.2, y: -0.2))
        handlePath.lineWidth = 2.2
        handlePath.lineCapStyle = .round
        handlePath.stroke()
        
        // 3. Draw  Symbol centered inside the lens
        let font = NSFont.systemFont(ofSize: 8.0, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let str = NSAttributedString(string: "", attributes: attrs)
        let strSize = str.size()
        let strRect = NSRect(
            x: 7.5 - (strSize.width / 2.0),
            y: 9.5 - (strSize.height / 2.0),
            width: strSize.width,
            height: strSize.height
        )
        str.draw(in: strRect)
        
        return true
    }
    img.isTemplate = true
    return img
}

// ── Job Data Model ─────────────────────────────────────────────────────────────
struct JobItem: Codable {
    let id: String
    let title: String
    let team: String
    let location: String
    let posted: String
    let url: String
}

struct StateData: Codable {
    var seen_ids: [String]
    var unread_count: Int?
    var last_job_count: Int?
    var last_checked_str: String?
    var last_daily_popup: String?
    var last_popup_time: String?
}

func loadStateData() -> StateData {
    if let data = try? Data(contentsOf: stateFile),
       let st = try? JSONDecoder().decode(StateData.self, from: data) {
        return st
    }
    return StateData(seen_ids: [], unread_count: 0, last_job_count: 0, last_checked_str: "Never", last_daily_popup: "", last_popup_time: "")
}

func saveStateData(_ st: StateData) {
    if let data = try? JSONEncoder().encode(st) {
        try? data.write(to: stateFile)
    }
}

// ── HTML Dashboard Generator ───────────────────────────────────────────────────
func generateDashboardHTML(jobs: [JobItem], greeting: String, subtitle: String, locationTitle: String, searchUrl: String) -> String {
    var rows = ""
    for j in jobs {
        rows += """
        <tr>
          <td class="cell">
            <a href="\(j.url)" class="job-link">\(j.title)</a>
            <br><span class="text-muted">\(j.team)</span>
          </td>
          <td class="cell">\(j.location)</td>
          <td class="cell text-muted">\(j.posted.isEmpty ? "—" : j.posted)</td>
        </tr>
        """
    }
    
    let nowStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
    
    return """
    <!DOCTYPE html>
    <html><head><meta charset="utf-8">
    <style>
      :root {
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
      }
      @media (prefers-color-scheme: dark) {
        :root {
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
        }
      }
      body { margin:0; padding:0; background:var(--bg-page); font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',Helvetica,Arial,sans-serif; color:var(--text-main); }
      .container { max-width:1200px; width:90%; margin:32px auto; background:var(--bg-card); border-radius:18px; overflow:hidden; border:1px solid var(--border); box-shadow:0 4px 24px rgba(0,0,0,0.04); }
      .header { background:var(--header-bg); padding:28px 32px; border-bottom:1px solid var(--border); }
      .header-title { color:var(--header-text); font-size:22px; font-weight:600; letter-spacing:-0.01em; }
      .header-sub { color:var(--text-sec); font-size:13px; margin-top:4px; }
      .content { padding:28px 32px; }
      .greeting { font-size:16px; margin:0 0 20px; }
      table { width:100%; border-collapse:collapse; }
      th { padding:12px 8px; text-align:left; font-size:12px; color:var(--text-sec); text-transform:uppercase; border-bottom:1px solid var(--border); font-weight:600; letter-spacing:0.02em; }
      .cell { padding:16px 8px; border-bottom:1px solid var(--border); font-size:14px; }
      .job-link { color:var(--link); font-weight:600; text-decoration:none; font-size:15px; }
      .job-link:hover { text-decoration:underline; }
      .text-muted { color:var(--text-sec); font-size:13px; }
      .btn-wrapper { margin-top:32px; text-align:center; }
      .btn { display:inline-block; background:var(--btn-bg); color:var(--btn-text); text-decoration:none; padding:12px 24px; border-radius:980px; font-size:15px; font-weight:600; }
      .footer { padding:16px 32px; background:var(--bg-page); border-top:1px solid var(--border); text-align:center; color:var(--text-sec); font-size:12px; }
    </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="header-title"> Jobs Monitor · \(locationTitle)</div>
          <div class="header-sub">\(subtitle)</div>
        </div>
        <div class="content">
          <p class="greeting">\(greeting)</p>
          <table>
            <thead><tr><th>Role</th><th>Location</th><th>Posted</th></tr></thead>
            <tbody>\(rows)</tbody>
          </table>
          <div class="btn-wrapper">
            <a href="\(searchUrl)" class="btn">View All Apple Jobs →</a>
          </div>
        </div>
        <div style="padding: 24px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border);">
          <strong style="color: var(--text-main); font-size: 14px;">How Jobs Monitor Works:</strong>
          <ul style="margin: 12px 0 16px 0; padding-left: 20px; line-height: 1.6;">
            <li><strong style="color: var(--text-main);">Runs Silently:</strong> Native macOS menu bar application running in the background.</li>
            <li><strong style="color: var(--text-main);">Instant Notifications:</strong> Shows alerts instantly when new roles are posted.</li>
            <li><strong style="color: var(--text-main);">Click-to-View:</strong> The browser dashboard opens only when you click "View Dashboard".</li>
          </ul>
        </div>
        <div class="footer">
          Jobs Monitor v\(APP_VERSION) · Built by Arun Thomas · Contact: \(CONTACT_EMAIL)<br>
          \(nowStr)
        </div>
      </div>
    </body></html>
    """
}

// ── HTML Parser ────────────────────────────────────────────────────────────────
func parseJobsFromHTML(_ html: String, defaultSearchUrl: String) -> [JobItem] {
    var results: [JobItem] = []
    
    let marker = "window.__staticRouterHydrationData = JSON.parse(\""
    if let range = html.range(of: marker) {
        let sub = html[range.upperBound...]
        if let endRange = sub.range(of: "\");") {
            var rawJsonStr = String(sub[..<endRange.lowerBound])
            rawJsonStr = rawJsonStr.replacingOccurrences(of: "\\\"", with: "\"")
            rawJsonStr = rawJsonStr.replacingOccurrences(of: "\\\\", with: "\\")
            
            if let objData = rawJsonStr.data(using: .utf8),
               let root = try? JSONSerialization.jsonObject(with: objData) as? [String: Any],
               let loaderData = root["loaderData"] as? [String: Any] {
                
                for (_, v) in loaderData {
                    if let dict = v as? [String: Any] {
                        let roles = (dict["searchResults"] as? [[String: Any]]) ?? (dict["roles"] as? [[String: Any]])
                        if let rolesList = roles {
                            for r in rolesList {
                                if let item = normalizeJob(r, defaultUrl: defaultSearchUrl) {
                                    results.append(item)
                                }
                            }
                            if !results.isEmpty { return results }
                        }
                    }
                }
            }
        }
    }
    
    return results
}

func normalizeJob(_ raw: [String: Any], defaultUrl: String) -> JobItem? {
    let pid = (raw["positionId"] as? String) ?? (raw["id"] as? String) ?? ""
    if pid.isEmpty { return nil }
    
    let title = (raw["postingTitle"] as? String) ?? (raw["title"] as? String) ?? (raw["name"] as? String) ?? "—"
    
    var teamStr = ""
    if let teamDict = raw["team"] as? [String: Any] {
        teamStr = (teamDict["teamName"] as? String) ?? ""
    } else if let t = raw["team"] as? String {
        teamStr = t
    }
    
    var locStr = "India"
    if let locs = raw["locations"] as? [[String: Any]], let firstLoc = locs.first {
        let city = (firstLoc["city"] as? String) ?? ""
        let country = (firstLoc["countryName"] as? String) ?? (firstLoc["countryCode"] as? String) ?? ""
        if !city.isEmpty { locStr = "\(city), \(country)" }
        else if let n = firstLoc["name"] as? String, !n.isEmpty { locStr = n }
    }
    
    let posted = (raw["postingDate"] as? String) ?? (raw["datePosted"] as? String) ?? ""
    let url = "https://jobs.apple.com/en-us/details/\(pid)"
    
    return JobItem(id: pid, title: title, team: teamStr, location: locStr, posted: posted, url: url)
}

// ── ClipLocal-Style Native About Window ─────────────────────────────────────────
class AboutWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Jobs Monitor"
        window.center()
        self.init(window: window)
        
        setupUI()
    }
    
    func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // App Icon Image (96x96)
        let iconView = NSImageView(frame: NSRect(x: 162, y: 205, width: 96, height: 96))
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Users/arunthomas/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            iconView.image = img
        }
        contentView.addSubview(iconView)
        
        // App Title
        let titleLabel = NSTextField(labelWithString: "Jobs Monitor")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: 172, width: 380, height: 24)
        contentView.addSubview(titleLabel)
        
        // Version Subtitle
        let verLabel = NSTextField(labelWithString: "Version \(APP_VERSION)")
        verLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        verLabel.textColor = .secondaryLabelColor
        verLabel.alignment = .center
        verLabel.frame = NSRect(x: 20, y: 152, width: 380, height: 18)
        contentView.addSubview(verLabel)
        
        // Privacy Notice
        let descLabel = NSTextField(wrappingLabelWithString: "Zero telemetry. The app runs 100% locally on your Mac and connects directly to jobs.apple.com to check new openings.")
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.frame = NSRect(x: 30, y: 105, width: 360, height: 38)
        contentView.addSubview(descLabel)
        
        // Author Note
        let openSourceLabel = NSTextField(labelWithString: "Free & Open Source · Built by Arun Thomas")
        openSourceLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        openSourceLabel.alignment = .center
        openSourceLabel.frame = NSRect(x: 20, y: 82, width: 380, height: 18)
        contentView.addSubview(openSourceLabel)
        
        // Action Buttons
        // let ghBtn = NSButton(title: "GitHub Repository ↗", target: self, action: #selector(openGitHub))
        // ghBtn.frame = NSRect(x: 65, y: 30, width: 140, height: 32)
        // ghBtn.bezelStyle = .rounded
        // contentView.addSubview(ghBtn)
        
        let contactBtn = NSButton(title: "Contact Developer", target: self, action: #selector(openContact))
        contactBtn.frame = NSRect(x: 130, y: 30, width: 160, height: 32)
        contactBtn.bezelStyle = .rounded
        contentView.addSubview(contactBtn)
    }
    
    @objc func openGitHub() {
        if let url = URL(string: GITHUB_REPO_URL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openContact() {
        if let url = URL(string: "mailto:\(CONTACT_EMAIL)?subject=Jobs%20Monitor") {
            NSWorkspace.shared.open(url)
        }
    }
}

// ── Native Preferences Window ──────────────────────────────────────────────────
class SettingsWindowController: NSWindowController {
    var radioCountry: NSButton!
    var countryPopUp: NSPopUpButton!
    
    var radioCity: NSButton!
    var cityPopUp: NSPopUpButton!
    
    var radioCustom: NSButton!
    var customUrlField: NSTextField!
    
    var intervalPopUp: NSPopUpButton!
    var dismissPopUp: NSPopUpButton!
    
    var dailyCheckCheckbox: NSButton!
    var timePopUp: NSPopUpButton!
    var dayButtons: [NSButton] = []
    
    var launchAtLoginCheckbox: NSButton!
    
    var onSave: (() -> Void)?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 630),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Jobs Monitor Preferences"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        self.init(window: window)
        
        setupUI()
        loadCurrentValues()
    }
    
    func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // ── Top Header Banner (Centralized Logo Only) ─────────────────
        let headerView = NSView(frame: NSRect(x: 0, y: 540, width: 600, height: 90))
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let iconView = NSImageView(frame: NSRect(x: 268, y: 13, width: 64, height: 64))
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Users/arunthomas/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            iconView.image = img
        } else {
            iconView.image = NSImage(systemSymbolName: "briefcase.fill", accessibilityDescription: nil)
        }
        headerView.addSubview(iconView)
        
        let headerSep = NSBox(frame: NSRect(x: 0, y: 0, width: 600, height: 1))
        headerSep.boxType = .separator
        headerView.addSubview(headerSep)
        
        contentView.addSubview(headerView)
        
        // ── Card 1: Target Location (y: 355, height: 170) ────────────
        let card1 = createCardView(frame: NSRect(x: 24, y: 355, width: 552, height: 170))
        
        let card1Title = createSectionHeader(title: "Target Search Location", iconName: "mappin.and.ellipse", frame: NSRect(x: 16, y: 135, width: 520, height: 22))
        card1.addSubview(card1Title)
        
        radioCountry = NSButton(radioButtonWithTitle: "Country Preset:", target: self, action: #selector(radioChanged))
        radioCountry.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        radioCountry.frame = NSRect(x: 20, y: 100, width: 140, height: 22)
        radioCountry.tag = 0
        card1.addSubview(radioCountry)
        
        countryPopUp = NSPopUpButton(frame: NSRect(x: 165, y: 97, width: 365, height: 26))
        countryPopUp.addItems(withTitles: countryPresets.map { $0.name })
        card1.addSubview(countryPopUp)
        
        radioCity = NSButton(radioButtonWithTitle: "City Preset:", target: self, action: #selector(radioChanged))
        radioCity.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        radioCity.frame = NSRect(x: 20, y: 65, width: 140, height: 22)
        radioCity.tag = 1
        card1.addSubview(radioCity)
        
        cityPopUp = NSPopUpButton(frame: NSRect(x: 165, y: 62, width: 365, height: 26))
        cityPopUp.addItems(withTitles: cityPresets.map { $0.name })
        card1.addSubview(cityPopUp)
        
        radioCustom = NSButton(radioButtonWithTitle: "Custom URL:", target: self, action: #selector(radioChanged))
        radioCustom.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        radioCustom.frame = NSRect(x: 20, y: 30, width: 140, height: 22)
        radioCustom.tag = 2
        card1.addSubview(radioCustom)
        
        customUrlField = NSTextField(frame: NSRect(x: 165, y: 28, width: 365, height: 24))
        customUrlField.placeholderString = "https://jobs.apple.com/en-us/search?..."
        card1.addSubview(customUrlField)
        
        contentView.addSubview(card1)
        
        // ── Card 2: Frequency & Alerts (y: 230, height: 110) ─────────
        let card2 = createCardView(frame: NSRect(x: 24, y: 230, width: 552, height: 110))
        
        let card2Title = createSectionHeader(title: "Frequency & Notifications", iconName: "clock.fill", frame: NSRect(x: 16, y: 75, width: 520, height: 22))
        card2.addSubview(card2Title)
        
        let intervalLabel = NSTextField(labelWithString: "Background Check Interval:")
        intervalLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        intervalLabel.frame = NSRect(x: 20, y: 44, width: 220, height: 20)
        card2.addSubview(intervalLabel)
        
        intervalPopUp = NSPopUpButton(frame: NSRect(x: 245, y: 41, width: 285, height: 26))
        intervalPopUp.addItems(withTitles: ["5 Minutes", "15 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours", "6 Hours"])
        card2.addSubview(intervalPopUp)
        
        let dismissLabel = NSTextField(labelWithString: "Alert Box Auto-Dismiss:")
        dismissLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        dismissLabel.frame = NSRect(x: 20, y: 12, width: 220, height: 20)
        card2.addSubview(dismissLabel)
        
        dismissPopUp = NSPopUpButton(frame: NSRect(x: 245, y: 9, width: 285, height: 26))
        dismissPopUp.addItems(withTitles: ["10 Seconds", "30 Seconds", "1 Minute", "3 Minutes", "5 Minutes", "10 Minutes", "Do Not Auto-Dismiss"])
        card2.addSubview(dismissPopUp)
        
        contentView.addSubview(card2)
        
        // ── Card 3: Daily Digest Schedule (y: 110, height: 105) ──────
        let card3 = createCardView(frame: NSRect(x: 24, y: 110, width: 552, height: 105))
        
        let card3Title = createSectionHeader(title: "Daily Digest Schedule", iconName: "calendar", frame: NSRect(x: 16, y: 72, width: 520, height: 22))
        card3.addSubview(card3Title)
        
        dailyCheckCheckbox = NSButton(checkboxWithTitle: "Enable Daily Check at:", target: self, action: #selector(dailyCheckToggled))
        dailyCheckCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        dailyCheckCheckbox.frame = NSRect(x: 20, y: 40, width: 175, height: 22)
        card3.addSubview(dailyCheckCheckbox)
        
        timePopUp = NSPopUpButton(frame: NSRect(x: 200, y: 37, width: 330, height: 26))
        timePopUp.addItems(withTitles: timeOptions.map { $0.title })
        card3.addSubview(timePopUp)
        
        let startX: CGFloat = 200
        let btnWidth: CGFloat = 43
        for (idx, dName) in dayNames.enumerated() {
            let btn = NSButton(title: dName, target: self, action: #selector(dayButtonToggled))
            btn.frame = NSRect(x: startX + CGFloat(idx) * (btnWidth + 4), y: 8, width: btnWidth, height: 24)
            btn.setButtonType(.pushOnPushOff)
            btn.bezelStyle = .recessed
            btn.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            btn.tag = idx
            card3.addSubview(btn)
            dayButtons.append(btn)
        }
        
        contentView.addSubview(card3)
        
        // ── Card 4: System Integration (y: 58, height: 42) ───────────
        let card4 = createCardView(frame: NSRect(x: 24, y: 58, width: 552, height: 42))
        
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Automatically launch Jobs Monitor when starting your Mac", target: self, action: nil)
        launchAtLoginCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        launchAtLoginCheckbox.frame = NSRect(x: 16, y: 10, width: 520, height: 22)
        card4.addSubview(launchAtLoginCheckbox)
        
        contentView.addSubview(card4)
        
        // ── Bottom Action Footer ──────────────────────────────────────
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: 360, y: 14, width: 100, height: 32)
        cancelBtn.bezelStyle = .rounded
        contentView.addSubview(cancelBtn)
        
        let saveBtn = NSButton(title: "Save Settings", target: self, action: #selector(saveClicked))
        saveBtn.frame = NSRect(x: 465, y: 14, width: 112, height: 32)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        contentView.addSubview(saveBtn)
    }

    func createCardView(frame: NSRect) -> NSView {
        let card = NSView(frame: frame)
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.layer?.cornerRadius = 10
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.cgColor
        return card
    }

    func createSectionHeader(title: String, iconName: String, frame: NSRect) -> NSView {
        let header = NSView(frame: frame)
        let iconView = NSImageView(frame: NSRect(x: 0, y: 1, width: 18, height: 18))
        iconView.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        iconView.contentTintColor = .labelColor
        header.addSubview(iconView)
        
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        label.frame = NSRect(x: 24, y: 0, width: frame.width - 24, height: 20)
        header.addSubview(label)
        return header
    }

    @objc func cancelClicked() {
        window?.close()
    }
    
    @objc func radioChanged(_ sender: NSButton) {
        radioCountry.state = (sender.tag == 0) ? .on : .off
        radioCity.state = (sender.tag == 1) ? .on : .off
        radioCustom.state = (sender.tag == 2) ? .on : .off
        
        countryPopUp.isEnabled = (sender.tag == 0)
        cityPopUp.isEnabled = (sender.tag == 1)
        customUrlField.isEnabled = (sender.tag == 2)
    }
    
    @objc func dailyCheckToggled(_ sender: NSButton) {
        let enabled = (sender.state == .on)
        timePopUp.isEnabled = enabled
        for btn in dayButtons {
            btn.isEnabled = enabled
        }
    }
    
    @objc func dayButtonToggled(_ sender: NSButton) {
        // Toggle visual state
    }
    
    func loadCurrentValues() {
        let s = loadSettings()
        radioCountry.state = (s.locationMode == 0) ? .on : .off
        radioCity.state = (s.locationMode == 1) ? .on : .off
        radioCustom.state = (s.locationMode == 2) ? .on : .off
        
        countryPopUp.isEnabled = (s.locationMode == 0)
        cityPopUp.isEnabled = (s.locationMode == 1)
        customUrlField.isEnabled = (s.locationMode == 2)
        
        countryPopUp.selectItem(at: (s.countryIndex >= 0 && s.countryIndex < countryPresets.count) ? s.countryIndex : 0)
        cityPopUp.selectItem(at: (s.cityIndex >= 0 && s.cityIndex < cityPresets.count) ? s.cityIndex : 0)
        
        customUrlField.stringValue = s.customUrl
        
        switch s.checkIntervalMinutes {
        case 5: intervalPopUp.selectItem(at: 0)
        case 15: intervalPopUp.selectItem(at: 1)
        case 30: intervalPopUp.selectItem(at: 2)
        case 60: intervalPopUp.selectItem(at: 3)
        case 240: intervalPopUp.selectItem(at: 5)
        case 360: intervalPopUp.selectItem(at: 6)
        default: intervalPopUp.selectItem(at: 4)
        }
        
        switch s.popupDismissSeconds {
        case 10: dismissPopUp.selectItem(at: 0)
        case 30: dismissPopUp.selectItem(at: 1)
        case 60: dismissPopUp.selectItem(at: 2)
        case 180: dismissPopUp.selectItem(at: 3)
        case 600: dismissPopUp.selectItem(at: 5)
        case 0: dismissPopUp.selectItem(at: 6)
        default: dismissPopUp.selectItem(at: 4)
        }
        
        dailyCheckCheckbox.state = s.enableDailyCheck ? .on : .off
        timePopUp.isEnabled = s.enableDailyCheck
        
        let h = s.dailyCheckHour
        let m = s.dailyCheckMinute
        var matchIdx = 20
        for (idx, opt) in timeOptions.enumerated() {
            if opt.hour == h && abs(opt.minute - m) < 15 {
                matchIdx = idx
                break
            }
        }
        timePopUp.selectItem(at: matchIdx)
        
        let days = s.activeDays.count == 7 ? s.activeDays : [false, true, true, true, true, true, false]
        for (idx, btn) in dayButtons.enumerated() {
            btn.state = days[idx] ? .on : .off
            btn.isEnabled = s.enableDailyCheck
        }
        
        launchAtLoginCheckbox.state = s.launchAtLogin ? .on : .off
    }
    
    @objc func saveClicked() {
        var s = loadSettings()
        if radioCountry.state == .on { s.locationMode = 0 }
        else if radioCity.state == .on { s.locationMode = 1 }
        else if radioCustom.state == .on { s.locationMode = 2 }
        
        s.countryIndex = countryPopUp.indexOfSelectedItem
        s.cityIndex = cityPopUp.indexOfSelectedItem
        s.customUrl = customUrlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch intervalPopUp.indexOfSelectedItem {
        case 0: s.checkIntervalMinutes = 5
        case 1: s.checkIntervalMinutes = 15
        case 2: s.checkIntervalMinutes = 30
        case 3: s.checkIntervalMinutes = 60
        case 5: s.checkIntervalMinutes = 240
        case 6: s.checkIntervalMinutes = 360
        default: s.checkIntervalMinutes = 120
        }
        
        switch dismissPopUp.indexOfSelectedItem {
        case 0: s.popupDismissSeconds = 10
        case 1: s.popupDismissSeconds = 30
        case 2: s.popupDismissSeconds = 60
        case 3: s.popupDismissSeconds = 180
        case 5: s.popupDismissSeconds = 600
        case 6: s.popupDismissSeconds = 0
        default: s.popupDismissSeconds = 300
        }
        
        s.enableDailyCheck = (dailyCheckCheckbox.state == .on)
        let selectedTimeOpt = timeOptions[max(0, min(timePopUp.indexOfSelectedItem, timeOptions.count - 1))]
        s.dailyCheckHour = selectedTimeOpt.hour
        s.dailyCheckMinute = selectedTimeOpt.minute
        s.activeDays = dayButtons.map { $0.state == .on }
        
        let launchLogin = (launchAtLoginCheckbox.state == .on)
        s.launchAtLogin = launchLogin
        configureLaunchAtLogin(enabled: launchLogin)
        
        saveSettings(s)
        window?.close()
        onSave?()
    }
}

// ── Main App Delegate (Menu Bar App) ───────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var dailyTimer: Timer?
    var settingsWindowController: SettingsWindowController?
    var aboutWindowController: AboutWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logMessage(" Jobs Monitor App Starting...")
        
        let settings = loadSettings()
        configureLaunchAtLogin(enabled: settings.launchAtLogin)
        
        // Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let state = loadStateData()
        updateBadge(unreadCount: state.unread_count ?? 0)
        
        rebuildMenu()
        scheduleTimer()
        scheduleDailyTimer()
        
        // Initial job check & background update check
        performCheck(isManual: false)
        checkForUpdates(silentIfCurrent: true)
        
        // First Launch: Automatically open Preferences Window
        let firstLaunchKey = "has_launched_jobsmonitor"
        if !UserDefaults.standard.bool(forKey: firstLaunchKey) {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.openPreferences()
            }
        }
    }
    
    func updateBadge(unreadCount: Int) {
        if let button = statusItem.button {
            let menuImg = createVectorMenuIcon()
            button.image = menuImg
            button.imagePosition = .imageLeft
            
            if unreadCount > 99 {
                button.title = " (99+ new)"
            } else if unreadCount > 0 {
                button.title = " (\(unreadCount) new)"
            } else {
                button.title = ""
            }
            button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        }
    }
    
    func rebuildMenu() {
        let menu = NSMenu()
        let state = loadStateData()
        
        // Title Item with Icon
        let titleItem = NSMenuItem(title: "Jobs Monitor v\(APP_VERSION)", action: nil, keyEquivalent: "")
        titleItem.image = NSImage(systemSymbolName: "apple.logo", accessibilityDescription: nil)
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // Last Checked Time Item with Clock Icon
        let lastCheckedText = state.last_checked_str ?? "Just now"
        let checkTimeItem = NSMenuItem(title: "Last Checked: \(lastCheckedText)", action: nil, keyEquivalent: "")
        checkTimeItem.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil)
        checkTimeItem.isEnabled = false
        menu.addItem(checkTimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check Now Item with Icon
        let checkNowItem = NSMenuItem(title: "Check Jobs Now", action: #selector(checkNowClicked), keyEquivalent: "r")
        checkNowItem.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        checkNowItem.target = self
        menu.addItem(checkNowItem)
        
        // View Dashboard Item with Icon
        let viewDashItem = NSMenuItem(title: "View Dashboard", action: #selector(viewDashboardClicked), keyEquivalent: "d")
        viewDashItem.image = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: nil)
        viewDashItem.target = self
        menu.addItem(viewDashItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check for Updates Item with Icon
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(manualUpdateCheck), keyEquivalent: "u")
        updateItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle.fill", accessibilityDescription: nil)
        updateItem.target = self
        menu.addItem(updateItem)
        
        // Preferences Item with Icon
        let prefItem = NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        prefItem.target = self
        menu.addItem(prefItem)
        
        // About Item with Icon
        let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "i")
        aboutItem.image = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: nil)
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit Item with Icon
        let quitItem = NSMenuItem(title: "Quit Monitor", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func manualUpdateCheck() {
        checkForUpdates(silentIfCurrent: false)
    }
    
    func checkForUpdates(silentIfCurrent: Bool) {
        guard let url = URL(string: VERSION_CHECK_URL) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let remoteVersion = json["version"] as? String else {
                if !silentIfCurrent {
                    DispatchQueue.main.async {
                        self.showUpdateAlert(remoteVersion: nil, changelog: "", isNewer: false)
                    }
                }
                return
            }
            
            var notes = ""
            if let changelogs = json["changelog"] as? [[String: Any]],
               let match = changelogs.first(where: { ($0["version"] as? String) == remoteVersion }),
               let changes = match["changes"] as? [String] {
                notes = changes.map { "• \($0)" }.joined(separator: "\n")
            }
            
            let isNewer = self.compareVersions(remote: remoteVersion, current: APP_VERSION)
            DispatchQueue.main.async {
                self.showUpdateAlert(remoteVersion: remoteVersion, changelog: notes, isNewer: isNewer)
            }
        }
        task.resume()
    }
    
    func compareVersions(remote: String, current: String) -> Bool {
        let rParts = remote.components(separatedBy: ".").compactMap { Int($0) }
        let cParts = current.components(separatedBy: ".").compactMap { Int($0) }
        
        for i in 0..<max(rParts.count, cParts.count) {
            let r = i < rParts.count ? rParts[i] : 0
            let c = i < cParts.count ? cParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
    
    func showUpdateAlert(remoteVersion: String?, changelog: String, isNewer: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            alert.icon = img
        }
        
        if isNewer, let ver = remoteVersion {
            alert.messageText = " Update Available: Jobs Monitor v\(ver)"
            alert.informativeText = "A new version of Jobs Monitor is available!\n\nWhat's New in v\(ver):\n\(changelog)\n\nClick \"Update Now\" to download and install automatically."
            alert.addButton(withTitle: "Update Now")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                downloadAndInstallUpdate()
            }
        } else {
            alert.messageText = " You're Up to Date!"
            alert.informativeText = "Jobs Monitor v\(APP_VERSION) is currently the latest version available."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func downloadAndInstallUpdate() {
        guard let url = URL(string: COMMAND_DOWNLOAD_URL) else { return }
        
        let progressAlert = NSAlert()
        progressAlert.messageText = "Downloading Update…"
        progressAlert.informativeText = "Fetching the latest installer from GitHub. This will only take a moment."
        progressAlert.addButton(withTitle: "Cancel")
        
        var cancelled = false
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            DispatchQueue.main.async {
                NSApp.abortModal()
                
                guard !cancelled else { return }
                
                if let error = error {
                    let err = NSAlert()
                    err.alertStyle = .warning
                    err.messageText = "Download Failed"
                    err.informativeText = "Could not download the update:\n\(error.localizedDescription)\n\nPlease check your internet connection and try again."
                    err.addButton(withTitle: "OK")
                    err.runModal()
                    return
                }
                
                guard let tempURL = tempURL else { return }
                
                let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                let destURL = downloadsDir.appendingPathComponent("install-jobsmonitor.command")
                
                try? FileManager.default.removeItem(at: destURL)
                do {
                    try FileManager.default.copyItem(at: tempURL, to: destURL)
                    try FileManager.default.setAttributes(
                        [.posixPermissions: NSNumber(value: 0o755)],
                        ofItemAtPath: destURL.path
                    )
                    // .command files auto-run when opened — launches in Terminal.app
                    NSWorkspace.shared.open(destURL)
                } catch {
                    let err = NSAlert()
                    err.alertStyle = .warning
                    err.messageText = "Could Not Save Installer"
                    err.informativeText = "The installer was downloaded but couldn't be saved:\n\(error.localizedDescription)"
                    err.addButton(withTitle: "OK")
                    err.runModal()
                }
            }
        }
        task.resume()
        
        let result = progressAlert.runModal()
        if result == .alertFirstButtonReturn {
            cancelled = true
            task.cancel()
        }
    }
    
    func scheduleTimer() {
        timer?.invalidate()
        let settings = loadSettings()
        let intervalSeconds = Double(settings.checkIntervalMinutes * 60)
        
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.performCheck(isManual: false)
        }
    }
    
    func scheduleDailyTimer() {
        dailyTimer?.invalidate()
        let settings = loadSettings()
        guard settings.enableDailyCheck else { return }
        
        let targetHour = settings.dailyCheckHour
        let targetMinute = settings.dailyCheckMinute
        let activeDays = settings.activeDays.count == 7 ? settings.activeDays : [false, true, true, true, true, true, false]
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let now = Date()
        var foundDate: Date? = nil
        
        for dayOffset in 0..<14 {
            guard let testDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            var comp = calendar.dateComponents([.year, .month, .day, .weekday], from: testDate)
            comp.hour = targetHour
            comp.minute = targetMinute
            comp.second = 0
            
            if let scheduledCandidate = calendar.date(from: comp) {
                let dayIndex = (comp.weekday ?? 1) - 1
                if activeDays[dayIndex] && scheduledCandidate > now {
                    foundDate = scheduledCandidate
                    break
                }
            }
        }
        
        guard let nextDate = foundDate else { return }
        let timeInterval = nextDate.timeIntervalSince(now)
        logMessage("Scheduled Daily Digest Check for \(DateFormatter.localizedString(from: nextDate, dateStyle: .short, timeStyle: .short))")
        
        dailyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.performCheck(isManual: true)
            self?.scheduleDailyTimer()
        }
    }
    
    @objc func checkNowClicked() {
        performCheck(isManual: true)
    }
    
    @objc func viewDashboardClicked() {
        var state = loadStateData()
        state.unread_count = 0
        saveStateData(state)
        updateBadge(unreadCount: 0)
        
        if FileManager.default.fileExists(atPath: dashboardFile.path) {
            NSWorkspace.shared.open(dashboardFile)
        } else {
            performCheck(isManual: true)
        }
    }
    
    @objc func openPreferences() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
            settingsWindowController?.onSave = { [weak self] in
                self?.rebuildMenu()
                self?.scheduleTimer()
                self?.scheduleDailyTimer()
                self?.performCheck(isManual: true)
            }
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    func performCheck(isManual: Bool) {
        let settings = loadSettings()
        guard let url = URL(string: settings.activeUrl) else { return }
        
        logMessage("Fetching roles for \(settings.locationTitle)...")
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                logMessage("Fetch error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            let jobs = parseJobsFromHTML(html, defaultSearchUrl: settings.activeUrl)
            logMessage("Fetched \(jobs.count) roles for \(settings.locationTitle)")
            
            var state = loadStateData()
            let isFirstRun = state.seen_ids.isEmpty
            let seenSet = Set(state.seen_ids)
            
            let newJobs = isFirstRun ? [] : jobs.filter { !seenSet.contains($0.id) }
            
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            state.last_checked_str = timeStr
            state.last_job_count = jobs.count
            
            DispatchQueue.main.async {
                let currentUnread = (state.unread_count ?? 0) + newJobs.count
                state.unread_count = currentUnread
                self.updateBadge(unreadCount: currentUnread)
                self.rebuildMenu()
                
                let greeting = "Hi Arun 👋 — \(jobs.count) active roles currently tracked for <strong>\(settings.locationTitle)</strong>:"
                let htmlStr = generateDashboardHTML(jobs: jobs.isEmpty ? [] : Array(jobs.prefix(20)),
                                                     greeting: greeting,
                                                     subtitle: "\(jobs.count) active openings",
                                                     locationTitle: settings.locationTitle,
                                                     searchUrl: settings.activeUrl)
                
                try? htmlStr.write(to: dashboardFile, atomically: true, encoding: .utf8)
                
                state.seen_ids = Array(Set(state.seen_ids + jobs.map { $0.id }))
                saveStateData(state)
                
                if !newJobs.isEmpty {
                    let plural = newJobs.count > 1 ? "s" : ""
                    self.showNativeAlert(
                        title: " \(newJobs.count) New Apple Job\(plural)!",
                        message: "\(newJobs.count) brand new role\(plural) posted for \(settings.locationTitle)!"
                    )
                } else if isManual {
                    self.showNativeAlert(
                        title: " Jobs Monitor (\(settings.locationTitle))",
                        message: "No new openings since last check. Dashboard is ready with latest \(jobs.count) roles!"
                    )
                }
            }
        }
        task.resume()
    }
    
    func showNativeAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "View Dashboard")
        alert.addButton(withTitle: "Dismiss")
        
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Users/arunthomas/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            alert.icon = img
        }
        
        let settings = loadSettings()
        if settings.popupDismissSeconds > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(settings.popupDismissSeconds)) {
                if let window = alert.window.sheetParent ?? NSApp.windows.first(where: { $0.title == title }) {
                    window.close()
                }
            }
        }
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            var state = loadStateData()
            state.unread_count = 0
            saveStateData(state)
            updateBadge(unreadCount: 0)
            rebuildMenu()
            NSWorkspace.shared.open(dashboardFile)
        }
    }
}

// ── Application Main (Single-Instance Kernel Lock) ──────────────────────────────
try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
let lockFilePath = appDir.appendingPathComponent("app.lock").path
let lockFd = open(lockFilePath, O_CREAT | O_RDWR, 0o666)
if lockFd < 0 || flock(lockFd, LOCK_EX | LOCK_NB) != 0 {
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

