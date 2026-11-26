import WidgetKit
import SwiftUI
import ActivityKit

@main
struct NamazVaktiWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        SixTimesWidget()
        DailyContentWidget()
        RamadanWidget()
        TrackingWidget()
        PrayerLiveActivity()
    }
}

private extension View {
    func brandBackground() -> some View {
        containerBackground(for: .widget) { Theme.heroGradient }
    }
    func cardBackground() -> some View {
        containerBackground(for: .widget) { Theme.card }
    }
}

// MARK: - Next prayer (all sizes + Lock Screen)

struct NextPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPrayer", provider: PrayerProvider()) { entry in
            NextPrayerView(entry: entry)
        }
        .configurationDisplayName(Loc.s("Sıradaki vakit"))
        .description(Loc.s("Sıradaki vakte kalan süre ve günün vakitleri"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct NextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        switch family {
        case .accessoryCircular: AccessoryCircularView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular: AccessoryRectangularView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .accessoryInline: AccessoryInlineView(entry: entry).containerBackground(for: .widget) { Color.clear }
        case .systemMedium: medium.brandBackground()
        case .systemLarge: large.brandBackground()
        default: small.brandBackground()
        }
    }

    private var small: some View {
        VStack(spacing: 6) {
            if let m = entry.moment {
                ZStack {
                    RingProgress(progress: m.progress(at: entry.date), lineWidth: 8)
                    VStack(spacing: 0) {
                        Text(verbatim: "\(Fmt.minutes(m.nextDate.timeIntervalSince(entry.date)))")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text(Loc.s("dakika")).font(.caption2).foregroundStyle(Theme.goldText)
                    }
                }
                .frame(width: 92, height: 92)
                Text(verbatim: "\(m.next.name) · \(Fmt.time(m.nextDate))").font(.footnote.weight(.semibold))
            }
        }
        .foregroundStyle(Theme.cream)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            if let m = entry.moment {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: "\(Loc.s("Şu an")) · \(entry.place.city)").font(.caption).foregroundStyle(Theme.goldText)
                    Text(m.current.name).font(.title3.bold())
                    Spacer(minLength: 0)
                    Text(Loc.s(m.next.untilKey)).font(.caption).foregroundStyle(Theme.goldText)
                    Countdown(to: m.nextDate).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                }
                .frame(width: 118, alignment: .leading)
            }
            if let t = entry.times {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            timeCell(PrayerKind.allCases[row], t)
                            timeCell(PrayerKind.allCases[row + 3], t)
                        }
                    }
                }
            }
        }
        .foregroundStyle(Theme.cream)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Loc.s("Namaz Vakti")).font(.subheadline.bold())
                Spacer()
                Text(verbatim: entry.place.city).font(.caption).foregroundStyle(Theme.goldText)
            }
            if let m = entry.moment {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(Loc.s("Şu anki vakit")).font(.caption).foregroundStyle(Theme.goldText)
                        Text(m.current.name).font(.title2.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(Loc.s(m.next.untilKey)).font(.caption).foregroundStyle(Theme.goldText)
                        Countdown(to: m.nextDate).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                            .multilineTextAlignment(.trailing)
                    }
                }
                ProgressView(value: m.progress(at: entry.date)).tint(Theme.gold)
            }
            if let t = entry.times {
                VStack(spacing: 2) {
                    ForEach(PrayerKind.allCases) { k in
                        HStack {
                            Text(k.name)
                            Spacer()
                            Text(Fmt.time(t.time(k))).monospacedDigit().fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(k == entry.moment?.next ? Theme.gold : Theme.cream)
                        .padding(.horizontal, 10).frame(height: 28)
                        .background(k == entry.moment?.current ? Theme.gold.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .foregroundStyle(Theme.cream)
    }

    private func timeCell(_ k: PrayerKind, _ t: DayTimes) -> some View {
        HStack {
            Text(k.name).lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(Fmt.time(t.time(k))).monospacedDigit().fontWeight(.bold)
        }
        .font(.caption)
        .foregroundStyle(k == entry.moment?.next ? Theme.gold : Theme.cream)
    }
}

// MARK: - Square widget with all six times

struct SixTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SixTimes", provider: PrayerProvider()) { entry in
            SixTimesView(entry: entry).cardBackground()
        }
        .configurationDisplayName(Loc.s("Günün vakitleri"))
        .description(Loc.s("Altı vakit küçük bir karede"))
        .supportedFamilies([.systemSmall])
    }
}

struct SixTimesView: View {
    let entry: PrayerEntry
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(verbatim: entry.place.city).font(.caption2.bold()).lineLimit(1)
                Spacer()
                if let m = entry.moment {
                    Text(verbatim: "\(m.next.name) \(Fmt.minutes(m.nextDate.timeIntervalSince(entry.date))) " + Loc.s("dk"))
                        .font(.caption2.bold()).foregroundStyle(Theme.accent).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            if let t = entry.times {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)], spacing: 4) {
                    ForEach(PrayerKind.allCases) { k in
                        let next = k == entry.moment?.next
                        VStack(alignment: .leading, spacing: 0) {
                            Text(k.name).font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.7)
                                .foregroundStyle(next ? Theme.onAccent : Theme.muted)
                            Text(Fmt.time(t.time(k))).font(.system(size: 15, weight: .bold, design: .rounded)).monospacedDigit()
                                .foregroundStyle(next ? Theme.onAccent : Theme.text)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(next ? Theme.accent : Theme.line.opacity(0.6), in: RoundedRectangle(cornerRadius: 9))
                    }
                }
            }
        }
    }
}

