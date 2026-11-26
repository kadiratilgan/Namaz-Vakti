import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct Place: Codable, Equatable, Hashable {
    var lat: Double
    var lon: Double
    var city: String
    var tz: String? = nil

    static let fallback = Place(lat: 41.0082, lon: 28.9784, city: "İstanbul", tz: "Europe/Istanbul")

    /// Prayer times are shown in the place's own time zone (e.g. a manually chosen city abroad).
    var timeZone: TimeZone { tz.flatMap(TimeZone.init(identifier:)) ?? .current }

    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }
}

/// Settings and records shared by the app, its widgets and (on the watch) the watch app.
/// The app and the iPhone widgets share one App Group container.
enum SharedStore {
    static let groupID = "group.com.kadiratilgan.namazvakti"
    static let defaults: UserDefaults = UserDefaults(suiteName: groupID) ?? .standard

    // MARK: Keys
    enum Key {
        static let place = "place"
        static let placeIsSet = "placeIsSet"
        static let autoLocation = "autoLocation"
        static let language = "appLanguage"      // "oto", "tr", "en", "de"
        static let theme = "theme"               // "sistem", "acik", "koyu"
        static let prayed = "prayed"             // [dayKey: [PrayerKind.rawValue]]
        static let kaza = "kaza"                 // [name: count]
        static let fasting = "fasting"           // [dayKey: "tuttu" | "kaza"]
        static let notif = "notifSettings"
        static let special = "specialReminders"
        static let liveActivity = "liveActivity"
        static let dynamicIsland = "dynamicIsland"
        static let travelMode = "travelMode"
        static let travelNotify = "travelNotify"
        static let travelDistance = "travelDistance"
        static let travelSafar = "travelSafar"
        static let recentCities = "recentCities"
        static let savedContent = "savedContent"
        static let contentOnHome = "contentOnHome"
        static let contentMorning = "contentMorning"
        static let ramadanAuto = "ramadanAuto"
        static let zikir = "zikirState"
        static let zikirHaptics = "zikirHaptics"
        static let onboarded = "onboarded"
        static let siriSuggestions = "siriSuggestions"
    }

    // MARK: Generic Codable helpers
    static func get<T: Decodable>(_ key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func set<T: Encodable>(_ value: T, for key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    static func bool(_ key: String, default value: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? value : defaults.bool(forKey: key)
    }

    // MARK: Place
    static var place: Place {
        get { get(Key.place, as: Place.self) ?? .fallback }
        set { set(newValue, for: Key.place); defaults.set(true, forKey: Key.placeIsSet) }
    }

    static var placeIsSet: Bool { defaults.bool(forKey: Key.placeIsSet) }

    // MARK: Day keys
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Prayer tracking
    static var prayedLog: [String: [String]] {
        get { get(Key.prayed, as: [String: [String]].self) ?? [:] }
        set { set(newValue, for: Key.prayed) }
    }

    static func isPrayed(_ kind: PrayerKind, on day: Date) -> Bool {
        prayedLog[dayKey(day)]?.contains(kind.rawValue) ?? false
    }

    static func setPrayed(_ kind: PrayerKind, on day: Date, _ value: Bool) {
        var log = prayedLog
        var list = Set(log[dayKey(day)] ?? [])
        if value { list.insert(kind.rawValue) } else { list.remove(kind.rawValue) }
        log[dayKey(day)] = Array(list)
        prayedLog = log
        reloadWidgets()
    }

    static func prayedCount(on day: Date) -> Int {
        PrayerKind.fard.filter { isPrayed($0, on: day) }.count
    }

    /// Consecutive full days (5/5) ending yesterday, plus today if already complete.
    static func streak(now: Date = Date(), calendar: Calendar = .current) -> Int {
        var count = 0
        var day = now
        if prayedCount(on: day) == 5 { count += 1 }
        while let prev = calendar.date(byAdding: .day, value: -1, to: day) {
            day = prev
            if prayedCount(on: day) == 5 { count += 1 } else { break }
            if count > 3650 { break }
        }
        return count
    }

    // MARK: Kaza (missed prayers)
    static var kaza: [String: Int] {
        get { get(Key.kaza, as: [String: Int].self) ?? [:] }
        set { set(newValue, for: Key.kaza) }
    }

    // MARK: Fasting
    static var fasting: [String: String] {
        get { get(Key.fasting, as: [String: String].self) ?? [:] }
        set { set(newValue, for: Key.fasting); reloadWidgets() }
    }

    static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

// MARK: - Notification settings

struct PrayerNotifSetting: Codable, Equatable {
    var on: Bool
    var before: Int      // minutes before the time starts, 0 = off
    var beforeEnd: Int   // minutes before the time ends, 0 = off
    var sound: String    // "ezan", "kisa", "bildirim", "titresim"
}

struct NotifSettings: Codable, Equatable {
    var master: Bool = true
    var perPrayer: [String: PrayerNotifSetting] = [
        PrayerKind.fajr.rawValue: .init(on: true, before: 30, beforeEnd: 0, sound: "kisa"),
        PrayerKind.sunrise.rawValue: .init(on: false, before: 0, beforeEnd: 0, sound: "bildirim"),
        PrayerKind.dhuhr.rawValue: .init(on: true, before: 15, beforeEnd: 30, sound: "ezan"),
        PrayerKind.asr.rawValue: .init(on: true, before: 15, beforeEnd: 30, sound: "ezan"),
        PrayerKind.maghrib.rawValue: .init(on: true, before: 10, beforeEnd: 15, sound: "ezan"),
        PrayerKind.isha.rawValue: .init(on: true, before: 15, beforeEnd: 45, sound: "kisa")
    ]
    var quietHours: Bool = true
    var showRemaining: Bool = true
    var vibrateOnly: Bool = false

    func setting(_ kind: PrayerKind) -> PrayerNotifSetting {
        perPrayer[kind.rawValue] ?? .init(on: true, before: 0, beforeEnd: 0, sound: "bildirim")
    }

    static var stored: NotifSettings {
        get { SharedStore.get(SharedStore.Key.notif, as: NotifSettings.self) ?? NotifSettings() }
        set { SharedStore.set(newValue, for: SharedStore.Key.notif) }
    }
}

struct SpecialReminders: Codable, Equatable {
    var friday = true
    var suhoor = true
    var iftar = true
    var holyNights = true
    var makruh = false

    static var stored: SpecialReminders {
        get { SharedStore.get(SharedStore.Key.special, as: SpecialReminders.self) ?? SpecialReminders() }
        set { SharedStore.set(newValue, for: SharedStore.Key.special) }
    }
}

// MARK: - Localisation with an in-app language override

enum Loc {
    /// nil = follow the device ("Otomatik").
    static var override: String? {
        let v = SharedStore.defaults.string(forKey: SharedStore.Key.language) ?? "oto"
        return ["tr", "en", "de"].contains(v) ? v : nil
    }

    private static var cachedBundle: (String, Bundle)?

    static var bundle: Bundle {
        guard let lang = override else { return .main }
        if let c = cachedBundle, c.0 == lang { return c.1 }
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: path) {
            cachedBundle = (lang, b)
            return b
        }
        return .main
    }

    /// The language actually in use (for "Otomatik · currently …").
    static var activeLanguage: String {
        if let o = override { return o }
        let pref = Bundle.main.preferredLocalizations.first ?? "en"
        return ["tr", "en", "de"].contains(pref) ? pref : "en"
    }

    static var locale: Locale { Locale(identifier: activeLanguage) }

    static func s(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: s(key), locale: locale, arguments: args)
    }
}
