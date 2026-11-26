import Foundation
import Adhan

/// The six daily times. Sunrise is shown but is not a prayer (it cannot be tracked or made up).
enum PrayerKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    /// Turkish source string; translated through the string catalog.
    var key: String {
        switch self {
        case .fajr: return "İmsak"
        case .sunrise: return "Güneş"
        case .dhuhr: return "Öğle"
        case .asr: return "İkindi"
        case .maghrib: return "Akşam"
        case .isha: return "Yatsı"
        }
    }

    /// "Time until …" phrase. Turkish suffixes depend on the word, so each prayer has its own key.
    var untilKey: String {
        switch self {
        case .fajr: return "İmsak'a kalan"
        case .sunrise: return "Güneş'e kalan"
        case .dhuhr: return "Öğle'ye kalan"
        case .asr: return "İkindi'ye kalan"
        case .maghrib: return "Akşam'a kalan"
        case .isha: return "Yatsı'ya kalan"
        }
    }

    var name: String { Loc.s(key) }
    var isFard: Bool { self != .sunrise }
    static var fard: [PrayerKind] { allCases.filter { $0.isFard } }

    var symbol: String {
        switch self {
        case .fajr: return "moon.haze"
        case .sunrise: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }
}

struct DayTimes: Hashable {
    let day: Date
    let times: [PrayerKind: Date]

    func time(_ kind: PrayerKind) -> Date { times[kind] ?? day }
    var ordered: [(PrayerKind, Date)] { PrayerKind.allCases.map { ($0, time($0)) } }
}

/// Where we are in the day: the running time slot and the next one.
struct PrayerMoment: Hashable {
    let current: PrayerKind      // the slot we are in (after isha until fajr → isha of the previous day)
    let currentStart: Date
    let next: PrayerKind
    let nextDate: Date

    func progress(at now: Date) -> Double {
        let total = nextDate.timeIntervalSince(currentStart)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(currentStart) / total))
    }
}

enum PrayerEngine {
    /// Diyanet (Turkey) parameters. Diyanet uses the first shadow length (asr-ı evvel) for ikindi.
    static var parameters: CalculationParameters {
        var params = CalculationMethod.turkey.params
        params.madhab = .shafi
        return params
    }

    static func times(for day: Date, place: Place, calendar: Calendar? = nil) -> DayTimes? {
        let calendar = calendar ?? place.calendar
        let comps = calendar.dateComponents([.year, .month, .day], from: day)
        let coords = Coordinates(latitude: place.lat, longitude: place.lon)
        guard let p = PrayerTimes(coordinates: coords, date: comps, calculationParameters: parameters) else { return nil }
        let start = calendar.startOfDay(for: day)
        return DayTimes(day: start, times: [
            .fajr: p.fajr, .sunrise: p.sunrise, .dhuhr: p.dhuhr,
            .asr: p.asr, .maghrib: p.maghrib, .isha: p.isha
        ])
    }

    static func moment(at now: Date, place: Place, calendar: Calendar? = nil) -> PrayerMoment? {
        let calendar = calendar ?? place.calendar
        guard let today = times(for: now, place: place, calendar: calendar),
              let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now),
              let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now),
              let tomorrow = times(for: tomorrowDate, place: place, calendar: calendar),
              let yesterday = times(for: yesterdayDate, place: place, calendar: calendar) else { return nil }

        let list = today.ordered
        if now < today.time(.fajr) {
            return PrayerMoment(current: .isha, currentStart: yesterday.time(.isha), next: .fajr, nextDate: today.time(.fajr))
        }
        for (index, item) in list.enumerated() {
            let nextIndex = index + 1
            if nextIndex < list.count {
                let nextItem = list[nextIndex]
                if now >= item.1 && now < nextItem.1 {
                    return PrayerMoment(current: item.0, currentStart: item.1, next: nextItem.0, nextDate: nextItem.1)
                }
            }
        }
        return PrayerMoment(current: .isha, currentStart: today.time(.isha), next: .fajr, nextDate: tomorrow.time(.fajr))
    }

    /// End of a prayer's time: the start of the following time slot.
    static func endOfTime(for kind: PrayerKind, on day: Date, place: Place, calendar: Calendar? = nil) -> Date? {
        let calendar = calendar ?? place.calendar
        guard let t = times(for: day, place: place, calendar: calendar) else { return nil }
        switch kind {
        case .fajr: return t.time(.sunrise)
        case .sunrise: return t.time(.dhuhr)
        case .dhuhr: return t.time(.asr)
        case .asr: return t.time(.maghrib)
        case .maghrib: return t.time(.isha)
        case .isha:
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            return times(for: next, place: place, calendar: calendar)?.time(.fajr)
        }
    }

    static func qibla(_ place: Place) -> Double {
        Qibla(coordinates: Coordinates(latitude: place.lat, longitude: place.lon)).direction
    }

    /// Great-circle distance to the Kaaba in kilometres.
    static func distanceToKaaba(_ place: Place) -> Double {
        distance(from: place, toLat: 21.4225, lon: 39.8262)
    }

    static func distance(from place: Place, toLat lat2: Double, lon lon2: Double) -> Double {
        let r = 6371.0
        let la1 = place.lat * .pi / 180, la2 = lat2 * .pi / 180
        let dLa = (lat2 - place.lat) * .pi / 180, dLo = (lon2 - place.lon) * .pi / 180
        let a = sin(dLa / 2) * sin(dLa / 2) + cos(la1) * cos(la2) * sin(dLo / 2) * sin(dLo / 2)
        return 2 * r * atan2(sqrt(a), sqrt(1 - a))
    }

    // MARK: Hijri calendar and Ramadan

    static var hijriCalendar: Calendar {
        var c = Calendar(identifier: .islamicUmmAlQura)
        c.locale = Loc.locale
        return c
    }

    static func hijriString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = hijriCalendar
        f.locale = Loc.locale
        f.dateFormat = "d MMMM y"
        return f.string(from: date)
    }

    static func isRamadan(_ date: Date) -> Bool {
        hijriCalendar.component(.month, from: date) == 9
    }

    static func ramadanDay(_ date: Date) -> Int? {
        isRamadan(date) ? hijriCalendar.component(.day, from: date) : nil
    }

    static func hijriYear(_ date: Date) -> Int { hijriCalendar.component(.year, from: date) }
}

// MARK: - Formatting helpers

enum Fmt {
    static var timeZone: TimeZone { SharedStore.place.timeZone }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.locale = Loc.locale
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Loc.locale
        f.timeZone = timeZone
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMMy")
        return f.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Loc.locale
        f.setLocalizedDateFormatFromTemplate("dMMMEEE")
        return f.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Loc.locale
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: date)
    }

    static func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Loc.locale
        f.setLocalizedDateFormatFromTemplate("MMMMy")
        return f.string(from: date)
    }

    static func countdown(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
    }

    static func minutes(_ seconds: TimeInterval) -> Int { max(0, Int((seconds / 60).rounded(.up))) }

    /// "in 25 min" / "in 8 h 5 min"
    static func inRelative(_ seconds: TimeInterval) -> String {
        let m = minutes(seconds)
        return m >= 60 ? Loc.f("%lld sa %lld dk sonra", m / 60, m % 60) : Loc.f("%lld dk sonra", m)
    }

    static func km(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Loc.locale
        f.maximumFractionDigits = value < 10 ? 1 : 0
        return (f.string(from: NSNumber(value: value)) ?? "\(Int(value))") + " km"
    }
}
