import Foundation
import UserNotifications

/// Schedules local notifications for the coming days (iOS keeps at most 64 pending requests).
enum NotificationService {
    static let center = UNUserNotificationCenter.current()

    enum Category {
        static let start = "PRAYER_START"
        static let end = "PRAYER_END"
    }
    enum Action {
        static let prayed = "PRAYED"
        static let snooze = "SNOOZE"
    }

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func registerCategories() {
        let prayed = UNNotificationAction(identifier: Action.prayed, title: Loc.s("Kıldım ✓"), options: [])
        let snooze = UNNotificationAction(identifier: Action.snooze, title: Loc.f("%lld dk ertele", 10), options: [])
        center.setNotificationCategories([
            UNNotificationCategory(identifier: Category.start, actions: [prayed], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: Category.end, actions: [prayed, snooze], intentIdentifiers: [], options: [])
        ])
    }

    // MARK: Scheduling

    private struct Pending {
        let id: String
        let date: Date
        let title: String
        let body: String
        let category: String?
        let sound: String
        let info: [String: String]
        let alwaysAllowed: Bool   // ignores quiet hours (fajr)
    }

    static func reschedule(place: Place, settings: NotifSettings, special: SpecialReminders, morningContent: Bool) async {
        center.removeAllPendingNotificationRequests()
        registerCategories()
        guard settings.master else { return }

        let cal = Calendar.current
        let now = Date()
        var items: [Pending] = []

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now),
                  let t = PrayerEngine.times(for: day, place: place) else { continue }
            let key = SharedStore.dayKey(day)

            for kind in PrayerKind.allCases {
                let s = settings.setting(kind)
                guard s.on else { continue }
                let start = t.time(kind)
                let info = ["kind": kind.rawValue, "day": key]
                let category = kind.isFard ? Category.start : nil

                items.append(Pending(id: "nv.\(key).\(kind.rawValue).start", date: start,
                                     title: Loc.f("%@ vakti girdi", kind.name),
                                     body: "\(place.city) · \(Fmt.time(start))",
                                     category: category, sound: s.sound, info: info, alwaysAllowed: kind == .fajr))
                if s.before > 0 {
                    let at = start.addingTimeInterval(TimeInterval(-s.before * 60))
                    items.append(Pending(id: "nv.\(key).\(kind.rawValue).before", date: at,
                                         title: Loc.f("%@ vaktine %lld dk kaldı", kind.name, s.before),
                                         body: "\(place.city) · \(Fmt.time(start))",
                                         category: nil, sound: "bildirim", info: info, alwaysAllowed: kind == .fajr))
                }
                if kind.isFard, s.beforeEnd > 0, !SharedStore.isPrayed(kind, on: day),
                   let end = PrayerEngine.endOfTime(for: kind, on: day, place: place) {
                    let at = end.addingTimeInterval(TimeInterval(-s.beforeEnd * 60))
                    items.append(Pending(id: endID(kind: kind, dayKey: key), date: at,
                                         title: Loc.f("%@ vaktinin çıkmasına %lld dk kaldı", kind.name, s.beforeEnd),
                                         body: Loc.s("Henüz “kıldım” olarak işaretlemedin."),
                                         category: Category.end, sound: "bildirim", info: info, alwaysAllowed: kind == .fajr))
                }
            }