// MARK: - Verse / hadith of the day

struct DailyContentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DailyContent", provider: PrayerProvider()) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(Loc.s("GÜNÜN AYETİ")).font(.caption2.bold()).tracking(0.8).foregroundStyle(Theme.goldInk)
                Text(verbatim: "“\(entry.content.localizedText)”").font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Theme.text).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text(entry.content.localizedSource).font(.caption2).foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .cardBackground()
        }
        .configurationDisplayName(Loc.s("Günün ayeti"))
        .description(Loc.s("Her gün yeni bir ayet"))
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Ramadan

struct RamadanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Ramadan", provider: PrayerProvider()) { entry in
            RamadanWidgetView(entry: entry)
        }
        .configurationDisplayName(Loc.s("Ramazan"))
        .description(Loc.s("İftar ve sahur geri sayımı; Ramazan dışında sıradaki vakit"))
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct RamadanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    private var target: (String, Date)? {
        guard entry.isRamadan, let iftar = entry.iftar, let imsak = entry.nextImsak else { return nil }
        return entry.date < iftar ? ("İftara kalan", iftar) : ("Sahura kalan", imsak)
    }

    var body: some View {
        if family == .accessoryRectangular {
            VStack(alignment: .leading) {
                if let t = target {
                    Text(Loc.s(t.0)).font(.headline).widgetAccentable()
                    Countdown(to: t.1)
                } else {
                    AccessoryRectangularView(entry: entry)
                }
            }
            .containerBackground(for: .widget) { Color.clear }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let t = target {
                    Text(Loc.s(t.0)).font(.caption).foregroundStyle(Theme.goldText)
                    Countdown(to: t.1).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(Loc.s("İftar")) \(entry.iftar.map(Fmt.time) ?? "") · " + Loc.f("%lld. gün", entry.ramadanDay ?? 1))
                        .font(.caption2)
                } else if let m = entry.moment {
                    Text(Loc.s(m.next.untilKey)).font(.caption).foregroundStyle(Theme.goldText)
                    Countdown(to: m.nextDate).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(m.next.name) \(Fmt.time(m.nextDate))").font(.caption2)
                }
            }
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .brandBackground()
        }
    }
}

// MARK: - Prayer tracking

struct TrackingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Tracking", provider: PrayerProvider()) { entry in
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.s("BUGÜN")).font(.caption.bold()).foregroundStyle(Theme.accent)
                Text(verbatim: "\(entry.prayedToday)/5").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                HStack(spacing: 5) {
                    ForEach(PrayerKind.fard) { k in
                        let done = SharedStore.isPrayed(k, on: entry.date)
                        let next = k == entry.moment?.next
                        Circle().fill(done ? Theme.accent : Theme.line)
                            .overlay(Circle().stroke(next ? Theme.gold : Color.clear, lineWidth: 2))
                            .frame(width: 18, height: 18)
                    }
                }
                Spacer(minLength: 0)
                Text(Loc.f("%lld gün seri", entry.streak)).font(.caption).foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(URL(string: "namazvakti://takip"))
            .cardBackground()
        }
        .configurationDisplayName(Loc.s("Namaz takibi"))
        .description(Loc.s("Bugün kılınan vakitler ve serin"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Live Activity (Lock Screen + Dynamic Island)

struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            let s = context.state
            let current = PrayerKind(rawValue: s.currentKey) ?? .dhuhr
            let next = PrayerKind(rawValue: s.nextKey) ?? .asr
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    AppBadge(size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Loc.f("%@ vakti devam ediyor", current.name)).font(.caption).foregroundStyle(Theme.goldText)
                        Text(Loc.s(next.untilKey)).font(.headline).foregroundStyle(Theme.cream)
                    }
                    Spacer()
                    Countdown(to: s.nextDate).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                        .multilineTextAlignment(.trailing).frame(maxWidth: 110)
                }
                ProgressView(timerInterval: s.currentStart...max(s.currentStart.addingTimeInterval(1), s.nextDate), countsDown: false) {
                    EmptyView()
                } currentValueLabel: { EmptyView() }
                .tint(Theme.gold)
                HStack {
                    Text(verbatim: "\(current.name) \(Fmt.time(s.currentStart))")
                    Spacer()
                    Text(verbatim: "\(next.name) \(Fmt.time(s.nextDate))")
                }
                .font(.caption).foregroundStyle(Theme.goldText)
            }
            .padding(16)
            .activityBackgroundTint(Color(hex: 0x14090B))
            .activitySystemActionForegroundColor(Theme.cream)
        } dynamicIsland: { context in
            let s = context.state
            let next = PrayerKind(rawValue: s.nextKey) ?? .asr
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(next.name, systemImage: next.symbol).font(.headline).foregroundStyle(Theme.gold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(to: s.nextDate).font(.headline).foregroundStyle(Theme.gold).frame(maxWidth: 90)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(verbatim: "\(context.attributes.city) · \(next.name) \(Fmt.time(s.nextDate))").font(.caption).foregroundStyle(Theme.goldText)
                }
            } compactLeading: {
                Image(systemName: next.symbol).foregroundStyle(Theme.gold)
            } compactTrailing: {
                Countdown(to: s.nextDate).font(.caption.bold()).foregroundStyle(Theme.gold).frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "clock").foregroundStyle(Theme.gold)
            }
        }
    }
}
