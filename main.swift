import AppKit
import Foundation
import ServiceManagement
import SwiftUI
import UserNotifications
import WebKit

// ── Global Single-Source Constants ─────────────────────────────────────────────
let APP_VERSION = "2.2.6"
let CONTACT_EMAIL = "arunthomashyd@gmail.com"
let GITHUB_REPO_URL = "https://github.com/arunofhyd/JobsMonitor"
let VERSION_CHECK_URL = "https://raw.githubusercontent.com/arunofhyd/JobsMonitor/main/version.json"
let LATEST_RELEASE_URL = "https://github.com/arunofhyd/JobsMonitor/releases/latest"
let COMMAND_DOWNLOAD_URL = "https://raw.githubusercontent.com/arunofhyd/JobsMonitor/refs/heads/main/install-jobsmonitor.command"

let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("JobsMonitor")
let stateFile = appDir.appendingPathComponent("seen_jobs.json")
let settingsFile = appDir.appendingPathComponent("settings.json")
let dashboardFile = appDir.appendingPathComponent("JobsMonitor_dash.html")
let logFile = appDir.appendingPathComponent("monitor.log")

func createChangelogView(changelog: String) -> NSView {
    let container = NSBox(frame: NSRect(x: 0, y: 0, width: 340, height: 140))
    container.boxType = .custom
    container.isTransparent = false
    container.fillColor = NSColor.controlBackgroundColor
    container.borderColor = NSColor.separatorColor.withAlphaComponent(0.3)
    container.borderWidth = 1
    container.cornerRadius = 8
    
    let scrollView = NSScrollView(frame: NSRect(x: 4, y: 4, width: 332, height: 132))
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false
    scrollView.wantsLayer = true
    
    let contentSize = scrollView.contentSize
    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height))
    textView.minSize = NSSize(width: 0.0, height: contentSize.height)
    textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = false
    textView.autoresizingMask = [.width]
    textView.textContainer?.containerSize = NSSize(width: contentSize.width - 12, height: CGFloat.greatestFiniteMagnitude)
    textView.textContainer?.widthTracksTextView = true
    textView.textContainerInset = NSSize(width: 6, height: 6)
    textView.isEditable = false
    textView.isSelectable = true
    textView.drawsBackground = false
    
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineSpacing = 3
    
    let attrStr = NSAttributedString(string: changelog, attributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .regular),
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: paraStyle
    ])
    textView.textStorage?.setAttributedString(attrStr)
    
    scrollView.documentView = textView
    container.addSubview(scrollView)
    return container
}

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

struct SoundOption {
    let title: String
    let nameOrPath: String
}

