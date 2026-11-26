import SwiftUI

struct TakvimView: View {
    @EnvironmentObject private var state: AppState
    @State private var mode = 0
    @State private var selected = Date()
    @State private var monthAnchor = Date()

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        c.locale = Loc.locale
        return c
    }

    var body: some View {
        NavigationStack {
            ScreenScroll {
                HStack(alignment: .bottom) {
                    ScreenTitle(title: Loc.s("Takvim"), subtitle: "\(state.place.city) · " + Loc.s("Diyanet hesaplaması"))
                    Button(Loc.s("Bugün")) { selected = Date(); monthAnchor = Date() }
                        .font(.subheadline.weight(.semibold))
                }
                Picker("", selection: $mode) {
                    Text(Loc.s("Haftalık")).tag(0)
                    Text(Loc.s("Aylık")).tag(1)
                    Text(Loc.s("Yıllık")).tag(2)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(Loc.s("Takvim görünümü"))

                switch mode {
                case 0: week
                case 1: month
                default: year
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: Week

    private var week: some View {
        let start = cal.dateInterval(of: .weekOfYear, for: selected)?.start ?? selected
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { selected = cal.date(byAdding: .day, value: -7, to: selected) ?? selected } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel(Loc.s("Önceki hafta"))
                Spacer()
                Text(verbatim: "\(Fmt.shortDate(days.first ?? start)) – \(Fmt.shortDate(days.last ?? start))").font(.headline)
                Spacer()
                Button { selected = cal.date(byAdding: .day, value: 7, to: selected) ?? selected } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel(Loc.s("Sonraki hafta"))
            }
            .foregroundStyle(Theme.text)
            Card(padding: 8) {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text(Loc.s("GÜN")).frame(width: 44, alignment: .leading)
                        ForEach(PrayerKind.allCases) { k in
                            Text(k.name.uppercased(with: Loc.locale)).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: .infinity)
                        }
                    }
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.muted)
                    .padding(.vertical, 6).padding(.horizontal, 6)
                    ForEach(days, id: \.self) { day in
                        let today = cal.isDateInToday(day)
                        let t = state.times(for: day)
                        HStack(spacing: 2) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(verbatim: "\(cal.component(.day, from: day))").font(.subheadline.bold())
                                Text(Fmt.weekdayShort(day)).font(.caption2.weight(.semibold)).opacity(0.75)
                            }
                            .frame(width: 44, alignment: .leading)
                            ForEach(PrayerKind.allCases) { k in
                                Text(t.map { Fmt.time($0.time(k)) } ?? "–")
                                    .font(.system(.footnote, design: .rounded)).monospacedDigit()
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 8).padding(.horizontal, 6)
                        .foregroundStyle(today ? Theme.cream : Theme.text)
                        .background(today ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Color.clear), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: Month

    private var month: some View {
        let interval = cal.dateInterval(of: .month, for: monthAnchor)!
        let first = interval.start
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let ordered = Array(symbols[(cal.firstWeekday - 1)...] + symbols[..<(cal.firstWeekday - 1)])
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return VStack(spacing: 12) {
            Card(padding: 10) {
                VStack(spacing: 6) {
                    HStack {
                        Button { monthAnchor = cal.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor } label: { Image(systemName: "chevron.left") }
                            .accessibilityLabel(Loc.s("Önceki ay"))
                        Spacer()
                        Text(Fmt.monthYear(first)).font(.headline)
                        Spacer()
                        Button { monthAnchor = cal.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor } label: { Image(systemName: "chevron.right") }
                            .accessibilityLabel(Loc.s("Sonraki ay"))
                    }
                    .foregroundStyle(Theme.text).padding(.horizontal, 6)
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(ordered.enumerated()), id: \.offset) { _, s in
                            Text(s).font(.caption2.bold()).foregroundStyle(Theme.muted)
                        }
                        ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 42) }
                        ForEach(1...count, id: \.self) { n in
                            let day = cal.date(byAdding: .day, value: n - 1, to: first)!
                            let isSel = cal.isDate(day, inSameDayAs: selected)
                            let isToday = cal.isDateInToday(day)
                            Button { selected = day } label: {
                                Text(verbatim: "\(n)").font(.subheadline.weight(isSel || isToday ? .bold : .medium))
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(isSel ? Theme.bordo : isToday ? Theme.soft : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(isSel ? Color.white : Theme.text)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Fmt.longDate(day))
                        }
                    }
                }
            }
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Fmt.longDate(selected)).font(.headline).foregroundStyle(Theme.text)
                    Text(PrayerEngine.hijriString(selected)).font(.footnote).foregroundStyle(Theme.muted)
                    if let t = state.times(for: selected) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(PrayerKind.allCases) { k in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(k.name).font(.caption.weight(.semibold)).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.7)
                                    Text(Fmt.time(t.time(k))).font(.system(.headline, design: .rounded)).monospacedDigit().foregroundStyle(Theme.text)
                                }
                                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Year

    private var year: some View {
        let y = cal.component(.year, from: selected)
        let months: [Date] = (1...12).compactMap { cal.date(from: DateComponents(year: y, month: $0, day: 1)) }
        let currentMonth = cal.component(.month, from: Date())
        return Card {
            VStack(spacing: 0) {
                HStack {
                    Text(Loc.s("AY (1.)")).frame(width: 84, alignment: .leading)
                    Text(Loc.s("GÜN UZUNLUĞU"))
                    Spacer()
                    Text(Loc.s("GÜNEŞ")).frame(width: 56, alignment: .trailing)
                    Text(Loc.s("AKŞAM")).frame(width: 56, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.muted).padding(.bottom, 8)
                ForEach(months, id: \.self) { m in
                    let t = state.times(for: m)
                    let rise = t?.time(.sunrise) ?? m, set = t?.time(.maghrib) ?? m
                    let length = set.timeIntervalSince(rise) / (17.5 * 3600)
                    let isCurrent = cal.component(.month, from: m) == currentMonth && cal.component(.year, from: m) == cal.component(.year, from: Date())
                    RowDivider()
                    HStack {
                        Text(m.formatted(.dateTime.month(.wide).locale(Loc.locale))).font(.subheadline.weight(isCurrent ? .bold : .medium))
                            .frame(width: 84, alignment: .leading)
                        GeometryReader { g in
                            Capsule().fill(Theme.line)
                                .overlay(alignment: .leading) {
                                    Capsule().fill(isCurrent ? Theme.accent : Theme.gold).frame(width: g.size.width * min(1, max(0, length)))
                                }
                        }
                        .frame(height: 8)
                        Text(Fmt.time(rise)).frame(width: 56, alignment: .trailing)
                        Text(Fmt.time(set)).frame(width: 56, alignment: .trailing)
                    }
                    .font(.system(.subheadline, design: .rounded)).monospacedDigit()
                    .foregroundStyle(Theme.text)
                    .frame(minHeight: 40)
                }
            }
        }
    }
}