            // Friday prayer
            if special.friday, cal.component(.weekday, from: day) == 6 {
                let at = t.time(.dhuhr).addingTimeInterval(-45 * 60)
                items.append(Pending(id: "nv.\(key).friday", date: at, title: Loc.s("Cuma namazı"),
                                     body: Loc.s("Cuma günü öğleden 45 dk önce"), category: nil, sound: "bildirim", info: [:], alwaysAllowed: false))
            }
            // Ramadan
            if PrayerEngine.isRamadan(day) {
                if special.suhoor {
                    let at = t.time(.fajr).addingTimeInterval(-45 * 60)
                    items.append(Pending(id: "nv.\(key).suhoor", date: at, title: Loc.s("Sahur (Ramazan)"),
                                         body: Loc.f("İmsak %@", Fmt.time(t.time(.fajr))), category: nil, sound: "bildirim", info: [:], alwaysAllowed: true))
                }
                if special.iftar {
                    items.append(Pending(id: "nv.\(key).iftar", date: t.time(.maghrib), title: Loc.s("İftar (Ramazan)"),
                                         body: Loc.s("Akşam vaktinde iftar bildirimi"), category: nil, sound: "ezan", info: [:], alwaysAllowed: true))
                }
            }
            // Holy nights (from the Umm al-Qura calendar; announced dates can differ by a day)
            if special.holyNights, let name = holyNightKey(on: day) {
                items.append(Pending(id: "nv.\(key).holy", date: t.time(.maghrib), title: Loc.s(name),
                                     body: Loc.s("Hayırlı geceler"), category: nil, sound: "bildirim", info: [:], alwaysAllowed: false))
            }
            // Makruh times
            if special.makruh {
                items.append(Pending(id: "nv.\(key).makruh1", date: t.time(.sunrise), title: Loc.s("Kerahat vakti"),
                                     body: Loc.s("Güneş doğduktan sonraki yaklaşık 45 dakika"), category: nil, sound: "bildirim", info: [:], alwaysAllowed: false))
                items.append(Pending(id: "nv.\(key).makruh2", date: t.time(.maghrib).addingTimeInterval(-45 * 60), title: Loc.s("Kerahat vakti"),
                                     body: Loc.s("Akşam vaktine kadar namaz kılınması mekruhtur"), category: nil, sound: "bildirim", info: [:], alwaysAllowed: false))
            }
            // Daily content
            if morningContent, let at = cal.date(bySettingHour: 8, minute: 0, second: 0, of: day) {
                let item = DailyContent.item(.ayet, for: day)
                items.append(Pending(id: "nv.\(key).content", date: at, title: Loc.s("GÜNÜN AYETİ"),
                                     body: item.localizedText, category: nil, sound: "bildirim", info: [:], alwaysAllowed: false))
            }
        }

        let upcoming = items
            .filter { $0.date > now }
            .filter { $0.alwaysAllowed || !settings.quietHours || !inQuietHours($0.date) }
            .sorted { $0.date < $1.date }
            .prefix(60)

        for p in upcoming {
            let content = UNMutableNotificationContent()
            content.title = p.title
            content.body = p.body
            content.userInfo = p.info
            if let c = p.category { content.categoryIdentifier = c }
            content.sound = sound(p.sound, vibrateOnly: settings.vibrateOnly)
            content.interruptionLevel = .timeSensitive
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: p.date)
            let request = UNNotificationRequest(identifier: p.id, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(request)
        }
    }

    static func endID(kind: PrayerKind, dayKey: String) -> String { "nv.\(dayKey).\(kind.rawValue).end" }

    static func removeEndWarning(kind: PrayerKind, day: Date) {
        center.removePendingNotificationRequests(withIdentifiers: [endID(kind: kind, dayKey: SharedStore.dayKey(day))])
    }

    static func snooze(_ content: UNNotificationContent, minutes: Int = 10) {
        guard let copy = content.mutableCopy() as? UNMutableNotificationContent else { return }
        let request = UNNotificationRequest(identifier: "nv.snooze.\(UUID().uuidString)", content: copy,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false))
        center.add(request)
    }

    static func sendNow(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "nv.now.\(UUID().uuidString)", content: content,
                                         trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)))
    }

    // MARK: Helpers

    /// Quiet hours: 23:00 – 04:30 (fajr is always delivered).
    private static func inQuietHours(_ date: Date) -> Bool {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return m >= 23 * 60 || m < 4 * 60 + 30
    }

    /// Custom adhan sounds are used when the files are in the app bundle (see README); otherwise the default sound.
    private static func sound(_ name: String, vibrateOnly: Bool) -> UNNotificationSound? {
        if vibrateOnly || name == "titresim" { return nil }
        let file: String? = name == "ezan" ? "ezan.caf" : name == "kisa" ? "ezan_kisa.caf" : nil
        if let file, Bundle.main.url(forResource: file, withExtension: nil) != nil {
            return UNNotificationSound(named: UNNotificationSoundName(file))
        }
        return .default
    }

    /// Evening before the holy night (the night begins at maghrib).
    private static func holyNightKey(on day: Date) -> String? {
        let cal = PrayerEngine.hijriCalendar
        guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { return nil }
        let m = cal.component(.month, from: next), d = cal.component(.day, from: next)
        switch (m, d) {
        case (3, 12): return "Mevlid Kandili"
        case (7, 27): return "Miraç Kandili"
        case (8, 15): return "Berat Kandili"
        case (9, 27): return "Kadir Gecesi"
        case (10, 1): return "Ramazan Bayramı"
        case (12, 10): return "Kurban Bayramı"
        default: return nil
        }
    }
}