let availableSounds: [SoundOption] = [
    SoundOption(title: "None", nameOrPath: ""),
    
    // ── Classic macOS System Sounds ──────────────────────────────────────────
    SoundOption(title: "Glass", nameOrPath: "Glass"),
    SoundOption(title: "Ping", nameOrPath: "Ping"),
    SoundOption(title: "Pop", nameOrPath: "Pop"),
    SoundOption(title: "Blow", nameOrPath: "Blow"),
    SoundOption(title: "Bottle", nameOrPath: "Bottle"),
    SoundOption(title: "Frog", nameOrPath: "Frog"),
    SoundOption(title: "Funk", nameOrPath: "Funk"),
    SoundOption(title: "Hero", nameOrPath: "Hero"),
    SoundOption(title: "Morse", nameOrPath: "Morse"),
    SoundOption(title: "Purr", nameOrPath: "Purr"),
    SoundOption(title: "Sosumi", nameOrPath: "Sosumi"),
    SoundOption(title: "Submarine", nameOrPath: "Submarine"),
    SoundOption(title: "Tink", nameOrPath: "Tink"),
    SoundOption(title: "Basso", nameOrPath: "Basso"),
    
    // ── Modern iOS / macOS Alert Tones ────────────────────────────────────────
    SoundOption(title: "Aurora", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Aurora.m4r"),
    SoundOption(title: "Bamboo", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Bamboo.m4r"),
    SoundOption(title: "Chord", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Chord.m4r"),
    SoundOption(title: "Circles", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Circles.m4r"),
    SoundOption(title: "Complete", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Complete.m4r"),
    SoundOption(title: "Hello", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Hello.m4r"),
    SoundOption(title: "Input", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Input.m4r"),
    SoundOption(title: "Keys", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Keys.m4r"),
    SoundOption(title: "Note", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Note.m4r"),
    SoundOption(title: "Popcorn", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Popcorn.m4r"),
    SoundOption(title: "Pulse", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Pulse.m4r"),
    SoundOption(title: "Synth", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Synth.m4r"),

    // ── Classic Apple Alert Tones ─────────────────────────────────────────────
    SoundOption(title: "Tri-Tone", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Tri-Tone.m4r"),
    SoundOption(title: "Alert", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Alert.m4r"),
    SoundOption(title: "Anticipate", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Anticipate.m4r"),
    SoundOption(title: "Bell", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Bell.m4r"),
    SoundOption(title: "Bloom", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Bloom.m4r"),
    SoundOption(title: "Calypso", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Calypso.m4r"),
    SoundOption(title: "Chime", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Chime.m4r"),
    SoundOption(title: "Choo Choo", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Choo Choo.m4r"),
    SoundOption(title: "Descent", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Descent.m4r"),
    SoundOption(title: "Ding", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Ding.m4r"),
    SoundOption(title: "Electronic", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Electronic.m4r"),
    SoundOption(title: "Fanfare", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Fanfare.m4r"),
    SoundOption(title: "Horn", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Horn.m4r"),
    SoundOption(title: "Ladder", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Ladder.m4r"),
    SoundOption(title: "Minuet", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Minuet.m4r"),
    SoundOption(title: "News Flash", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/News Flash.m4r"),
    SoundOption(title: "Noir", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Noir.m4r"),
    SoundOption(title: "Sherwood Forest", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Sherwood Forest.m4r"),
    SoundOption(title: "Spell", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Spell.m4r"),
    SoundOption(title: "Suspense", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Suspense.m4r"),
    SoundOption(title: "Swish", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Swish.m4r"),
    SoundOption(title: "Swoosh", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Swoosh.m4r"),
    SoundOption(title: "Telegraph", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Telegraph.m4r"),
    SoundOption(title: "Tiptoes", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Tiptoes.m4r"),
    SoundOption(title: "Tweet", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Tweet.m4r"),
    SoundOption(title: "Typewriters", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Typewriters.m4r"),
    SoundOption(title: "Update", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Classic/Update.m4r"),
    
    // ── Haptic & Expressive Tones ─────────────────────────────────────────────
    SoundOption(title: "Droplet", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Droplet-EncoreInfinitum.caf"),
    SoundOption(title: "Antic", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Antic-EncoreInfinitum.caf"),
    SoundOption(title: "Cheers", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Cheers-EncoreInfinitum.caf"),
    SoundOption(title: "Handoff", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Handoff-EncoreInfinitum.caf"),
    SoundOption(title: "Milestone", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Milestone-EncoreInfinitum.caf"),
    SoundOption(title: "Passage", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Passage-EncoreInfinitum.caf"),
    SoundOption(title: "Portal", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Portal-EncoreInfinitum.caf"),
    SoundOption(title: "Rattle", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Rattle-EncoreInfinitum.caf"),
    SoundOption(title: "Rebound", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Rebound-EncoreInfinitum.caf"),
    SoundOption(title: "Slide", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Slide-EncoreInfinitum.caf"),
    SoundOption(title: "Welcome", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Welcome-EncoreInfinitum.caf"),

    // ── Iconic Ringtones ──────────────────────────────────────────────────────
    SoundOption(title: "Reflection", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Reflection.m4r"),
    SoundOption(title: "Radar", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Radar.m4r"),
    SoundOption(title: "Apex", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Apex.m4r"),
    SoundOption(title: "Beacon", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Beacon.m4r"),
    SoundOption(title: "Bulletin", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Bulletin.m4r"),
    SoundOption(title: "Chimes", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Chimes.m4r"),
    SoundOption(title: "Circuit", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Circuit.m4r"),
    SoundOption(title: "Constellation", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Constellation.m4r"),
    SoundOption(title: "Cosmic", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Cosmic.m4r"),
    SoundOption(title: "Crystals", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Crystals.m4r"),
    SoundOption(title: "Hillside", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Hillside.m4r"),
    SoundOption(title: "Illuminate", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Illuminate.m4r"),
    SoundOption(title: "Marimba", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Marimba.m4r"),
    SoundOption(title: "Night Owl", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Night Owl.m4r"),
    SoundOption(title: "Opening", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Opening.m4r"),
    SoundOption(title: "Playtime", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Playtime.m4r"),
    SoundOption(title: "Radiate", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Radiate.m4r"),
    SoundOption(title: "Ripples", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Ripples.m4r"),
    SoundOption(title: "Sencha", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Sencha.m4r"),
    SoundOption(title: "Signal", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Signal.m4r"),
    SoundOption(title: "Silk", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Silk.m4r"),
    SoundOption(title: "Slow Rise", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Slow Rise.m4r"),
    SoundOption(title: "Stargaze", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Stargaze.m4r"),
    SoundOption(title: "Summit", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Summit.m4r"),
    SoundOption(title: "Twinkle", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Twinkle.m4r"),
    SoundOption(title: "Uplift", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Uplift.m4r"),
    SoundOption(title: "Waves", nameOrPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Waves.m4r")
]

private var activeSound: NSSound?

func stopNotificationSound() {
    activeSound?.stop()
    activeSound = nil
}

func playNotificationSound(_ nameOrPath: String, volume: Float = 1.0) {
    stopNotificationSound()
    guard !nameOrPath.isEmpty else { return }
    let vol = max(0.0, min(1.0, volume))
    if nameOrPath.hasPrefix("/") {
        if let sound = NSSound(contentsOfFile: nameOrPath, byReference: true) {
            sound.volume = vol
            activeSound = sound
            sound.play()
        }
    } else {
        if let sound = NSSound(named: NSSound.Name(nameOrPath)) {
            sound.volume = vol
            activeSound = sound
            sound.play()
        }
    }
}

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
    var checkIntervalMinutes: Int // 5, 15, 30, 60, 120, 240, 360, 720, 1440
    var popupDismissSeconds: Int // 10, 30, 60, 180, 300, 600, 0
    var notificationSound: String // system sound name, or "" for none
    var notificationVolume: Float // 0.0 to 1.0 (default 1.0)
    var notificationStyle: Int // 0: System Side Notification (Banner), 1: Mid-Screen Window (Popup Alert - Default)
    var enableDailyCheck: Bool
    var dailyCheckHour: Int // 0..23
    var dailyCheckMinute: Int // 0..59
    var activeDays: [Bool] // 7 booleans for [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
    var launchAtLogin: Bool
    var enableInternalMode: Bool
    var internalOnly: Bool
    
    enum CodingKeys: String, CodingKey {
        case locationMode, countryIndex, cityIndex, customUrl, checkIntervalMinutes, popupDismissSeconds, notificationSound, notificationVolume, notificationStyle, enableDailyCheck, dailyCheckHour, dailyCheckMinute, activeDays, launchAtLogin, enableInternalMode, internalOnly
    }
    
    init(locationMode: Int, countryIndex: Int, cityIndex: Int, customUrl: String, checkIntervalMinutes: Int, popupDismissSeconds: Int, notificationSound: String, notificationVolume: Float = 1.0, notificationStyle: Int = 1, enableDailyCheck: Bool, dailyCheckHour: Int, dailyCheckMinute: Int, activeDays: [Bool], launchAtLogin: Bool, enableInternalMode: Bool = false, internalOnly: Bool = false) {
        self.locationMode = locationMode
        self.countryIndex = countryIndex
        self.cityIndex = cityIndex
        self.customUrl = customUrl
        self.checkIntervalMinutes = checkIntervalMinutes
        self.popupDismissSeconds = popupDismissSeconds
        self.notificationSound = notificationSound
        self.notificationVolume = notificationVolume
        self.notificationStyle = notificationStyle
        self.enableDailyCheck = enableDailyCheck
        self.dailyCheckHour = dailyCheckHour
        self.dailyCheckMinute = dailyCheckMinute
        self.activeDays = activeDays
        self.launchAtLogin = launchAtLogin
        self.enableInternalMode = enableInternalMode
        self.internalOnly = internalOnly
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locationMode = try container.decodeIfPresent(Int.self, forKey: .locationMode) ?? 0
        countryIndex = try container.decodeIfPresent(Int.self, forKey: .countryIndex) ?? 0
        cityIndex = try container.decodeIfPresent(Int.self, forKey: .cityIndex) ?? 0
        customUrl = try container.decodeIfPresent(String.self, forKey: .customUrl) ?? "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest"
        checkIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .checkIntervalMinutes) ?? 120
        popupDismissSeconds = try container.decodeIfPresent(Int.self, forKey: .popupDismissSeconds) ?? 300
        notificationSound = try container.decodeIfPresent(String.self, forKey: .notificationSound) ?? "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Bulletin.m4r"
        notificationVolume = try container.decodeIfPresent(Float.self, forKey: .notificationVolume) ?? 1.0
        notificationStyle = try container.decodeIfPresent(Int.self, forKey: .notificationStyle) ?? 1
        enableDailyCheck = try container.decodeIfPresent(Bool.self, forKey: .enableDailyCheck) ?? true
        dailyCheckHour = try container.decodeIfPresent(Int.self, forKey: .dailyCheckHour) ?? 10
        dailyCheckMinute = try container.decodeIfPresent(Int.self, forKey: .dailyCheckMinute) ?? 0
        activeDays = try container.decodeIfPresent([Bool].self, forKey: .activeDays) ?? [false, true, true, true, true, true, false]
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? true
        enableInternalMode = try container.decodeIfPresent(Bool.self, forKey: .enableInternalMode) ?? false
        internalOnly = try container.decodeIfPresent(Bool.self, forKey: .internalOnly) ?? false
    }
    
    static var defaultConfig: AppSettings {
        return AppSettings(
            locationMode: 0,
            countryIndex: 0,
            cityIndex: 0,
            customUrl: "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest",
            checkIntervalMinutes: 120,
            popupDismissSeconds: 300,
            notificationSound: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones/Bulletin.m4r",
            notificationVolume: 1.0,
            notificationStyle: 1,
            enableDailyCheck: true,
            dailyCheckHour: 10,
            dailyCheckMinute: 0,
            activeDays: [false, true, true, true, true, true, false],
            launchAtLogin: true,
            enableInternalMode: false,
            internalOnly: false
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
    
    var activeCareersUrl: String {
        return activeUrl.replacingOccurrences(of: "jobs.apple.com", with: "careers.apple.com")
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
        let execPath = "/Applications/JobsMonitor.app/Contents/MacOS/JobsMonitor"
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
    var countries: [String]? = []
    var cities: [String]? = []
    var isInternal: Bool? = false
}

struct StateData: Codable {
    var seen_ids: [String]
    var unread_count: Int?
    var last_job_count: Int?
    var last_checked_str: String?
    var last_daily_popup: String?
    var last_popup_time: String?
    var last_check_timestamp: Double?
    var isAppleConnectAuthenticated: Bool?
    var ssoSessionExpired: Bool?
    var hasEverAuthenticatedInternal: Bool?
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

func getUserFirstName() -> String {
    let fullName = NSFullUserName()
    let firstName = fullName.components(separatedBy: " ").first ?? ""
    return firstName.isEmpty ? "There" : firstName
}

// ── HTML Dashboard Generator ───────────────────────────────────────────────────
func generateDashboardHTML(
    jobs: [JobItem],
    internalIdSet: Set<String>,
    publicIdSet: Set<String>,
    internalTotalCount: Int,
    publicTotalCount: Int,
    enableInternalMode: Bool,
    internalOnly: Bool,
    greeting: String,
    locationTitle: String,
    publicSearchUrl: String,
    careersSearchUrl: String
) -> String {
    let totalCount = jobs.count
    
    var rows = ""
    for j in jobs {
        let inInternal = internalIdSet.contains(j.id) || (j.isInternal == true)
        let inPublic = publicIdSet.contains(j.id)
        
        let internalUrl = j.url.replacingOccurrences(of: "jobs.apple.com", with: "careers.apple.com")
        let publicUrl = j.url.replacingOccurrences(of: "careers.apple.com", with: "jobs.apple.com")
        let primaryUrl = inInternal ? internalUrl : publicUrl
        
        let groupFilledIconSvg = "<svg class=\"portal-icon\" viewBox=\"0 0 16 16\" fill=\"currentColor\"><path d=\"M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z\"/></svg>"
        
        let portalHtml: String
        if inInternal && !inPublic {
            // Scenario 1: Exclusive to AppleConnect Internal Portal
            portalHtml = "<a href=\"\(internalUrl)\" class=\"portal-badge portal-internal\" target=\"_blank\"> Internal ↗</a>"
        } else if inInternal && inPublic {
            // Scenario 2: Listed on Both Internal & Public
            portalHtml = "<div class=\"portal-badge-group\"><a href=\"\(internalUrl)\" class=\"portal-badge portal-internal\" target=\"_blank\"> Internal ↗</a><a href=\"\(publicUrl)\" class=\"portal-badge portal-public\" target=\"_blank\">\(groupFilledIconSvg)Public ↗</a></div>"
        } else {
            // Scenario 3: Public Only
            portalHtml = "<a href=\"\(publicUrl)\" class=\"portal-badge portal-public\" target=\"_blank\">\(groupFilledIconSvg)Public ↗</a>"
        }
        
        rows += """
        <tr data-internal="\(inInternal)" data-public="\(inPublic)" data-both="true">
          <td class="cell">
            <a href="\(primaryUrl)" class="job-link" target="_blank">\(j.title)</a>
            <br><span class="text-muted">\(j.team)</span>
          </td>
          <td class="cell text-muted">\(j.posted.isEmpty ? "—" : j.posted)</td>
          <td class="cell">\(j.location)</td>
          <td class="cell" style="text-align:right; padding-right: 12px;">
            \(portalHtml)
          </td>
        </tr>
        """
    }
    
    let nowStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
    
    let groupFilledIconSvg = "<svg class=\"portal-icon\" viewBox=\"0 0 16 16\" fill=\"currentColor\"><path d=\"M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z\"/></svg>"
    
    var filterBarHtml = ""
    if !enableInternalMode {
        filterBarHtml = """
        <div class="filter-bar">
          <div class="search-box-wrapper">
            <span class="search-icon">🔍</span>
            <input type="text" id="job-search" class="search-input" placeholder="Search roles, teams, locations..." oninput="filterDashboard()" autocomplete="off" spellcheck="false">
            <button class="clear-search-btn" id="clear-search" onclick="clearSearch()" style="display:none;">✕</button>
          </div>
          <div class="filter-status" id="filter-status">Showing all \(totalCount) public roles</div>
        </div>
        """
    } else if internalOnly {
        filterBarHtml = """
        <div class="filter-bar">
          <div class="search-box-wrapper">
            <span class="search-icon">🔍</span>
            <input type="text" id="job-search" class="search-input" placeholder="Search \(totalCount) internal roles..." oninput="filterDashboard()" autocomplete="off" spellcheck="false">
            <button class="clear-search-btn" id="clear-search" onclick="clearSearch()" style="display:none;">✕</button>
          </div>
          <div class="filter-status" id="filter-status">Showing all \(totalCount)  internal roles</div>
        </div>
        """
    } else {
        filterBarHtml = """
        <div class="filter-bar">
          <div class="filter-group">
            <button class="filter-pill active" onclick="setFilter('all', this)">All <span class="pill-count">\(totalCount)</span></button>
            <button class="filter-pill" onclick="setFilter('internal', this)"> Internal <span class="pill-count">\(internalTotalCount)</span></button>
            <button class="filter-pill" onclick="setFilter('public', this)">\(groupFilledIconSvg)Public <span class="pill-count">\(publicTotalCount)</span></button>
          </div>
          <div class="search-box-wrapper">
            <span class="search-icon">🔍</span>
            <input type="text" id="job-search" class="search-input" placeholder="Search roles, teams, cities..." oninput="filterDashboard()" autocomplete="off" spellcheck="false">
            <button class="clear-search-btn" id="clear-search" onclick="clearSearch()" style="display:none;">✕</button>
          </div>
        </div>
        <div class="filter-status-row">
          <span class="filter-status" id="filter-status">Showing all \(totalCount) roles</span>
        </div>
        """
    }
    
    var footerBannerHtml = ""
    if !enableInternalMode {
        footerBannerHtml = """
        <div style="padding: 20px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border); line-height: 1.8;">
          <strong style="color: var(--text-main);">Job Links:</strong> Clicking any <strong>job title</strong> or <span class="portal-badge portal-public" style="margin: 0 4px; pointer-events: none;">\(groupFilledIconSvg)Public ↗</span> badge opens the role directly on <a href="https://jobs.apple.com" target="_blank" style="color: var(--link); font-weight: 600; text-decoration: none;">jobs.apple.com ↗</a>.
        </div>
        """
    } else if internalOnly {
        footerBannerHtml = """
        <div style="padding: 20px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border); line-height: 1.8;">
          <strong style="color: var(--text-main);">Job Links & Portals:</strong> Clicking any <strong>job title</strong> or <span class="portal-badge portal-internal" style="margin: 0 4px; pointer-events: none;"> Internal ↗</span> badge opens the role directly on <a href="https://careers.apple.com" target="_blank" style="color: #af52de; font-weight: 600; text-decoration: none;">careers.apple.com ↗</a> via AppleConnect SSO.
        </div>
        """
    } else {
        footerBannerHtml = """
        <div style="padding: 22px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border); line-height: 1.8;">
          <div style="font-weight: 600; color: var(--text-main); margin-bottom: 8px;">Portal Badges & Direct Links:</div>
          <div style="margin-bottom: 6px;">
            • <span class="portal-badge portal-internal" style="margin: 0 4px; pointer-events: none;"> Internal ↗</span> Roles available on Apple employee portal at <a href="https://careers.apple.com" target="_blank" style="color: #af52de; font-weight: 600; text-decoration: none;">careers.apple.com ↗</a> (AppleConnect SSO).
          </div>
          <div style="margin-bottom: 6px;">
            • <span class="portal-badge portal-public" style="margin: 0 4px; pointer-events: none;">\(groupFilledIconSvg)Public ↗</span> Roles open on the public jobs site at <a href="https://jobs.apple.com" target="_blank" style="color: var(--link); font-weight: 600; text-decoration: none;">jobs.apple.com ↗</a>.
          </div>
          <div>
            • Roles displaying <strong>both</strong> badges are open across both internal employee and public applicant portals. Click either badge to visit that portal!
          </div>
        </div>
        """
    }
    
    return """
    <!DOCTYPE html>
    <html><head><meta charset="utf-8">
    <title> Jobs Monitor · \(locationTitle)</title>
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
      .content { padding:28px 32px; }
      .greeting { font-size:16px; margin:0 0 20px; }
      
      .filter-bar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin: 16px 0 14px;
        flex-wrap: wrap;
        gap: 12px;
      }
      .filter-group {
        display: inline-flex;
        background: var(--bg-page);
        padding: 4px;
        border-radius: 30px;
        border: 1px solid var(--border);
        gap: 4px;
      }
      .filter-pill {
        background: transparent;
        border: 1px solid transparent;
        padding: 6px 14px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 500;
        color: var(--text-sec);
        cursor: pointer;
        transition: all 0.18s ease-in-out;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        outline: none;
        font-family: inherit;
      }
      .filter-pill:hover {
        color: var(--text-main);
      }
      .filter-pill.active {
        background: var(--bg-card);
        color: var(--text-main);
        font-weight: 600;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        border: 1px solid var(--border);
      }
      .pill-count {
        display: inline-block;
        padding: 1px 7px;
        border-radius: 10px;
        font-size: 11px;
        background: rgba(128,128,128,0.14);
        color: inherit;
        font-weight: 600;
      }
      .filter-pill.active .pill-count {
        background: rgba(128,128,128,0.22);
      }
      
      .search-box-wrapper {
        position: relative;
        display: inline-flex;
        align-items: center;
        min-width: 260px;
        background: var(--bg-page);
        border: 1px solid var(--border);
        border-radius: 20px;
        padding: 0 12px;
        transition: all 0.2s ease;
      }
      .search-box-wrapper:focus-within {
        border-color: var(--link);
        box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.15);
        background: var(--bg-card);
      }
      .search-icon {
        font-size: 13px;
        opacity: 0.6;
        margin-right: 6px;
        user-select: none;
      }
      .search-input {
        border: none;
        background: transparent;
        outline: none;
        font-family: inherit;
        font-size: 13px;
        color: var(--text-main);
        width: 100%;
        padding: 7px 0;
      }
      .search-input::placeholder {
        color: var(--text-sec);
      }
      .clear-search-btn {
        background: transparent;
        border: none;
        color: var(--text-sec);
        cursor: pointer;
        font-size: 12px;
        padding: 0 4px;
        outline: none;
      }
      .clear-search-btn:hover {
        color: var(--text-main);
      }
      
      .filter-status-row {
        margin-bottom: 18px;
      }
      .filter-status {
        font-size: 13px;
        color: var(--text-sec);
      }
      
      table { width:100%; border-collapse:collapse; }
      th { padding:12px 8px; text-align:left; font-size:12px; color:var(--text-sec); text-transform:uppercase; border-bottom:1px solid var(--border); font-weight:600; letter-spacing:0.02em; }
      .cell { padding:16px 8px; border-bottom:1px solid var(--border); font-size:14px; }
      .job-link { color:var(--link); font-weight:600; text-decoration:none; font-size:15px; }
      .job-link:hover { text-decoration:underline; }
      .portal-badge-group {
        display: inline-flex;
        gap: 6px;
        justify-content: flex-end;
        align-items: center;
        flex-wrap: wrap;
      }
      .portal-badge {
        display: inline-flex;
        align-items: center;
        padding: 4px 10px;
        border-radius: 14px;
        font-size: 11px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.18s ease-in-out;
        line-height: 1.3;
        white-space: nowrap;
      }
      .portal-icon {
        width: 12px;
        height: 12px;
        margin-right: 4px;
        vertical-align: -1px;
        display: inline-block;
      }
      .portal-internal {
        background: rgba(175, 82, 222, 0.12);
        color: #af52de !important;
        border: 1px solid rgba(175, 82, 222, 0.35);
      }
      .portal-internal:hover {
        background: #af52de !important;
        color: #ffffff !important;
        border-color: #af52de !important;
        box-shadow: 0 2px 8px rgba(175, 82, 222, 0.3);
      }
      .portal-public {
        background: rgba(0, 113, 227, 0.1);
        color: #0071e3 !important;
        border: 1px solid rgba(0, 113, 227, 0.3);
      }
      .portal-public:hover {
        background: #0071e3 !important;
        color: #ffffff !important;
        border-color: #0071e3 !important;
        box-shadow: 0 2px 8px rgba(0, 113, 227, 0.3);
      }
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
        </div>
        <div class="content">
          <p class="greeting">\(greeting)</p>
          
          \(filterBarHtml)
          
          <table>
            <thead><tr><th style="width: 55%;">Role</th><th style="width: 11%;">Posted</th><th style="width: 12%;">Location</th><th style="text-align:right; width: 22%; padding-right: 18px;">PORTAL</th></tr></thead>
            <tbody>
              \(rows)
              <tr id="no-match-row" style="display:none;">
                <td colspan="4" style="text-align:center; padding: 40px 16px; color: var(--text-sec); font-size: 14px;">
                  No roles match your search or filter criteria.
                </td>
              </tr>
            </tbody>
          </table>
          <div class="btn-wrapper">
            <a href="\(internalOnly ? careersSearchUrl : publicSearchUrl)" id="view-all-jobs-btn" class="btn" target="_blank">\(internalOnly ? "View All  Internal Jobs →" : "View All \(groupFilledIconSvg) Public Jobs →")</a>
          </div>
        </div>
        \(footerBannerHtml)
        <div class="footer">
          Jobs Monitor v\(APP_VERSION) · Built by Arun Thomas · Contact: \(CONTACT_EMAIL)<br>
          \(nowStr)
        </div>
      </div>
      
      <script>
        var activeFilter = 'all';
        var publicSearchUrl = "\(publicSearchUrl)";
        var careersSearchUrl = "\(careersSearchUrl)";
        var groupIconHtml = '<svg class="portal-icon" style="vertical-align:-1.5px; width:13px; height:13px; margin:0 3px;" viewBox="0 0 16 16" fill="currentColor"><path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"/></svg>';
        
        function setFilter(type, btn) {
          document.querySelectorAll('.filter-pill').forEach(function(el) { el.classList.remove('active'); });
          if (btn) btn.classList.add('active');
          activeFilter = type;
          
          var viewAllBtn = document.getElementById('view-all-jobs-btn');
          if (viewAllBtn) {
            if (activeFilter === 'internal') {
              viewAllBtn.href = careersSearchUrl;
              viewAllBtn.innerHTML = 'View All  Internal Jobs →';
            } else {
              viewAllBtn.href = publicSearchUrl;
              viewAllBtn.innerHTML = 'View All ' + groupIconHtml + ' Public Jobs →';
            }
          }
          
          filterDashboard();
        }
        
        function clearSearch() {
          var input = document.getElementById('job-search');
          if (input) {
            input.value = '';
            var clearBtn = document.getElementById('clear-search');
            if (clearBtn) clearBtn.style.display = 'none';
            filterDashboard();
            input.focus();
          }
        }
        
        function filterDashboard() {
          var searchInput = document.getElementById('job-search');
          var query = searchInput ? searchInput.value.toLowerCase().trim() : '';
          var clearBtn = document.getElementById('clear-search');
          if (clearBtn) {
            clearBtn.style.display = query.length > 0 ? 'inline-block' : 'none';
          }
          
          var rows = document.querySelectorAll('tbody tr[data-both]');
          var visibleCount = 0;
          
          rows.forEach(function(row) {
            var matchType = false;
            if (activeFilter === 'all') {
              matchType = true;
            } else if (activeFilter === 'internal') {
              matchType = (row.getAttribute('data-internal') === 'true');
            } else if (activeFilter === 'public') {
              matchType = (row.getAttribute('data-public') === 'true');
            }
            
            var text = row.textContent.toLowerCase();
            var matchQuery = (query === '' || text.indexOf(query) !== -1);
            
            if (matchType && matchQuery) {
              row.style.display = '';
              visibleCount++;
            } else {
              row.style.display = 'none';
            }
          });
          
          var noMatch = document.getElementById('no-match-row');
          if (noMatch) {
            noMatch.style.display = (visibleCount === 0) ? 'table-row' : 'none';
          }
          
          var status = document.getElementById('filter-status');
          if (status) {
            var label = (activeFilter === 'all') ? 'roles' : ((activeFilter === 'internal') ? ' internal roles' : groupIconHtml + ' public roles');
            if (query.length > 0) {
              status.innerHTML = 'Found ' + visibleCount + ' ' + label + ' matching "' + query + '"';
            } else {
              status.innerHTML = 'Showing all ' + visibleCount + ' ' + label;
            }
          }
        }
      </script>
    </body></html>
    """
}

// ── Date Parser Helper (Newest to Oldest Sorting) ──────────────────────────────
func parsePostedDate(_ str: String) -> Date {
    let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return Date.distantPast }
    let lower = trimmed.lowercased()
    if lower == "today" || lower == "just now" {
        return Date()
    } else if lower == "yesterday" {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    } else if lower.contains("day") && lower.contains("ago") {
        let digits = lower.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let days = Int(digits) {
            return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }
    
    let formats = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd",
        "MMM d, yyyy",
        "MMMM d, yyyy",
        "d MMM yyyy",
        "d MMMM yyyy",
        "MMM dd, yyyy"
    ]
    for fmt in formats {
        let f = DateFormatter()
        f.dateFormat = fmt
        f.locale = Locale(identifier: "en_US_POSIX")
        if let d = f.date(from: trimmed) {
            return d
        }
    }
    return Date.distantPast
}

// ── HTML Parser ────────────────────────────────────────────────────────────────
func parseJobsFromHTML(_ html: String, defaultSearchUrl: String, settings: AppSettings, isInternal: Bool = false) -> [JobItem] {
    var rawResults: [JobItem] = []
    
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
                                if let item = normalizeJob(r, defaultUrl: defaultSearchUrl, isInternal: isInternal) {
                                    rawResults.append(item)
                                }
                            }
                            if !rawResults.isEmpty { break }
                        }
                    }
                }
            }
        }
    }
    
    // ── Location Intelligence Filter ──────────────────────────────────
    var candidates: [JobItem] = rawResults
    if settings.locationMode == 0 {
        // Country Mode (e.g. India)
        let idx = max(0, min(settings.countryIndex, countryPresets.count - 1))
        let targetCountry = countryPresets[idx].name.lowercased()
        let targetCode = countryPresets[idx].code.lowercased()
        
        let filtered = rawResults.filter { job in
            let locLower = job.location.lowercased()
            let cList = (job.countries ?? []).map { $0.lowercased() }
            if cList.contains(where: { $0.contains(targetCountry) || targetCountry.contains($0) }) { return true }
            if locLower.contains(targetCountry) { return true }
            if targetCountry == "india" && (locLower.contains("india") || cList.contains(where: { $0.contains("ind") })) { return true }
            if targetCode.contains("usa") && (locLower.contains("united states") || locLower.contains("usa")) { return true }
            if targetCode.contains("gbr") && (locLower.contains("united kingdom") || locLower.contains("uk")) { return true }
            return false
        }
        if !filtered.isEmpty { candidates = filtered }
    } else if settings.locationMode == 1 {
        // City Mode (e.g. Bengaluru)
        let idx = max(0, min(settings.cityIndex, cityPresets.count - 1))
        let targetCity = cityPresets[idx].name.lowercased()
        
        let filtered = rawResults.filter { job in
            let locLower = job.location.lowercased()
            let cList = (job.cities ?? []).map { $0.lowercased() }
            return cList.contains(where: { $0.contains(targetCity) || targetCity.contains($0) }) || locLower.contains(targetCity)
        }
        if !filtered.isEmpty { candidates = filtered }
    }
    
    // ── Sort Newest to Oldest by Posting Date ─────────────────────────
    return candidates.sorted { j1, j2 in
        let d1 = parsePostedDate(j1.posted)
        let d2 = parsePostedDate(j2.posted)
        if d1 != d2 {
            return d1 > d2
        }
        return j1.id > j2.id
    }
}

func normalizeJob(_ raw: [String: Any], defaultUrl: String, isInternal: Bool = false) -> JobItem? {
    let pid = (raw["positionId"] as? String) ?? (raw["id"] as? String) ?? ""
    if pid.isEmpty { return nil }
    
    let title = (raw["postingTitle"] as? String) ?? (raw["title"] as? String) ?? (raw["name"] as? String) ?? "—"
    
    var teamStr = ""
    if let teamDict = raw["team"] as? [String: Any] {
        teamStr = (teamDict["teamName"] as? String) ?? ""
    } else if let t = raw["team"] as? String {
        teamStr = t
    }
    
    var locStr = ""
    var extractedCountries: [String] = []
    var extractedCities: [String] = []
    
    if let locs = raw["locations"] as? [[String: Any]] {
        for loc in locs {
            let city = (loc["city"] as? String) ?? ""
            let country = (loc["countryName"] as? String) ?? (loc["countryCode"] as? String) ?? ""
            let name = (loc["name"] as? String) ?? ""
            
            if !country.isEmpty { extractedCountries.append(country) }
            if !city.isEmpty { extractedCities.append(city) }
            if !name.isEmpty { extractedCountries.append(name) }
            
            if locStr.isEmpty {
                if !city.isEmpty && !country.isEmpty { locStr = "\(city), \(country)" }
                else if !city.isEmpty { locStr = city }
                else if !name.isEmpty { locStr = name }
                else if !country.isEmpty { locStr = country }
            }
        }
    }
    if locStr.isEmpty { locStr = "Apple" }
    
    let posted = (raw["postingDate"] as? String) ?? (raw["datePosted"] as? String) ?? ""
    let url = isInternal ? "https://careers.apple.com/en-us/details/\(pid)" : "https://jobs.apple.com/en-us/details/\(pid)"
    
    return JobItem(id: pid, title: title, team: teamStr, location: locStr, posted: posted, url: url, countries: extractedCountries, cities: extractedCities, isInternal: isInternal)
}

struct JobsAboutFeature {
    let symbol: String
    let color: NSColor
    let title: String
    let desc: String
}

// ── Native Modern About Window ─────────────────────────────────────────
class AboutWindowController: NSWindowController {
    convenience init() {
        let features: [JobsAboutFeature] = [
            JobsAboutFeature(symbol: "briefcase.fill", color: .systemBlue, title: "Real-Time Job Monitoring", desc: "Automates queries to jobs.apple.com to catch newly opened positions instantly."),
            JobsAboutFeature(symbol: "bell.badge.fill", color: .systemOrange, title: "Smart macOS Notifications", desc: "Get native alert banners or persistent notifications on newly discovered roles."),
            JobsAboutFeature(symbol: "slider.horizontal.3", color: .systemPurple, title: "Role & Location Filters", desc: "Filter by search keywords, teams, target countries, and specific cities."),
            JobsAboutFeature(symbol: "lock.shield.fill", color: .systemGreen, title: "100% On-Device & Private", desc: "Zero telemetry. Connects directly from your Mac straight to Apple careers.")
        ]

        let width: CGFloat = 460
        let textWidth: CGFloat = width - 115
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 2
        let textFont = NSFont.systemFont(ofSize: 11.5, weight: .regular)
        let titleFont = NSFont.systemFont(ofSize: 13, weight: .semibold)

        var featureHeights: [CGFloat] = []
        var totalFeaturesHeight: CGFloat = 0
        for f in features {
            let attr = NSAttributedString(string: f.desc, attributes: [
                .font: textFont,
                .paragraphStyle: para
            ])
            let measured = attr.boundingRect(
                with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading])
            let h = ceil(measured.height) + 24
            featureHeights.append(h)
            totalFeaturesHeight += h + 16
        }
        totalFeaturesHeight -= 16

        let headerHeight: CGFloat = 204
        let bottomSpaceNeeded: CGFloat = 124
        let finalHeight = headerHeight + totalFeaturesHeight + bottomSpaceNeeded

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: finalHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        self.init(window: window)
        setupUI(width: width, finalHeight: finalHeight, headerHeight: headerHeight, features: features, featureHeights: featureHeights, textWidth: textWidth, para: para, textFont: textFont, titleFont: titleFont)
    }
    
    func setupUI(width: CGFloat, finalHeight: CGFloat, headerHeight: CGFloat, features: [JobsAboutFeature], featureHeights: [CGFloat], textWidth: CGFloat, para: NSMutableParagraphStyle, textFont: NSFont, titleFont: NSFont) {
        guard let window = self.window else { return }
        
        let bg = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: finalHeight))
        bg.material = .popover
        bg.blendingMode = .behindWindow
        bg.state = .active
        
        // App Icon (64x64)
        let icon = NSImageView(frame: NSRect(x: (width - 64)/2, y: finalHeight - 88, width: 64, height: 64))
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png")
            ?? Bundle.main.path(forResource: "AppIcon", ofType: "icns")
            ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            icon.image = img
        } else if let img = NSImage(named: "AppIcon") {
            icon.image = img
        } else {
            icon.image = NSApp.applicationIconImage
        }
        icon.imageScaling = .scaleProportionallyUpOrDown
        bg.addSubview(icon)
        
        // Title
        let title = NSTextField(labelWithString: "Jobs Monitor")
        title.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        title.alignment = .center
        title.frame = NSRect(x: 0, y: finalHeight - 124, width: width, height: 28)
        bg.addSubview(title)
        
        // Version
        let ver = NSTextField(labelWithString: "Version \(APP_VERSION)")
        ver.font = NSFont.systemFont(ofSize: 11.5, weight: .medium)
        ver.textColor = .tertiaryLabelColor
        ver.alignment = .center
        ver.frame = NSRect(x: 0, y: finalHeight - 144, width: width, height: 15)
        bg.addSubview(ver)
        
        // Subtitle / Tagline
        let sub = NSTextField(labelWithString: "Real-time Apple career openings tracker with smart alerts.")
        sub.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        sub.textColor = .secondaryLabelColor
        sub.alignment = .center
        sub.frame = NSRect(x: 16, y: finalHeight - 168, width: width - 32, height: 16)
        bg.addSubview(sub)
        
        // Features
        var currentY = finalHeight - headerHeight
        for (i, f) in features.enumerated() {
            let itemH = featureHeights[i]
            let itemY = currentY - itemH
            
            let symSize: CGFloat = 24
            let symView = NSImageView(frame: NSRect(x: 36, y: itemY + (itemH - symSize)/2 + 2, width: symSize, height: symSize))
            let symCfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            symView.image = NSImage(systemSymbolName: f.symbol, accessibilityDescription: nil)?.withSymbolConfiguration(symCfg)
            symView.contentTintColor = f.color
            bg.addSubview(symView)
            
            let hLabel = NSTextField(labelWithString: f.title)
            hLabel.font = titleFont
            hLabel.frame = NSRect(x: 74, y: itemY + itemH - 20, width: textWidth, height: 18)
            bg.addSubview(hLabel)
            
            let attr = NSAttributedString(string: f.desc, attributes: [
                .font: textFont,
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: para
            ])
            let dLabel = NSTextField(labelWithAttributedString: attr)
            dLabel.frame = NSRect(x: 74, y: itemY, width: textWidth, height: itemH - 22)
            dLabel.lineBreakMode = .byWordWrapping
            dLabel.maximumNumberOfLines = 0
            dLabel.isEditable = false
            dLabel.drawsBackground = false
            dLabel.isBordered = false
            bg.addSubview(dLabel)

            currentY = itemY - 16
        }
        
        // Author Note
        let credit = NSTextField(labelWithString: "Built by Arun Thomas")
        credit.frame = NSRect(x: 0, y: 78, width: width, height: 16)
        credit.alignment = .center
        credit.font = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
        credit.textColor = .secondaryLabelColor
        bg.addSubview(credit)
        
        // Action Buttons
        let buttonsY: CGFloat = 26
        let contactW: CGFloat = 110
        let gitW: CGFloat = 110
        let spacing: CGFloat = 14
        let totalW = contactW + gitW + spacing
        let startX = (width - totalW) / 2
        
        let contact = NSButton(title: "Contact", target: self, action: #selector(openContact))
        contact.frame = NSRect(x: startX, y: buttonsY, width: contactW, height: 34)
        contact.isBordered = false
        contact.wantsLayer = true
        contact.layer?.backgroundColor = NSColor.white.cgColor
        contact.layer?.cornerRadius = 17
        contact.layer?.masksToBounds = true
        contact.attributedTitle = NSAttributedString(string: "Contact", attributes: [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 12.5, weight: .medium)
        ])
        bg.addSubview(contact)
        
        let github = NSButton(title: "GitHub", target: self, action: #selector(openGitHub))
        github.frame = NSRect(x: startX + contactW + spacing, y: buttonsY, width: gitW, height: 34)
        github.isBordered = false
        github.wantsLayer = true
        github.layer?.backgroundColor = NSColor.black.cgColor
        github.layer?.cornerRadius = 17
        github.layer?.masksToBounds = true
        github.attributedTitle = NSAttributedString(string: "GitHub", attributes: [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 12.5, weight: .medium)
        ])
        bg.addSubview(github)
        
        window.contentView = bg
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

// ── AppleConnect SSO WebKit Authentication Window ──────────────────────────────
class AppleConnectAuthWindowController: NSWindowController, WKNavigationDelegate, NSWindowDelegate {
    var webView: WKWebView!
    var statusLabel: NSTextField!
    var progressIndicator: NSProgressIndicator!
    var onAuthCompletion: ((Bool) -> Void)?
    private var didCompleteAuthSuccessfully = false

    convenience init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "AppleConnect Sign In · Jobs Monitor"
        win.center()
        self.init(window: win)
        win.delegate = self
        setupUI()
    }

    func setupUI() {
        guard let win = window else { return }
        let contentView = NSView(frame: win.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 780, height: 780))
        contentView.autoresizingMask = [.width, .height]
        
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        webView = WKWebView(frame: NSRect(x: 0, y: 48, width: contentView.bounds.width, height: contentView.bounds.height - 48), configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        contentView.addSubview(webView)
        
        // Bottom Status Bar
        let bottomBar = NSView(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: 48))
        bottomBar.autoresizingMask = [.width, .maxYMargin]
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        statusLabel = NSTextField(labelWithString: "Sign in with your Apple account to enable Internal Mode...")
        statusLabel.frame = NSRect(x: 16, y: 14, width: contentView.bounds.width - 240, height: 20)
        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.autoresizingMask = [.width]
        bottomBar.addSubview(statusLabel)
        
        let confirmBtn = NSButton(title: "Confirm Sign In", target: self, action: #selector(confirmSignInClicked))
        confirmBtn.bezelStyle = .rounded
        confirmBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        confirmBtn.frame = NSRect(x: contentView.bounds.width - 164, y: 8, width: 148, height: 32)
        confirmBtn.autoresizingMask = [.minXMargin]
        bottomBar.addSubview(confirmBtn)
        
        progressIndicator = NSProgressIndicator(frame: NSRect(x: contentView.bounds.width - 192, y: 16, width: 16, height: 16))
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.autoresizingMask = [.minXMargin]
        progressIndicator.isDisplayedWhenStopped = false
        bottomBar.addSubview(progressIndicator)
        
        contentView.addSubview(bottomBar)
        win.contentView = contentView
    }

    func startAuthentication(targetUrl: String? = nil) {
        didCompleteAuthSuccessfully = false
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        let settings = loadSettings()
        let urlStr = targetUrl ?? settings.activeCareersUrl
        guard let url = URL(string: urlStr) else { return }
        let req = URLRequest(url: url)
        progressIndicator.startAnimation(nil)
        statusLabel.stringValue = "Loading Apple internal careers portal..."
        webView.load(req)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressIndicator.startAnimation(nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressIndicator.stopAnimation(nil)
        let currentUrl = webView.url?.absoluteString ?? ""
        logMessage("AppleConnect webView navigated to: \(currentUrl)")
        verifyAuthentication(isManualClick: false)
    }

    @objc func confirmSignInClicked() {
        verifyAuthentication(isManualClick: true)
    }

    func verifyAuthentication(isManualClick: Bool) {
        let currentUrl = webView.url?.absoluteString ?? ""
        let lowerUrl = currentUrl.lowercased()
        let isNotOnLoginPage = lowerUrl.contains("careers.apple.com") &&
                               !lowerUrl.contains("idmsa.apple.com") &&
                               !lowerUrl.contains("appleconnect") &&
                               !lowerUrl.contains("appleid.apple.com") &&
                               !lowerUrl.contains("signin") &&
                               !lowerUrl.contains("auth")
        
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            let appleCookies = cookies.filter { $0.domain.contains("apple.com") }
            let hasRealSSOToken = appleCookies.contains(where: { cookie in
                let name = cookie.name.lowercased()
                return name == "myacinfo" || name == "dqsess" || name == "itctx" || name == "ac_session" || name == "ds_session_id" || name.contains("session") || name.contains("auth")
            })
            
            DispatchQueue.main.async {
                if (hasRealSSOToken && isNotOnLoginPage) || (isManualClick && isNotOnLoginPage) {
                    self?.didCompleteAuthSuccessfully = true
                    self?.statusLabel.stringValue = "✔ Successfully Authenticated with AppleConnect!"
                    self?.statusLabel.textColor = .systemGreen
                    var state = loadStateData()
                    state.isAppleConnectAuthenticated = true
                    state.hasEverAuthenticatedInternal = true
                    state.ssoSessionExpired = false
                    saveStateData(state)
                    self?.onAuthCompletion?(true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.window?.close()
                    }
                } else if isManualClick {
                    self?.statusLabel.stringValue = "⚠️ Please sign in to your Apple account in the window first."
                    self?.statusLabel.textColor = .systemOrange
                } else if lowerUrl.contains("idmsa.apple.com") || lowerUrl.contains("appleconnect") || lowerUrl.contains("appleid.apple.com") {
                    self?.statusLabel.stringValue = "Please enter your AppleConnect credentials above..."
                    self?.statusLabel.textColor = .secondaryLabelColor
                } else {
                    self?.statusLabel.stringValue = "Sign in with your Apple account above, then click Confirm."
                    self?.statusLabel.textColor = .secondaryLabelColor
                }
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        if !didCompleteAuthSuccessfully {
            let state = loadStateData()
            if state.isAppleConnectAuthenticated != true {
                onAuthCompletion?(false)
            }
        }
    }

    static func clearSession(completion: @escaping () -> Void) {
        let store = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        store.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            var state = loadStateData()
            state.isAppleConnectAuthenticated = false
            state.hasEverAuthenticatedInternal = false
            state.ssoSessionExpired = false
            saveStateData(state)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// ── Dynamic Appearance Card & Header Views for Preferences ──────────────────────
class SettingsHeaderView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func updateLayer() {
        super.updateLayer()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
    }
}

class SettingsCardView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
    }
    required init?(coder: NSCoder) { fatalError() }
    override func updateLayer() {
        super.updateLayer()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }
}

// ── Native Preferences Window ──────────────────────────────────────────────────
class SettingsWindowController: NSWindowController, NSTextFieldDelegate, NSWindowDelegate {
    var radioCountry: NSButton!
    var countryPopUp: NSPopUpButton!
    
    var radioCity: NSButton!
    var cityPopUp: NSPopUpButton!
    
    var radioCustom: NSButton!
    var customUrlField: NSTextField!
    var customUrlPreviewBtn: NSButton!
    var customUrlInstructionsBtn: NSButton!
    
    var intervalPopUp: NSPopUpButton!
    var notificationStylePopUp: NSPopUpButton!
    var notificationStylePreviewBtn: NSButton!
    var notificationStyleInfoBtn: NSButton!
    var dismissLabel: NSTextField!
    var dismissPopUp: NSPopUpButton!
    var soundPopUp: NSPopUpButton!
    var volumeSlider: NSSlider!
    var volumeValueLabel: NSTextField!
    
    var dailyCheckCheckbox: NSButton!
    var timePopUp: NSPopUpButton!
    var dayButtons: [NSButton] = []
    
    var enableInternalModeCheckbox: NSButton!
    var internalOnlyCheckbox: NSButton!
    var internalAuthStatusLabel: NSTextField!
    var signInAppleConnectBtn: NSButton!
    var disconnectAppleConnectBtn: NSButton!
    var authWindowController: AppleConnectAuthWindowController?
    
    var launchAtLoginCheckbox: NSButton!
    
    var onSave: (() -> Void)?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 960),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Jobs Monitor Preferences"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.center()
        self.init(window: window)
        window.delegate = self
        
        setupUI()
        loadCurrentValues()
    }
    
    func windowWillClose(_ notification: Notification) {
        // Discard any uncommitted changes when window is closed without saving
        loadCurrentValues()
    }
    
    func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // ── Top Header Banner (Centralized Logo Only) ─────────────────
        let headerView = SettingsHeaderView(frame: NSRect(x: 0, y: 870, width: 660, height: 90))
        
        let iconView = NSImageView(frame: NSRect(x: 298, y: 13, width: 64, height: 64))
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            iconView.image = img
        } else {
            iconView.image = NSImage(systemSymbolName: "briefcase.fill", accessibilityDescription: nil)
        }
        headerView.addSubview(iconView)
        
        let headerSep = NSBox(frame: NSRect(x: 0, y: 0, width: 660, height: 1))
        headerSep.boxType = .separator
        headerView.addSubview(headerSep)
        
        contentView.addSubview(headerView)
        
        // ── Card 1: Target Location (y: 695, height: 165) ────────────
        let card1 = createCardView(frame: NSRect(x: 24, y: 695, width: 612, height: 165))
        
        let card1Title = createSectionHeader(title: "Target Location", iconName: "mappin.and.ellipse", frame: NSRect(x: 16, y: 132, width: 580, height: 22))
        card1.addSubview(card1Title)
        
        radioCountry = NSButton(radioButtonWithTitle: "Country", target: self, action: #selector(radioChanged))
        radioCountry.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        radioCountry.frame = NSRect(x: 20, y: 94, width: 150, height: 22)
        radioCountry.tag = 0
        card1.addSubview(radioCountry)
        
        countryPopUp = NSPopUpButton(frame: NSRect(x: 185, y: 91, width: 407, height: 26))
        countryPopUp.addItems(withTitles: countryPresets.map { $0.name })
        card1.addSubview(countryPopUp)
        
        radioCity = NSButton(radioButtonWithTitle: "City", target: self, action: #selector(radioChanged))
        radioCity.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        radioCity.frame = NSRect(x: 20, y: 56, width: 150, height: 22)
        radioCity.tag = 1
        card1.addSubview(radioCity)
        
        cityPopUp = NSPopUpButton(frame: NSRect(x: 185, y: 53, width: 407, height: 26))
        cityPopUp.addItems(withTitles: cityPresets.map { $0.name })
        card1.addSubview(cityPopUp)
        
        radioCustom = NSButton(radioButtonWithTitle: "Custom URL", target: self, action: #selector(radioChanged))
        radioCustom.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        radioCustom.frame = NSRect(x: 20, y: 18, width: 150, height: 22)
        radioCustom.tag = 2
        card1.addSubview(radioCustom)
        
        customUrlField = NSTextField(frame: NSRect(x: 185, y: 16, width: 326, height: 26))
        customUrlField.placeholderString = "https://jobs.apple.com/en-us/search?search=Python&location=india-INDC"
        customUrlField.font = NSFont.systemFont(ofSize: 12)
        customUrlField.delegate = self
        customUrlField.toolTip = "Paste a search URL from jobs.apple.com"
        card1.addSubview(customUrlField)
        
        customUrlPreviewBtn = NSButton(title: "🔍", target: self, action: #selector(showCustomUrlPreview))
        customUrlPreviewBtn.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        customUrlPreviewBtn.bezelStyle = .rounded
        customUrlPreviewBtn.frame = NSRect(x: 517, y: 15, width: 35, height: 26)
        customUrlPreviewBtn.toolTip = "View full long URL in expanded window"
        card1.addSubview(customUrlPreviewBtn)

        customUrlInstructionsBtn = NSButton(title: "?", target: self, action: #selector(showCustomUrlInstructions))
        customUrlInstructionsBtn.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        customUrlInstructionsBtn.bezelStyle = .rounded
        customUrlInstructionsBtn.frame = NSRect(x: 554, y: 15, width: 38, height: 26)
        customUrlInstructionsBtn.toolTip = "How to use Custom Search URLs"
        card1.addSubview(customUrlInstructionsBtn)
        
        contentView.addSubview(card1)
        
        // ── Card 2: Refresh Frequency (y: 595, height: 85) ─────────
        let card2 = createCardView(frame: NSRect(x: 24, y: 595, width: 612, height: 85))
        
        let card2Title = createSectionHeader(title: "Refresh Frequency", iconName: "clock.fill", frame: NSRect(x: 16, y: 52, width: 580, height: 22))
        card2.addSubview(card2Title)
        
        let intervalLabel = NSTextField(labelWithString: "Check for new jobs every")
        intervalLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        intervalLabel.frame = NSRect(x: 20, y: 18, width: 155, height: 20)
        card2.addSubview(intervalLabel)
        
        intervalPopUp = NSPopUpButton(frame: NSRect(x: 185, y: 15, width: 407, height: 26))
        intervalPopUp.addItems(withTitles: ["5 Minutes", "15 Minutes", "30 Minutes", "1 Hour", "2 Hours", "4 Hours", "6 Hours", "12 Hours", "24 Hours"])
        card2.addSubview(intervalPopUp)
        
        contentView.addSubview(card2)
        
        // ── Card 3: Daily Summary (y: 445, height: 135) ─────────────
        let card3 = createCardView(frame: NSRect(x: 24, y: 445, width: 612, height: 135))
        
        let card3Title = createSectionHeader(title: "Daily Summary", iconName: "calendar.badge.clock", frame: NSRect(x: 16, y: 100, width: 580, height: 22))
        card3.addSubview(card3Title)
        
        dailyCheckCheckbox = NSButton(checkboxWithTitle: "Show at", target: self, action: #selector(dailyCheckToggled))
        dailyCheckCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        dailyCheckCheckbox.frame = NSRect(x: 20, y: 58, width: 155, height: 22)
        card3.addSubview(dailyCheckCheckbox)
        
        timePopUp = NSPopUpButton(frame: NSRect(x: 185, y: 55, width: 407, height: 26))
        timePopUp.addItems(withTitles: timeOptions.map { $0.title })
        card3.addSubview(timePopUp)
        
        let startX: CGFloat = 185
        let totalW: CGFloat = 407.0
        let spacing: CGFloat = 4.0
        let btnWidth: CGFloat = (totalW - 6.0 * spacing) / 7.0
        
        for (idx, dName) in dayNames.enumerated() {
            let btnX = startX + CGFloat(idx) * (btnWidth + spacing)
            let btn = NSButton(title: dName, target: self, action: #selector(dayButtonToggled))
            btn.frame = NSRect(x: btnX, y: 18, width: btnWidth, height: 26)
            btn.setButtonType(.pushOnPushOff)
            btn.bezelStyle = .recessed
            btn.font = NSFont.systemFont(ofSize: 11, weight: .regular)
            btn.tag = idx
            card3.addSubview(btn)
            dayButtons.append(btn)
        }
        
        contentView.addSubview(card3)
        
        // ── Card 4: Alerts & Notifications (y: 200, height: 230) ──────
        let card4 = createCardView(frame: NSRect(x: 24, y: 200, width: 612, height: 230))
        
        let card4Title = createSectionHeader(title: "Alerts & Notifications", iconName: "bell.fill", frame: NSRect(x: 16, y: 194, width: 580, height: 22))
        card4.addSubview(card4Title)
        
        // Row 1: Notification Style setting
        let styleLabel = NSTextField(labelWithString: "Notification Style")
        styleLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        styleLabel.frame = NSRect(x: 20, y: 154, width: 155, height: 20)
        card4.addSubview(styleLabel)
        
        notificationStylePopUp = NSPopUpButton(frame: NSRect(x: 185, y: 151, width: 250, height: 26))
        notificationStylePopUp.addItems(withTitles: ["System Notification Banner", "Mid-Screen Popup Window"])
        notificationStylePopUp.target = self
        notificationStylePopUp.action = #selector(notificationStyleChanged)
        card4.addSubview(notificationStylePopUp)
        
        notificationStylePreviewBtn = NSButton(title: "▶ Preview", target: self, action: #selector(previewNotificationStyle))
        notificationStylePreviewBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        notificationStylePreviewBtn.bezelStyle = .rounded
        notificationStylePreviewBtn.frame = NSRect(x: 442, y: 150, width: 105, height: 26)
        notificationStylePreviewBtn.toolTip = "Test current notification style and sound live"
        card4.addSubview(notificationStylePreviewBtn)

        notificationStyleInfoBtn = NSButton(title: "?", target: self, action: #selector(showNotificationStyleInfo))
        notificationStyleInfoBtn.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        notificationStyleInfoBtn.bezelStyle = .rounded
        notificationStyleInfoBtn.frame = NSRect(x: 554, y: 150, width: 38, height: 26)
        notificationStyleInfoBtn.toolTip = "Learn about Notification Delivery Styles"
        card4.addSubview(notificationStyleInfoBtn)

        // Row 2: Sound Selector (Auto-previews selected sound)
        let soundLabel = NSTextField(labelWithString: "Sound")
        soundLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        soundLabel.frame = NSRect(x: 20, y: 110, width: 155, height: 20)
        card4.addSubview(soundLabel)
        
        soundPopUp = NSPopUpButton(frame: NSRect(x: 185, y: 107, width: 407, height: 26))
        soundPopUp.addItems(withTitles: availableSounds.map { $0.title })
        soundPopUp.target = self
        soundPopUp.action = #selector(soundPopUpChanged)
        card4.addSubview(soundPopUp)

        // Row 3: Sound Volume Control
        let volumeTitleLabel = NSTextField(labelWithString: "Volume")
        volumeTitleLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        volumeTitleLabel.frame = NSRect(x: 20, y: 66, width: 155, height: 20)
        card4.addSubview(volumeTitleLabel)

        volumeSlider = NSSlider(value: 1.0, minValue: 0.0, maxValue: 1.0, target: self, action: #selector(volumeSliderChanged))
        volumeSlider.frame = NSRect(x: 185, y: 64, width: 340, height: 24)
        card4.addSubview(volumeSlider)

        volumeValueLabel = NSTextField(labelWithString: "100%")
        volumeValueLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        volumeValueLabel.textColor = .secondaryLabelColor
        volumeValueLabel.frame = NSRect(x: 532, y: 66, width: 60, height: 20)
        card4.addSubview(volumeValueLabel)
        
        // Row 4: Dismiss Popup Window Alert
        dismissLabel = NSTextField(labelWithString: "Dismiss popup after")
        dismissLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        dismissLabel.frame = NSRect(x: 20, y: 22, width: 155, height: 20)
        card4.addSubview(dismissLabel)
        
        dismissPopUp = NSPopUpButton(frame: NSRect(x: 185, y: 19, width: 407, height: 26))
        dismissPopUp.addItems(withTitles: ["10 Seconds", "30 Seconds", "1 Minute", "3 Minutes", "5 Minutes", "10 Minutes", "Do Not Auto-Dismiss"])
        card4.addSubview(dismissPopUp)
        
        contentView.addSubview(card4)
        
        // ── Card 5: Apple Employee / Internal Mode (y: 65, height: 120) ──
        let card5 = createCardView(frame: NSRect(x: 24, y: 65, width: 612, height: 120))
        
        let card5Title = createSectionHeader(title: "Apple Employee (Internal Mode)", iconName: "lock.shield.fill", frame: NSRect(x: 16, y: 88, width: 580, height: 22))
        card5.addSubview(card5Title)
        
        enableInternalModeCheckbox = NSButton(checkboxWithTitle: "Enable Internal Mode (careers.apple.com)", target: self, action: #selector(internalModeToggled))
        enableInternalModeCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        enableInternalModeCheckbox.frame = NSRect(x: 20, y: 54, width: 330, height: 22)
        card5.addSubview(enableInternalModeCheckbox)
        
        internalOnlyCheckbox = NSButton(checkboxWithTitle: "Internal roles only", target: self, action: nil)
        internalOnlyCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        internalOnlyCheckbox.frame = NSRect(x: 360, y: 54, width: 230, height: 22)
        card5.addSubview(internalOnlyCheckbox)
        
        internalAuthStatusLabel = NSTextField(labelWithString: "○ Not Signed In")
        internalAuthStatusLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        internalAuthStatusLabel.textColor = .secondaryLabelColor
        internalAuthStatusLabel.frame = NSRect(x: 20, y: 18, width: 270, height: 22)
        card5.addSubview(internalAuthStatusLabel)
        
        signInAppleConnectBtn = NSButton(title: "Sign In with AppleConnect...", target: self, action: #selector(signInAppleConnectClicked))
        signInAppleConnectBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        signInAppleConnectBtn.bezelStyle = .rounded
        signInAppleConnectBtn.frame = NSRect(x: 295, y: 14, width: 205, height: 28)
        card5.addSubview(signInAppleConnectBtn)
        
        disconnectAppleConnectBtn = NSButton(title: "Disconnect", target: self, action: #selector(disconnectAppleConnectClicked))
        disconnectAppleConnectBtn.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        disconnectAppleConnectBtn.bezelStyle = .rounded
        disconnectAppleConnectBtn.frame = NSRect(x: 505, y: 14, width: 95, height: 28)
        card5.addSubview(disconnectAppleConnectBtn)
        
        contentView.addSubview(card5)
        
        // ── Bottom Action Footer ──────────────────────────────────────
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: nil)
        launchAtLoginCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        launchAtLoginCheckbox.frame = NSRect(x: 24, y: 18, width: 160, height: 22)
        contentView.addSubview(launchAtLoginCheckbox)
        
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelBtn.frame = NSRect(x: 410, y: 14, width: 100, height: 32)
        cancelBtn.bezelStyle = .rounded
        contentView.addSubview(cancelBtn)
        
        let saveBtn = NSButton(title: "Save Settings", target: self, action: #selector(saveClicked))
        saveBtn.frame = NSRect(x: 520, y: 14, width: 116, height: 32)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        contentView.addSubview(saveBtn)
    }

    func createCardView(frame: NSRect) -> NSView {
        let card = SettingsCardView(frame: frame)
        return card
    }

    func createSectionHeader(title: String, iconName: String, frame: NSRect) -> NSView {
        let header = NSView(frame: frame)
        
        let iconSize: CGFloat = 16.0
        let iconY: CGFloat = (frame.height - iconSize) / 2.0
        let iconView = NSImageView(frame: NSRect(x: 0, y: iconY, width: iconSize, height: iconSize))
        iconView.imageScaling = .scaleProportionallyUpOrDown
        let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) ?? NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        iconView.image = img
        iconView.contentTintColor = .labelColor
        header.addSubview(iconView)
        
        let labelHeight: CGFloat = 18.0
        let labelY: CGFloat = (frame.height - labelHeight) / 2.0
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        label.frame = NSRect(x: 24, y: labelY, width: frame.width - 24, height: labelHeight)
        header.addSubview(label)
        return header
    }

    func controlTextDidChange(_ obj: Notification) {
        if let tf = obj.object as? NSTextField, tf == customUrlField {
            tf.toolTip = tf.stringValue.isEmpty ? "Paste a search URL from jobs.apple.com" : tf.stringValue
        }
    }

    @objc func showCustomUrlPreview() {
        let currentUrl = customUrlField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayUrl = currentUrl.isEmpty ? "https://jobs.apple.com/en-us/search?location=india-INDC&sort=newest" : currentUrl
        showCustomInfoModal(title: "Current Custom Search URL", contentText: displayUrl, isMonospaced: true)
    }

    @objc func showCustomUrlInstructions() {
        let instructions = """
        How to configure a Custom Apple Jobs Search:
        
        1. Open your browser and go to jobs.apple.com/en-us/search
        2. Apply your desired search filters (e.g. keywords like 'Swift', 'AI/ML', specific teams, or multiple regions).
        3. Ensure the sort order is set to 'Newest' on Apple's portal.
        4. Copy the entire URL from your browser's address bar.
        5. Select 'Custom URL' above and paste your link into the field.
        
        Jobs Monitor will track and alert you for new openings matching your custom query!
        """
        showCustomInfoModal(title: "Custom URL Instructions", contentText: instructions, isMonospaced: false)
    }

    @objc func closeInfoModal(_ sender: NSButton) {
        NSApp.stopModal()
        sender.window?.orderOut(nil)
    }

    func showCustomInfoModal(title: String, contentText: String, isMonospaced: Bool = false) {
        let winWidth: CGFloat = 540
        let font = isMonospaced ? NSFont.monospacedSystemFont(ofSize: 11, weight: .regular) : NSFont.systemFont(ofSize: 12, weight: .regular)
        let constraintRect = CGSize(width: winWidth - 68, height: .greatestFiniteMagnitude)
        let boundingBox = (contentText as NSString).boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        let textContentHeight = max(110, min(420, ceil(boundingBox.height) + 24))
        let winHeight: CGFloat = textContentHeight + 216
        
        let modalWin = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winWidth, height: winHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        modalWin.title = title
        modalWin.titleVisibility = .hidden
        modalWin.titlebarAppearsTransparent = true
        modalWin.isMovableByWindowBackground = true
        modalWin.backgroundColor = NSColor.windowBackgroundColor
        modalWin.center()
        
        let modalContent = NSView(frame: NSRect(x: 0, y: 0, width: winWidth, height: winHeight))
        
        let headerView = SettingsHeaderView(frame: NSRect(x: 0, y: winHeight - 90, width: winWidth, height: 90))
        let iconView = NSImageView(frame: NSRect(x: (winWidth - 64) / 2.0, y: 13, width: 64, height: 64))
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            iconView.image = img
        } else {
            iconView.image = NSImage(systemSymbolName: "briefcase.fill", accessibilityDescription: nil)
        }
        headerView.addSubview(iconView)
        
        let headerSep = NSBox(frame: NSRect(x: 0, y: 0, width: winWidth, height: 1))
        headerSep.boxType = .separator
        headerView.addSubview(headerSep)
        modalContent.addSubview(headerView)
        
        let modalTitleLabel = NSTextField(labelWithString: title)
        modalTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        modalTitleLabel.alignment = .center
        modalTitleLabel.frame = NSRect(x: 20, y: winHeight - 124, width: winWidth - 40, height: 22)
        modalContent.addSubview(modalTitleLabel)
        
        let cardY: CGFloat = 68
        let cardH: CGFloat = textContentHeight
        let card = createCardView(frame: NSRect(x: 24, y: cardY, width: winWidth - 48, height: cardH))
        
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 10, width: winWidth - 68, height: cardH - 20))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        
        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = font
        textView.textColor = .labelColor
        textView.string = contentText
        textView.textContainer?.containerSize = NSSize(width: winWidth - 68, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView
        card.addSubview(scrollView)
        
        modalContent.addSubview(card)
        
        let okBtn = NSButton(title: "OK", target: self, action: #selector(closeInfoModal(_:)))
        okBtn.bezelStyle = .rounded
        okBtn.frame = NSRect(x: (winWidth - 90) / 2.0, y: 18, width: 90, height: 32)
        okBtn.keyEquivalent = "\r"
        modalContent.addSubview(okBtn)
        
        modalWin.contentView = modalContent
        NSApp.runModal(for: modalWin)
    }

    @objc func showNotificationStyleInfo() {
        let content = """
        Delivery Styles:
        
        • System Notification Banner: Standard macOS notification banner in the top-right corner. Automatically routed through Notification Center and respects macOS Do Not Disturb & Focus modes.
        
        • Mid-Screen Popup Window: A prominent dialog appearing in the center of your screen with app icon, dismiss countdown, and quick-action buttons. Guaranteed to be noticed even when DND is active.
        """
        showCustomInfoModal(title: "Notification Delivery Styles", contentText: content, isMonospaced: false)
    }

    @objc func previewNotificationStyle() {
        let isSystemBanner = notificationStylePopUp.indexOfSelectedItem == 0
        let currentVol = volumeSlider.floatValue
        
        var selectedSoundPath = ""
        let idx = soundPopUp.indexOfSelectedItem
        if idx >= 0 && idx < availableSounds.count {
            selectedSoundPath = availableSounds[idx].nameOrPath
        }
        
        playNotificationSound(selectedSoundPath, volume: currentVol)
        
        if isSystemBanner {
            let content = UNMutableNotificationContent()
            content.title = " Jobs Monitor Preview"
            content.body = "This is a test of the System Notification Banner alert style."
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    logMessage("Notification Preview dispatch error: \(error.localizedDescription)")
                }
            }
        } else {
            let alert = NSAlert()
            alert.messageText = " Jobs Monitor Preview"
            alert.informativeText = "This is a test of the Mid-Screen Popup Window alert style."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            
            let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
            if let img = NSImage(contentsOfFile: iconPath) {
                alert.icon = img
            }
            alert.runModal()
        }
    }

    @objc func notificationStyleChanged(_ sender: NSPopUpButton) {
        let isSystemBanner = (sender.indexOfSelectedItem == 0)
        dismissLabel.isHidden = isSystemBanner
        dismissPopUp.isHidden = isSystemBanner
    }

    @objc func volumeSliderChanged(_ sender: NSSlider) {
        let pct = Int(sender.floatValue * 100)
        volumeValueLabel.stringValue = "\(pct)%"
        debouncedSoundPreview()
    }

    @objc func soundPopUpChanged(_ sender: NSPopUpButton) {
        debouncedSoundPreview()
    }

    var volumePreviewTimer: Timer?
    func debouncedSoundPreview() {
        volumePreviewTimer?.invalidate()
        volumePreviewTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let idx = self.soundPopUp.indexOfSelectedItem
            if idx >= 0 && idx < availableSounds.count {
                playNotificationSound(availableSounds[idx].nameOrPath, volume: self.volumeSlider.floatValue)
            }
        }
    }

    @objc func radioChanged(_ sender: NSButton) {
        countryPopUp.isEnabled = (sender.tag == 0)
        cityPopUp.isEnabled = (sender.tag == 1)
        customUrlField.isEnabled = (sender.tag == 2)
        customUrlInstructionsBtn.isEnabled = true
    }

    @objc func dailyCheckToggled(_ sender: NSButton) {
        let enabled = (sender.state == .on)
        timePopUp.isEnabled = enabled
        for btn in dayButtons {
            btn.isEnabled = enabled
        }
    }

    @objc func dayButtonToggled(_ sender: NSButton) {
        // Toggle handled by button state
    }
    
    @objc func cancelClicked() {
        volumePreviewTimer?.invalidate()
        stopNotificationSound()
        window?.close()
    }
    
    @objc func internalModeToggled() {
        let state = loadStateData()
        let isAuth = state.isAppleConnectAuthenticated ?? false
        
        if enableInternalModeCheckbox.state == .on {
            if !isAuth {
                // Cannot enable without authentication
                enableInternalModeCheckbox.state = .off
                internalOnlyCheckbox.state = .off
                internalOnlyCheckbox.isEnabled = false
                
                let alert = NSAlert()
                alert.messageText = "AppleConnect Authentication Required"
                alert.informativeText = "To enable Internal Mode, please sign in with your Apple employee credentials."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Sign In with AppleConnect...")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    signInAppleConnectClicked()
                }
                return
            }
            internalOnlyCheckbox.isEnabled = true
        } else {
            internalOnlyCheckbox.state = .off
            internalOnlyCheckbox.isEnabled = false
        }
    }
    
    func updateInternalAuthUI() {
        let state = loadStateData()
        let isAuth = state.isAppleConnectAuthenticated ?? false
        let isExpired = (state.ssoSessionExpired == true)
        
        if isAuth {
            if isExpired {
                internalAuthStatusLabel.stringValue = "⚠️ Authentication Session Expired"
                internalAuthStatusLabel.textColor = .systemOrange
            } else {
                internalAuthStatusLabel.stringValue = "● Authenticated with AppleConnect"
                internalAuthStatusLabel.textColor = .systemGreen
            }
            signInAppleConnectBtn.title = "Re-authenticate..."
            disconnectAppleConnectBtn.isHidden = false
            enableInternalModeCheckbox.isEnabled = true
            internalOnlyCheckbox.isEnabled = (enableInternalModeCheckbox.state == .on)
        } else {
            internalAuthStatusLabel.stringValue = "○ Not Signed In"
            internalAuthStatusLabel.textColor = .secondaryLabelColor
            signInAppleConnectBtn.title = "Sign In with AppleConnect..."
            disconnectAppleConnectBtn.isHidden = true
            enableInternalModeCheckbox.state = .off
            internalOnlyCheckbox.state = .off
            internalOnlyCheckbox.isEnabled = false
        }
    }
    
    @objc func signInAppleConnectClicked() {
        if authWindowController == nil {
            authWindowController = AppleConnectAuthWindowController()
        }
        let settings = loadSettings()
        authWindowController?.onAuthCompletion = { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.enableInternalModeCheckbox.state = .on
                    self?.internalOnlyCheckbox.isEnabled = true
                } else {
                    self?.enableInternalModeCheckbox.state = .off
                    self?.internalOnlyCheckbox.state = .off
                    self?.internalOnlyCheckbox.isEnabled = false
                }
                self?.updateInternalAuthUI()
            }
        }
        authWindowController?.startAuthentication(targetUrl: settings.activeCareersUrl)
    }
    
    @objc func disconnectAppleConnectClicked() {
        AppleConnectAuthWindowController.clearSession { [weak self] in
            DispatchQueue.main.async {
                self?.enableInternalModeCheckbox.state = .off
                self?.internalOnlyCheckbox.state = .off
                self?.internalOnlyCheckbox.isEnabled = false
                
                var s = loadSettings()
                s.enableInternalMode = false
                s.internalOnly = false
                saveSettings(s)
                
                var st = loadStateData()
                st.isAppleConnectAuthenticated = false
                st.hasEverAuthenticatedInternal = false
                st.ssoSessionExpired = false
                saveStateData(st)
                
                self?.updateInternalAuthUI()
            }
        }
    }
    
    func loadCurrentValues() {
        let s = loadSettings()
        radioCountry.state = (s.locationMode == 0) ? .on : .off
        radioCity.state = (s.locationMode == 1) ? .on : .off
        radioCustom.state = (s.locationMode == 2) ? .on : .off
        
        countryPopUp.isEnabled = (s.locationMode == 0)
        cityPopUp.isEnabled = (s.locationMode == 1)
        customUrlField.isEnabled = (s.locationMode == 2)
        customUrlInstructionsBtn.isEnabled = true
        
        countryPopUp.selectItem(at: (s.countryIndex >= 0 && s.countryIndex < countryPresets.count) ? s.countryIndex : 0)
        cityPopUp.selectItem(at: (s.cityIndex >= 0 && s.cityIndex < cityPresets.count) ? s.cityIndex : 0)
        
        customUrlField.stringValue = s.customUrl
        customUrlField.toolTip = s.customUrl.isEmpty ? "Paste a search URL from jobs.apple.com" : s.customUrl
        
        switch s.checkIntervalMinutes {
        case 5: intervalPopUp.selectItem(at: 0)
        case 15: intervalPopUp.selectItem(at: 1)
        case 30: intervalPopUp.selectItem(at: 2)
        case 60: intervalPopUp.selectItem(at: 3)
        case 120: intervalPopUp.selectItem(at: 4)
        case 240: intervalPopUp.selectItem(at: 5)
        case 360: intervalPopUp.selectItem(at: 6)
        case 720: intervalPopUp.selectItem(at: 7)
        case 1440: intervalPopUp.selectItem(at: 8)
        default: intervalPopUp.selectItem(at: 4)
        }
        
        // Notification Style (Default: 1 - Mid-Screen Popup Window)
        notificationStylePopUp.selectItem(at: s.notificationStyle == 0 ? 0 : 1)
        notificationStyleChanged(notificationStylePopUp)
        
        switch s.popupDismissSeconds {
        case 10: dismissPopUp.selectItem(at: 0)
        case 30: dismissPopUp.selectItem(at: 1)
        case 60: dismissPopUp.selectItem(at: 2)
        case 180: dismissPopUp.selectItem(at: 3)
        case 600: dismissPopUp.selectItem(at: 5)
        case 0: dismissPopUp.selectItem(at: 6)
        default: dismissPopUp.selectItem(at: 4)
        }
        
        // Notification Sound & Volume
        let savedSound = s.notificationSound
        if let idx = availableSounds.firstIndex(where: { $0.nameOrPath == savedSound || $0.title == savedSound }) {
            soundPopUp.selectItem(at: idx)
        } else if let bulletinIdx = availableSounds.firstIndex(where: { $0.title == "Bulletin" }) {
            soundPopUp.selectItem(at: bulletinIdx)
        } else {
            soundPopUp.selectItem(at: 1)
        }
        
        volumeSlider.floatValue = s.notificationVolume
        volumeValueLabel.stringValue = "\(Int(s.notificationVolume * 100))%"
        
        dailyCheckCheckbox.state = s.enableDailyCheck ? .on : .off
        timePopUp.isEnabled = s.enableDailyCheck
        
        let h = s.dailyCheckHour
        let m = s.dailyCheckMinute
        let matchIdx = timeOptions.firstIndex(where: { $0.hour == h && $0.minute == m }) ?? 0
        timePopUp.selectItem(at: matchIdx)
        
        let days = s.activeDays.count == 7 ? s.activeDays : [false, true, true, true, true, true, false]
        for (idx, btn) in dayButtons.enumerated() {
            btn.state = days[idx] ? .on : .off
            btn.isEnabled = s.enableDailyCheck
        }
        
        enableInternalModeCheckbox.state = s.enableInternalMode ? .on : .off
        internalOnlyCheckbox.state = s.internalOnly ? .on : .off
        updateInternalAuthUI()
        
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
        case 4: s.checkIntervalMinutes = 120
        case 5: s.checkIntervalMinutes = 240
        case 6: s.checkIntervalMinutes = 360
        case 7: s.checkIntervalMinutes = 720
        case 8: s.checkIntervalMinutes = 1440
        default: s.checkIntervalMinutes = 120
        }
        
        s.notificationStyle = notificationStylePopUp.indexOfSelectedItem == 0 ? 0 : 1
        
        switch dismissPopUp.indexOfSelectedItem {
        case 0: s.popupDismissSeconds = 10
        case 1: s.popupDismissSeconds = 30
        case 2: s.popupDismissSeconds = 60
        case 3: s.popupDismissSeconds = 180
        case 5: s.popupDismissSeconds = 600
        case 6: s.popupDismissSeconds = 0
        default: s.popupDismissSeconds = 300
        }
        
        // Notification Sound & Volume
        let selectedSoundIdx = soundPopUp.indexOfSelectedItem
        if selectedSoundIdx >= 0 && selectedSoundIdx < availableSounds.count {
            s.notificationSound = availableSounds[selectedSoundIdx].nameOrPath
        }
        s.notificationVolume = volumeSlider.floatValue
        
        s.enableDailyCheck = (dailyCheckCheckbox.state == .on)
        let selectedTimeOpt = timeOptions[max(0, min(timePopUp.indexOfSelectedItem, timeOptions.count - 1))]
        s.dailyCheckHour = selectedTimeOpt.hour
        s.dailyCheckMinute = selectedTimeOpt.minute
        s.activeDays = dayButtons.map { $0.state == .on }
        
        let state = loadStateData()
        let isAuth = state.isAppleConnectAuthenticated ?? false
        if enableInternalModeCheckbox.state == .on && isAuth {
            s.enableInternalMode = true
            s.internalOnly = (internalOnlyCheckbox.state == .on)
        } else {
            s.enableInternalMode = false
            s.internalOnly = false
        }
        
        let launchLogin = (launchAtLoginCheckbox.state == .on)
        s.launchAtLogin = launchLogin
        configureLaunchAtLogin(enabled: launchLogin)
        
        volumePreviewTimer?.invalidate()
        stopNotificationSound()
        saveSettings(s)
        window?.close()
        onSave?()
    }
}

// ── Main App Delegate (Menu Bar App) ───────────────────────────────────────────
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var dailyTimer: Timer?
    var settingsWindowController: SettingsWindowController?
    var aboutWindowController: AboutWindowController?
    
    func setupMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logMessage(" Jobs Monitor App Starting...")
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                logMessage("UNUserNotificationCenter authorization notice: \(error.localizedDescription)")
            }
        }
        
        setupMainMenu()
        
        // Observe system wake from sleep so timers stay accurate and missed daily checks trigger
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(macOSDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
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
        
        // First Launch or Installer Launch: Automatically open Preferences Window
        let firstLaunchKey = "has_launched_jobsmonitor"
        let forceOpenPref = CommandLine.arguments.contains("--open-preferences")
        if forceOpenPref || !UserDefaults.standard.bool(forKey: firstLaunchKey) {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openPreferences()
            }
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=com.aoh.jobsmonitor") {
                NSWorkspace.shared.open(url)
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
        
        // Title Item with Icon (Version removed)
        let titleItem = NSMenuItem(title: "Jobs Monitor", action: nil, keyEquivalent: "")
        titleItem.image = NSImage(systemSymbolName: "apple.logo", accessibilityDescription: nil)
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // Last Checked Time Item with Clock Icon
        var lastCheckedText = state.last_checked_str ?? "Just now"
        if lastCheckedText.contains("AM") || lastCheckedText.contains("PM") || lastCheckedText == "Never" {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, HH:mm"
            lastCheckedText = formatter.string(from: Date())
        }
        let checkTimeItem = NSMenuItem(title: "Last Checked: \(lastCheckedText)", action: nil, keyEquivalent: "")
        checkTimeItem.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: nil)
        checkTimeItem.isEnabled = false
        menu.addItem(checkTimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check Jobs Item with Icon
        let checkNowItem = NSMenuItem(title: "Check Jobs", action: #selector(checkNowClicked), keyEquivalent: "r")
        checkNowItem.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        checkNowItem.target = self
        menu.addItem(checkNowItem)
        
        // View Dashboard Item with Icon
        let viewDashItem = NSMenuItem(title: "View Dashboard", action: #selector(viewDashboardClicked), keyEquivalent: "d")
        viewDashItem.image = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: nil)
        viewDashItem.target = self
        menu.addItem(viewDashItem)
        
        // Preferences Item with Icon
        let prefItem = NSMenuItem(title: "Preferences", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        prefItem.target = self
        menu.addItem(prefItem)
        
        let settings = loadSettings()
        let isAuth = (state.isAppleConnectAuthenticated ?? false) || (state.hasEverAuthenticatedInternal ?? false)
        let isExpired = (state.ssoSessionExpired == true)
        
        if settings.enableInternalMode && isAuth {
            let modeTitle = isExpired ? "⚠️ AppleConnect Session Expired" : "Internal Mode: Active "
            let modeItem = NSMenuItem(title: modeTitle, action: #selector(openPreferences), keyEquivalent: "")
            modeItem.image = NSImage(systemSymbolName: isExpired ? "exclamationmark.triangle.fill" : "apple.logo", accessibilityDescription: nil)
            modeItem.target = self
            menu.addItem(modeItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // About Item with Icon
        let aboutItem = NSMenuItem(title: "About", action: #selector(openAbout), keyEquivalent: "i")
        aboutItem.image = NSImage(systemSymbolName: "info.circle.fill", accessibilityDescription: nil)
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Check for Updates Item with Icon
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(manualUpdateCheck), keyEquivalent: "u")
        updateItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle.fill", accessibilityDescription: nil)
        updateItem.target = self
        menu.addItem(updateItem)
        
        // Quit Item with Icon
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
        
        menu.delegate = self
        statusItem.menu = menu
    }
    
    @objc func menuWillOpen(_ menu: NSMenu) {
        let state = loadStateData()
        var lastCheckedText = state.last_checked_str ?? "Just now"
        if lastCheckedText.contains("AM") || lastCheckedText.contains("PM") || lastCheckedText == "Never" {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, HH:mm"
            lastCheckedText = formatter.string(from: Date())
        }
        if menu.items.count > 1 {
            menu.items[1].title = "Last Checked: \(lastCheckedText)"
        }
    }
    
    @objc func manualUpdateCheck() {
        checkForUpdates(silentIfCurrent: false)
    }
    
    func checkForUpdates(silentIfCurrent: Bool) {
        let now = Date()
        if silentIfCurrent {
            if let lastCheck = UserDefaults.standard.object(forKey: "lastUpdateCheckDate") as? Date,
               now.timeIntervalSince(lastCheck) < 86400 {
                return // Only check once per 24 hours on automatic launch
            }
        }
        UserDefaults.standard.set(now, forKey: "lastUpdateCheckDate")

        URLCache.shared.removeAllCachedResponses()
        let ts = Int(now.timeIntervalSince1970)
        let urlStr = VERSION_CHECK_URL.contains("?") ? "\(VERSION_CHECK_URL)&t=\(ts)" : "\(VERSION_CHECK_URL)?t=\(ts)"
        guard let url = URL(string: urlStr) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("no-cache", forHTTPHeaderField: "Pragma")
        
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
            
            let isNewer = self.compareVersions(remote: remoteVersion, current: APP_VERSION)
            var notes = ""
            if let changelogs = json["changelog"] as? [[String: Any]] {
                let targetEntries: [[String: Any]]
                if isNewer {
                    targetEntries = changelogs.filter { entry in
                        if let v = entry["version"] as? String {
                            return self.compareVersions(remote: v, current: APP_VERSION)
                        }
                        return false
                    }
                } else {
                    targetEntries = Array(changelogs.prefix(2))
                }
                
                notes = targetEntries.compactMap { entry -> String? in
                    guard let v = entry["version"] as? String,
                          let changes = entry["changes"] as? [String] else { return nil }
                    let changeList = changes.map { "• \($0)" }.joined(separator: "\n")
                    return "Version \(v):\n\(changeList)"
                }.joined(separator: "\n\n")
            }
            
            if isNewer || !silentIfCurrent {
                DispatchQueue.main.async {
                    self.showUpdateAlert(remoteVersion: remoteVersion, changelog: notes, isNewer: isNewer)
                }
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
        NSApp.activate(ignoringOtherApps: true)
        
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            alert.icon = img
        }
        
        if isNewer, let ver = remoteVersion {
            alert.messageText = "Jobs Monitor v\(ver) is available"
            alert.informativeText = "You have v\(APP_VERSION). Here's what's new:"
            if !changelog.isEmpty {
                alert.accessoryView = createChangelogView(changelog: changelog)
            }
            alert.addButton(withTitle: "Update Now")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                downloadAndInstallUpdate()
            }
        } else if remoteVersion != nil {
            alert.messageText = "You're Up to Date!"
            alert.informativeText = "Jobs Monitor v\(APP_VERSION) is the latest version."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            alert.messageText = "Couldn't Check for Updates"
            alert.informativeText = "Please check your internet connection and try again."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func downloadAndInstallUpdate() {
        guard let url = URL(string: COMMAND_DOWNLOAD_URL) else { return }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            DispatchQueue.main.async {
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
                    // Launch installer script directly in Terminal
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
    }
    
    @objc func macOSDidWake(_ notification: Notification) {
        logMessage("macOS woke from sleep — evaluating timer status and scheduled daily digest")
        evaluateAndScheduleTimer()
        scheduleDailyTimer()
    }
    
    func scheduleTimer() {
        evaluateAndScheduleTimer()
    }
    
    func evaluateAndScheduleTimer() {
        timer?.invalidate()
        let settings = loadSettings()
        let intervalSeconds = Double(settings.checkIntervalMinutes * 60)
        
        let state = loadStateData()
        let now = Date()
        let lastCheckTime = state.last_check_timestamp ?? 0
        let elapsed = now.timeIntervalSince1970 - lastCheckTime
        
        if lastCheckTime > 0 && elapsed < intervalSeconds {
            let remaining = max(5.0, intervalSeconds - elapsed)
            logMessage("Next job check scheduled in \(Int(remaining / 60)) min (\(Int(remaining))s)")
            timer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
                self?.performCheck(isManual: false)
                self?.scheduleTimer()
                self?.scheduleDailyTimer()
            }
        } else {
            logMessage("Job check due/overdue (elapsed: \(Int(elapsed / 60)) min) — running job check")
            performCheck(isManual: false)
            
            timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
                self?.performCheck(isManual: false)
                self?.scheduleDailyTimer()
            }
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
        
        // ── Check if today's daily popup was missed (laptop was off at scheduled time) ──
        let todayWeekdayIndex = calendar.component(.weekday, from: now) - 1 // 0=Sun, 1=Mon, ..., 6=Sat
        if activeDays[todayWeekdayIndex] {
            var todayComp = calendar.dateComponents([.year, .month, .day], from: now)
            todayComp.hour = targetHour
            todayComp.minute = targetMinute
            todayComp.second = 0
            
            if let scheduledToday = calendar.date(from: todayComp), scheduledToday <= now {
                // Scheduled time for today has passed — check if we already showed it today
                let state = loadStateData()
                let dateOnlyFormatter = DateFormatter()
                dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
                let todayStr = dateOnlyFormatter.string(from: now)
                let lastPopupDate = state.last_daily_popup ?? ""
                
                if lastPopupDate != todayStr {
                    // Missed today's popup — fire it now
                    logMessage("Missed daily popup for today (\(todayStr)) — triggering now")
                    var updatedState = state
                    updatedState.last_daily_popup = todayStr
                    saveStateData(updatedState)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.performCheck(isManual: true)
                    }
                }
            }
        }
        
        // ── Schedule the next future daily popup ──────────────────────────
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
            // Record that we showed today's popup
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            var state = loadStateData()
            state.last_daily_popup = dateOnlyFormatter.string(from: Date())
            saveStateData(state)
            
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
        settingsWindowController?.loadCurrentValues()
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
        let state = loadStateData()
        let isAuth = (state.isAppleConnectAuthenticated == true)
        let internalModeActive = settings.enableInternalMode && isAuth
        
        logMessage("Fetching roles for \(settings.locationTitle) (Internal Mode: \(internalModeActive ? "ON" : "OFF"))...")
        
        let publicBaseUrl = settings.activeUrl
        let internalBaseUrl = settings.activeCareersUrl
        
        var publicJobs: [JobItem] = []
        var internalJobs: [JobItem] = []
        var ssoExpiredDetected = false
        let group = DispatchGroup()
        let lock = NSLock()
        
        func fetchChannel(baseUrlStr: String, isInternalChannel: Bool, cookies: [HTTPCookie]? = nil) {
            for page in 1...3 {
                let sep = baseUrlStr.contains("?") ? "&" : "?"
                let pageUrlStr = "\(baseUrlStr)\(sep)page=\(page)"
                guard let url = URL(string: pageUrlStr) else { continue }
                
                var request = URLRequest(url: url, timeoutInterval: 30)
                request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
                
                if let cookies = cookies, !cookies.isEmpty {
                    let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
                    for (k, v) in headerFields {
                        request.setValue(v, forHTTPHeaderField: k)
                    }
                }
                
                group.enter()
                URLSession.shared.dataTask(with: request) { data, response, error in
                    defer { group.leave() }
                    guard let data = data, error == nil,
                          let html = String(data: data, encoding: .utf8) else {
                        if let err = error {
                            logMessage("Fetch \(isInternalChannel ? "internal" : "public") page \(page) error: \(err.localizedDescription)")
                        }
                        return
                    }
                    
                    let pageJobs = parseJobsFromHTML(html, defaultSearchUrl: baseUrlStr, settings: settings, isInternal: isInternalChannel)
                    
                    if isInternalChannel && pageJobs.isEmpty {
                        let lowerHtml = html.lowercased()
                        if lowerHtml.contains("sign in with your apple account") || lowerHtml.contains("appleid.apple.com/auth/authorize") || lowerHtml.contains("login.apple.com") || lowerHtml.contains("appleconnect") {
                            lock.lock()
                            ssoExpiredDetected = true
                            lock.unlock()
                        }
                    }
                    
                    lock.lock()
                    if isInternalChannel {
                        internalJobs.append(contentsOf: pageJobs)
                    } else {
                        publicJobs.append(contentsOf: pageJobs)
                    }
                    lock.unlock()
                }.resume()
            }
        }
        
        if internalModeActive {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
                let appleCookies = cookies.filter { $0.domain.contains("apple.com") }
                
                if !settings.internalOnly {
                    fetchChannel(baseUrlStr: publicBaseUrl, isInternalChannel: false)
                }
                fetchChannel(baseUrlStr: internalBaseUrl, isInternalChannel: true, cookies: appleCookies)
                
                group.notify(queue: .main) {
                    self?.processFetchedJobs(publicJobs: publicJobs, internalJobs: internalJobs, ssoExpiredDetected: ssoExpiredDetected, internalModeActive: true, settings: settings, isManual: isManual)
                }
            }
        } else {
            fetchChannel(baseUrlStr: publicBaseUrl, isInternalChannel: false)
            
            group.notify(queue: .main) { [weak self] in
                self?.processFetchedJobs(publicJobs: publicJobs, internalJobs: [], ssoExpiredDetected: false, internalModeActive: false, settings: settings, isManual: isManual)
            }
        }
    }
    
    func processFetchedJobs(publicJobs: [JobItem], internalJobs: [JobItem], ssoExpiredDetected: Bool, internalModeActive: Bool, settings: AppSettings, isManual: Bool) {
        // 1. Deduplicate & sort public jobs
        var publicMap: [String: JobItem] = [:]
        var publicOrder: [String] = []
        for j in publicJobs {
            if publicMap[j.id] == nil {
                publicMap[j.id] = j
                publicOrder.append(j.id)
            }
        }
        let sortedPublic = publicOrder.compactMap { publicMap[$0] }.sorted { j1, j2 in
            let d1 = parsePostedDate(j1.posted)
            let d2 = parsePostedDate(j2.posted)
            if d1 != d2 { return d1 > d2 }
            return j1.id > j2.id
        }
        let top40Public = Array(sortedPublic.prefix(40))
        
        // 2. Deduplicate & sort internal jobs
        var internalMap: [String: JobItem] = [:]
        var internalOrder: [String] = []
        for j in internalJobs {
            if internalMap[j.id] == nil {
                internalMap[j.id] = j
                internalOrder.append(j.id)
            }
        }
        let sortedInternal = internalOrder.compactMap { internalMap[$0] }.sorted { j1, j2 in
            let d1 = parsePostedDate(j1.posted)
            let d2 = parsePostedDate(j2.posted)
            if d1 != d2 { return d1 > d2 }
            return j1.id > j2.id
        }
        let top40Internal = Array(sortedInternal.prefix(40))
        
        let publicIdSet = Set(top40Public.map { $0.id })
        let internalIdSet = Set(top40Internal.map { $0.id })
        
        // Build unified list for dashboard
        var unifiedMap: [String: JobItem] = [:]
        var unifiedOrder: [String] = []
        
        for j in (top40Internal + top40Public) {
            if let existing = unifiedMap[j.id] {
                if existing.isInternal != true && j.isInternal == true {
                    unifiedMap[j.id] = j
                }
            } else {
                unifiedMap[j.id] = j
                unifiedOrder.append(j.id)
            }
        }
        
        var displayJobs = unifiedOrder.compactMap { unifiedMap[$0] }.sorted { j1, j2 in
            let d1 = parsePostedDate(j1.posted)
            let d2 = parsePostedDate(j2.posted)
            if d1 != d2 { return d1 > d2 }
            return j1.id > j2.id
        }
        
        if internalModeActive && settings.internalOnly {
            displayJobs = top40Internal
        } else if !internalModeActive {
            displayJobs = top40Public
        }
        
        let totalUniqueRoles = displayJobs.count
        if internalModeActive {
            logMessage("Fetched \(totalUniqueRoles) total active roles (\(top40Internal.count) top internal, \(top40Public.count) top public) for \(settings.locationTitle)")
        } else {
            logMessage("Fetched \(displayJobs.count) total roles for \(settings.locationTitle)")
        }
        
        var state = loadStateData()
        let isFirstRun = state.seen_ids.isEmpty
        let seenSet = Set(state.seen_ids)
        
        let newJobs = isFirstRun ? [] : displayJobs.filter { !seenSet.contains($0.id) }
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        let timeStr = formatter.string(from: now)
        state.last_checked_str = timeStr
        state.last_job_count = displayJobs.count
        state.last_check_timestamp = now.timeIntervalSince1970
        
        if internalModeActive {
            if ssoExpiredDetected || internalJobs.isEmpty {
                state.ssoSessionExpired = true
                logMessage("⚠️ AppleConnect SSO session appears expired. Re-authentication needed.")
            } else {
                state.ssoSessionExpired = false
                state.isAppleConnectAuthenticated = true
            }
        } else {
            state.ssoSessionExpired = false
            state.isAppleConnectAuthenticated = false
        }
        
        let currentUnread = (state.unread_count ?? 0) + newJobs.count
        state.unread_count = currentUnread
        state.seen_ids = Array(Set(state.seen_ids + displayJobs.map { $0.id }))
        saveStateData(state)
        
        updateBadge(unreadCount: currentUnread)
        rebuildMenu()
        
        let effectiveInternalMode = internalModeActive && (state.ssoSessionExpired != true)
        let firstName = getUserFirstName()
        let modeSubtitle = effectiveInternalMode ? (settings.internalOnly ? " [Internal Only]" : " [Public + Internal]") : ""
        let greeting = effectiveInternalMode && !settings.internalOnly
            ? "Hi \(firstName) 👋 — \(top40Internal.count) Internal & \(top40Public.count) Public active roles tracked for <strong>\(settings.locationTitle)</strong>:"
            : "Hi \(firstName) 👋 — \(min(40, displayJobs.count)) latest active roles currently tracked for <strong>\(settings.locationTitle)</strong>\(modeSubtitle):"
            
        let htmlStr = generateDashboardHTML(jobs: displayJobs,
                                             internalIdSet: internalIdSet,
                                             publicIdSet: publicIdSet,
                                             internalTotalCount: top40Internal.count,
                                             publicTotalCount: top40Public.count,
                                             enableInternalMode: effectiveInternalMode,
                                             internalOnly: settings.internalOnly && effectiveInternalMode,
                                             greeting: greeting,
                                             locationTitle: "\(settings.locationTitle)\(modeSubtitle)",
                                             publicSearchUrl: settings.activeUrl,
                                             careersSearchUrl: settings.activeCareersUrl)
        
        try? htmlStr.write(to: dashboardFile, atomically: true, encoding: .utf8)
        
        if !newJobs.isEmpty {
            let plural = newJobs.count > 1 ? "s" : ""
            let internalNewCount = newJobs.filter { internalIdSet.contains($0.id) || ($0.isInternal == true) }.count
            let internalNote = internalNewCount > 0 ? " (\(internalNewCount)  internal)" : ""
            showNativeAlert(
                title: " \(newJobs.count) New Apple Job\(plural)!",
                message: "\(newJobs.count) brand new role\(plural) posted for \(settings.locationTitle)\(internalNote)!"
            )
        } else if isManual {
            showNativeAlert(
                title: " Jobs Monitor (\(settings.locationTitle))",
                message: "No new openings since last check. Dashboard is ready with latest roles!"
            )
        }
    }
    
    func showNativeAlert(title: String, message: String) {
        let settings = loadSettings()
        
        // Play custom notification sound if configured
        playNotificationSound(settings.notificationSound, volume: settings.notificationVolume)
        
        if settings.notificationStyle == 0 {
            // ── System Side Notification (Respects DND) ──────────────────
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    logMessage("UNUserNotificationCenter dispatch error: \(error.localizedDescription)")
                }
            }
        } else {
            // ── Mid-Screen Modal Window Popup Alert (Bypasses DND) ────────
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "View Dashboard")
            alert.addButton(withTitle: "Dismiss")
            
            let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
            if let img = NSImage(contentsOfFile: iconPath) {
                alert.icon = img
            }
            
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
    
    // ── UNUserNotificationCenterDelegate Implementation ──────────────────────
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .list])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                var state = loadStateData()
                state.unread_count = 0
                saveStateData(state)
                self?.updateBadge(unreadCount: 0)
                self?.rebuildMenu()
                NSWorkspace.shared.open(dashboardFile)
            }
        }
        completionHandler()
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

