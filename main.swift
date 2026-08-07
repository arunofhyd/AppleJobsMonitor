import AppKit
import Foundation
import ServiceManagement
import SwiftUI
import UserNotifications

// ── Global Single-Source Constants ─────────────────────────────────────────────
let APP_VERSION = "2.1.7"
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

struct UpdateChangelogView: View {
    let changelog: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(changelog)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(width: 340, height: 140)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
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
    
    enum CodingKeys: String, CodingKey {
        case locationMode, countryIndex, cityIndex, customUrl, checkIntervalMinutes, popupDismissSeconds, notificationSound, notificationVolume, notificationStyle, enableDailyCheck, dailyCheckHour, dailyCheckMinute, activeDays, launchAtLogin
    }
    
    init(locationMode: Int, countryIndex: Int, cityIndex: Int, customUrl: String, checkIntervalMinutes: Int, popupDismissSeconds: Int, notificationSound: String, notificationVolume: Float = 1.0, notificationStyle: Int = 1, enableDailyCheck: Bool, dailyCheckHour: Int, dailyCheckMinute: Int, activeDays: [Bool], launchAtLogin: Bool) {
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

func getUserFirstName() -> String {
    let fullName = NSFullUserName()
    let firstName = fullName.components(separatedBy: " ").first ?? ""
    return firstName.isEmpty ? "There" : firstName
}

// ── HTML Dashboard Generator ───────────────────────────────────────────────────
func generateDashboardHTML(jobs: [JobItem], greeting: String, subtitle: String, locationTitle: String, searchUrl: String) -> String {
    var rows = ""
    for j in jobs {
        let careersUrl = j.url.replacingOccurrences(of: "jobs.apple.com", with: "careers.apple.com")
        rows += """
        <tr>
          <td class="cell">
            <a href="\(j.url)" class="job-link">\(j.title)</a>
            <br><span class="text-muted">\(j.team)</span>
          </td>
          <td class="cell text-muted">\(j.posted.isEmpty ? "—" : j.posted)</td>
          <td class="cell">\(j.location)</td>
          <td class="cell" style="text-align:right;">
            <a href="\(careersUrl)" class="careers-btn" target="_blank">Careers ↗</a>
          </td>
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
      .careers-btn {
        display: inline-block;
        padding: 2px 8px;
        background: transparent;
        color: var(--link);
        border: 1px solid var(--link);
        border-radius: 12px;
        font-size: 11px;
        font-weight: 500;
        text-decoration: none;
        transition: all 0.2s;
        line-height: 1.2;
      }
      .careers-btn:hover {
        background: var(--link);
        color: var(--btn-text);
        text-decoration: none;
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
          <div class="header-sub">\(subtitle)</div>
        </div>
        <div class="content">
          <p class="greeting">\(greeting)</p>
          <table>
            <thead><tr><th style="width: 50%;">Role</th><th style="width: 15%;">Posted</th><th style="width: 20%;">Location</th><th style="text-align:right; width: 15%;">PORTAL</th></tr></thead>
            <tbody>\(rows)</tbody>
          </table>
          <div class="btn-wrapper">
            <a href="\(searchUrl)" class="btn">View All Apple Jobs →</a>
          </div>
        </div>
        <div style="padding: 20px 32px; background: var(--bg-page); font-size: 13px; color: var(--text-sec); border-top: 1px solid var(--border); line-height: 1.8;">
          <strong style="color: var(--text-main);">Job Links:</strong> Clicking on the <strong style="color: var(--link);">job title</strong> takes you to the public jobs page, and clicking on the <span class="careers-btn" style="margin: 0 4px; pointer-events: none; padding: 1px 6px; font-size: 10px; display: inline-block; vertical-align: middle; position: relative; top: -1px;">Careers ↗</span> button takes you to the internal company posting if available.
        </div>
        <div class="footer">
          Jobs Monitor v\(APP_VERSION) · Built by Arun Thomas · Contact: \(CONTACT_EMAIL)<br>
          \(nowStr)
        </div>
      </div>
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
func parseJobsFromHTML(_ html: String, defaultSearchUrl: String, settings: AppSettings) -> [JobItem] {
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
                                if let item = normalizeJob(r, defaultUrl: defaultSearchUrl) {
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
    let url = "https://jobs.apple.com/en-us/details/\(pid)"
    
    return JobItem(id: pid, title: title, team: teamStr, location: locStr, posted: posted, url: url, countries: extractedCountries, cities: extractedCities)
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
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
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
class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
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
    var notificationStyleInfoBtn: NSButton!
    var dismissLabel: NSTextField!
    var dismissPopUp: NSPopUpButton!
    var soundPopUp: NSPopUpButton!
    var volumeSlider: NSSlider!
    var volumeValueLabel: NSTextField!
    
    var dailyCheckCheckbox: NSButton!
    var timePopUp: NSPopUpButton!
    var dayButtons: [NSButton] = []
    
    var launchAtLoginCheckbox: NSButton!
    
    var onSave: (() -> Void)?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 825),
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
        
        setupUI()
        loadCurrentValues()
    }
    
    func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // ── Top Header Banner (Centralized Logo Only) ─────────────────
        let headerView = SettingsHeaderView(frame: NSRect(x: 0, y: 735, width: 660, height: 90))
        
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
        
        // ── Card 1: Target Location (y: 560, height: 165) ────────────
        let card1 = createCardView(frame: NSRect(x: 24, y: 560, width: 612, height: 165))
        
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
        
        // ── Card 2: Refresh Frequency (y: 460, height: 85) ─────────
        let card2 = createCardView(frame: NSRect(x: 24, y: 460, width: 612, height: 85))
        
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
        
        // ── Card 3: Daily Summary (y: 310, height: 135) ─────────────
        let card3 = createCardView(frame: NSRect(x: 24, y: 310, width: 612, height: 135))
        
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
        
        // ── Card 4: Alerts & Notifications (y: 65, height: 230) ──────
        let card4 = createCardView(frame: NSRect(x: 24, y: 65, width: 612, height: 230))
        
        let card4Title = createSectionHeader(title: "Alerts & Notifications", iconName: "bell.fill", frame: NSRect(x: 16, y: 194, width: 580, height: 22))
        card4.addSubview(card4Title)
        
        // Row 1: Notification Style setting
        let styleLabel = NSTextField(labelWithString: "Notification Style")
        styleLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        styleLabel.frame = NSRect(x: 20, y: 154, width: 155, height: 20)
        card4.addSubview(styleLabel)
        
        notificationStylePopUp = NSPopUpButton(frame: NSRect(x: 185, y: 151, width: 363, height: 26))
        notificationStylePopUp.addItems(withTitles: ["System Notification Banner", "Mid-Screen Popup Window"])
        notificationStylePopUp.target = self
        notificationStylePopUp.action = #selector(notificationStyleChanged)
        card4.addSubview(notificationStylePopUp)
        
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
        let alert = NSAlert()
        alert.messageText = "Full Custom Search URL"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if currentUrl.isEmpty {
            alert.informativeText = "No URL pasted yet. Select 'Custom URL' and paste a search link from jobs.apple.com."
        } else {
            alert.informativeText = ""
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 460, height: 110))
            scrollView.hasVerticalScroller = true
            scrollView.borderType = .bezelBorder
            
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 460, height: 110))
            textView.isEditable = false
            textView.isSelectable = true
            textView.string = currentUrl
            textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            textView.textColor = .labelColor
            
            scrollView.documentView = textView
            alert.accessoryView = scrollView
        }
        
        alert.icon = NSImage(size: NSSize(width: 1, height: 1))
        alert.runModal()
    }

    @objc func showCustomUrlInstructions() {
        let alert = NSAlert()
        alert.messageText = "Custom Search URLs"
        alert.informativeText = """
        You can monitor specific job titles, teams, or custom search criteria by using a custom URL from Apple Jobs.

        Instructions:
        1. Open jobs.apple.com in your web browser.
        2. Search for your desired role or keywords (for example: "Python" or "iOS").
        3. Copy the complete URL from your browser's address bar.
        4. Select "Custom URL" in Jobs Monitor and paste the link.

        Note:
        Apple's search engine automatically scans your keywords across job titles, descriptions, responsibilities, and qualifications.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            alert.icon = img
        }
        alert.runModal()
    }
    
    @objc func showNotificationStyleInfo() {
        let alert = NSAlert()
        alert.messageText = "Notification Styles"
        alert.informativeText = """
        Jobs Monitor provides two notification delivery modes when new job openings are detected.

        • Mid-Screen Popup Window (Default)
        Displays an interactive alert window in the center of your screen. Mid-screen popup windows bypass macOS Do Not Disturb settings to ensure urgent postings are noticed immediately.

        • System Notification Banner
        Delivers standard macOS system notifications in the upper-right corner of your screen. System notification banners adhere to your macOS Do Not Disturb schedule.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png") ?? "/Applications/JobsMonitor.app/Contents/Resources/AppIcon.png"
        if let img = NSImage(contentsOfFile: iconPath) {
            alert.icon = img
        }
        alert.runModal()
    }

    private var volumePreviewTimer: Timer?

    @objc func notificationStyleChanged(_ sender: NSPopUpButton) {
        let isPopup = (sender.indexOfSelectedItem == 1)
        dismissPopUp.isEnabled = isPopup
        dismissLabel.textColor = isPopup ? .labelColor : .secondaryLabelColor
    }

    @objc func volumeSliderChanged(_ sender: NSSlider) {
        let pct = Int(sender.floatValue * 100)
        volumeValueLabel.stringValue = "\(pct)%"
        
        volumePreviewTimer?.invalidate()
        let currentVol = sender.floatValue
        volumePreviewTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let idx = self.soundPopUp.indexOfSelectedItem
            if idx >= 0 && idx < availableSounds.count {
                playNotificationSound(availableSounds[idx].nameOrPath, volume: currentVol)
            }
        }
    }

    @objc func soundPopUpChanged(_ sender: NSPopUpButton) {
        volumePreviewTimer?.invalidate()
        let idx = sender.indexOfSelectedItem
        if idx >= 0 && idx < availableSounds.count {
            playNotificationSound(availableSounds[idx].nameOrPath, volume: volumeSlider.floatValue)
        }
    }
    
    @objc func cancelClicked() {
        volumePreviewTimer?.invalidate()
        stopNotificationSound()
        window?.close()
    }
    
    @objc func radioChanged(_ sender: NSButton) {
        radioCountry.state = (sender.tag == 0) ? .on : .off
        radioCity.state = (sender.tag == 1) ? .on : .off
        radioCustom.state = (sender.tag == 2) ? .on : .off
        
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
        if selectedSoundIdx >= 0 && selectedSoundIdx < availableSounds.count {
            s.notificationSound = availableSounds[selectedSoundIdx].nameOrPath
        }
        
        s.enableDailyCheck = (dailyCheckCheckbox.state == .on)
        let selectedTimeOpt = timeOptions[max(0, min(timePopUp.indexOfSelectedItem, timeOptions.count - 1))]
        s.dailyCheckHour = selectedTimeOpt.hour
        s.dailyCheckMinute = selectedTimeOpt.minute
        s.activeDays = dayButtons.map { $0.state == .on }
        
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
    
    func menuWillOpen(_ menu: NSMenu) {
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
                let hosting = NSHostingView(rootView: UpdateChangelogView(changelog: changelog))
                hosting.frame = NSRect(x: 0, y: 0, width: 340, height: 140)
                alert.accessoryView = hosting
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
        logMessage("macOS woke from sleep — refreshing timers and checking scheduled daily digest")
        scheduleTimer()
        scheduleDailyTimer()
    }
    
    func scheduleTimer() {
        timer?.invalidate()
        let settings = loadSettings()
        let intervalSeconds = Double(settings.checkIntervalMinutes * 60)
        
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.performCheck(isManual: false)
            self?.scheduleDailyTimer()
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
            
            let jobs = parseJobsFromHTML(html, defaultSearchUrl: settings.activeUrl, settings: settings)
            logMessage("Fetched \(jobs.count) roles for \(settings.locationTitle)")
            
            var state = loadStateData()
            let isFirstRun = state.seen_ids.isEmpty
            let seenSet = Set(state.seen_ids)
            
            let newJobs = isFirstRun ? [] : jobs.filter { !seenSet.contains($0.id) }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, HH:mm"
            let timeStr = formatter.string(from: Date())
            state.last_checked_str = timeStr
            state.last_job_count = jobs.count
            
            DispatchQueue.main.async {
                let currentUnread = (state.unread_count ?? 0) + newJobs.count
                state.unread_count = currentUnread
                state.seen_ids = Array(Set(state.seen_ids + jobs.map { $0.id }))
                saveStateData(state)
                
                self.updateBadge(unreadCount: currentUnread)
                self.rebuildMenu()
                
                let firstName = getUserFirstName()
                let greeting = "Hi \(firstName) 👋 — \(jobs.count) active roles currently tracked for <strong>\(settings.locationTitle)</strong>:"
                let htmlStr = generateDashboardHTML(jobs: jobs.isEmpty ? [] : Array(jobs.prefix(20)),
                                                     greeting: greeting,
                                                     subtitle: "\(jobs.count) active openings",
                                                     locationTitle: settings.locationTitle,
                                                     searchUrl: settings.activeUrl)
                
                try? htmlStr.write(to: dashboardFile, atomically: true, encoding: .utf8)
                
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

