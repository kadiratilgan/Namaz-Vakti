import WidgetKit
import SwiftUI

/// Timeline shared by the iPhone widgets and the Apple Watch complications.
struct PrayerEntry: TimelineEntry {
    let date: Date
    let place: Place
    let times: DayTimes?
    let moment: PrayerMoment?
    let prayedToday: Int
    let streak: Int
    let isRamadan: Bool
    let ramadanDay: Int?
    let iftar: Date?
    let nextImsak: Date?
    let content: ContentItem

    static func make(at date: Date) -> PrayerEntry {
        let place = SharedStore.place
        let times = PrayerEngine.times(for: date, place: place)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        let ramadanOn = SharedStore.bool(SharedStore.Key.ramadanAuto, default: true) && PrayerEngine.isRamadan(date)
        return PrayerEntry(
            date: date, place: place, times: times,
            moment: PrayerEngine.moment(at: date, place: place),
            prayedToday: SharedStore.prayedCount(on: date),
            streak: SharedStore.streak(now: date),
            isRamadan: ramadanOn,
            ramadanDay: PrayerEngine.ramadanDay(date),
            iftar: times?.time(.maghrib),
            nextImsak: PrayerEngine.times(for: tomorrow, place: place)?.time(.fajr),
            content: DailyContent.item(.ayet, for: date))
    }
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry { .make(at: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(.make(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let now = Date()
        var dates: [Date] = [now]
        let place = SharedStore.place
        for offset in 0...1 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: now),
                  let t = PrayerEngine.times(for: day, place: place) else { continue }
            dates += PrayerKind.allCases.map { t.time($0).addingTimeInterval(1) }.filter { $0 > now }
            if let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: day)) {
                dates.append(midnight.addingTimeInterval(1))
            }
        }
        let entries = Array(Set(dates)).sorted().prefix(16).map { PrayerEntry.make(at: $0) }
        let refresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        completion(Timeline(entries: Array(entries), policy: .after(min(refresh, entries.last?.date ?? refresh))))
    }
}

// MARK: - Views used on both platforms

/// Countdown that the system keeps ticking without new timeline entries.
struct Countdown: View {
    let to: Date
    var body: some View {
        Text(timerInterval: Date()...max(Date(), to), countsDown: true)
            .monospacedDigit()
    }
}

struct RingProgress: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    var color: Color = Theme.gold
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.25), lineWidth: lineWidth)
            Circle().trim(from: 0, to: progress).stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct AccessoryCircularView: View {
    let entry: PrayerEntry
    var body: some View {
        if let m = entry.moment {
            ZStack {
                AccessoryWidgetBackground()
                ProgressView(timerInterval: m.currentStart...max(m.currentStart.addingTimeInterval(1), m.nextDate), countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    VStack(spacing: 0) {
                        Text(verbatim: "\(Fmt.minutes(m.nextDate.timeIntervalSince(entry.date)))").font(.system(.body, design: .rounded).bold())
                        Text(verbatim: m.next.name.prefix(3).uppercased()).font(.system(size: 8, weight: .bold))
                    }
                }
                .progressViewStyle(.circular)
            }
            .widgetAccentable()
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerEntry
    var body: some View {
        if let m = entry.moment {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(m.next.name.uppercased(with: Loc.locale)) \(Fmt.time(m.nextDate))")
                    .font(.headline).widgetAccentable()
                Countdown(to: m.nextDate).font(.body)
                ProgressView(value: m.progress(at: entry.date)).tint(Theme.gold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AccessoryInlineView: View {
    let entry: PrayerEntry
    var body: some View {
        if let m = entry.moment {
            Text(verbatim: "\(m.next.name) \(Fmt.time(m.nextDate))")
        }
    }
}
