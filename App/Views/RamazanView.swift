import SwiftUI

struct RamazanView: View {
    @EnvironmentObject private var state: AppState

    /// Days of the current Ramadan, or of the next one if it hasn't started yet.
    private var ramadanDays: [Date] {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if let d = PrayerEngine.ramadanDay(day) {
            day = cal.date(byAdding: .day, value: -(d - 1), to: day) ?? day
        } else {
            for _ in 0..<400 {
                guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
                if PrayerEngine.ramadanDay(day) == 1 { break }
            }
        }
        var list: [Date] = []
        var d = day
        while PrayerEngine.isRamadan(d) && list.count < 30 {
            list.append(d)
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return list
    }

    var body: some View {
        let _ = state.revision
        let days = ramadanDays
        let first = days.first ?? Date()
        let last = days.last ?? Date()
        ScreenScroll {
            ScreenTitle(title: Loc.f("Ramazan %@", String(PrayerEngine.hijriYear(first))),
                        subtitle: "\(Fmt.shortDate(first)) – \(Fmt.shortDate(last)) · \(state.place.city)")
            TimelineView(.periodic(from: .now, by: 1)) { ctx in countdown(now: ctx.date, days: days) }

            SectionTitle(key: "ORUÇ TAKİBİ")
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                        ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                            fastCell(day: day, number: index + 1)
                        }
                    }
                    HStack(spacing: 14) {
                        legend(Theme.gold, filled: true, "Tutuldu")
                        legend(Color(hex: 0xB3261E), filled: false, "Kazaya kaldı")
                        legend(Theme.line, filled: true, "Henüz gelmedi")
                    }
                    .font(.caption).foregroundStyle(Theme.muted)
                    RowDivider()
                    let values = days.compactMap { SharedStore.fasting[SharedStore.dayKey($0)] }
                    HStack {
                        Text(Loc.f("%lld gün tutuldu · %lld kaza", values.filter { $0 == "tuttu" }.count, values.filter { $0 == "kaza" }.count))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                        Spacer()
                        Text(Loc.s("Güne dokunarak değiştir")).font(.caption).foregroundStyle(Theme.muted)
                    }
                }
            }

            SectionTitle(key: "RAMAZAN AYARLARI")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ToggleRow(title: Loc.s("Ramazan modu"), subtitle: Loc.s("Ramazan başlayınca otomatik açılır"), isOn: $state.ramadanAuto)
                    RowDivider()
                    ToggleRow(title: Loc.s("Sahur hatırlatması"), subtitle: Loc.s("İmsaktan 45 dk önce uyandırır"), isOn: $state.special.suhoor)
                    RowDivider()
                    ToggleRow(title: Loc.s("İftar bildirimi"), subtitle: Loc.s("Akşam vaktinde, ezan sesiyle"), isOn: $state.special.iftar)
                }
                .padding(.horizontal, 14)
            }

            SectionTitle(key: "İMSAKİYE")
            Card(padding: 8) {
                VStack(spacing: 2) {
                    HStack {
                        Text(Loc.s("GÜN")).frame(width: 40, alignment: .leading)
                        Text(Loc.s("TARİH"))
                        Spacer()
                        Text(Loc.s("İMSAK")).frame(width: 60, alignment: .trailing)
                        Text(Loc.s("İFTAR")).frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.muted).padding(.horizontal, 8).padding(.vertical, 8)
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        imsakiyeRow(day: day, number: index + 1, total: days.count)
                    }
                }
            }
            Text(Loc.s("Ramazan tarihleri Ümmü'l-Kurâ takvimine göre hesaplanır; Diyanet'in ilan ettiği tarihlerden bir gün farklı olabilir."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func countdown(now: Date, days: [Date]) -> some View {
        let inRamadan = PrayerEngine.isRamadan(now)
        let t = state.times(for: now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let iftar = t?.time(.maghrib) ?? now
        let nextImsak = state.times(for: tomorrow)?.time(.fajr) ?? now
        VStack(alignment: .leading, spacing: 12) {
            if inRamadan {
                Text(Loc.s(now < iftar ? "İftara kalan" : "Sahura kalan")).font(.footnote).foregroundStyle(Theme.goldText)
                Text(Fmt.countdown((now < iftar ? iftar : nextImsak).timeIntervalSince(now)))
                    .font(.system(size: 54, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(Theme.gold)
                HStack(spacing: 10) {
                    tile(Loc.s("Bugün iftar"), Fmt.time(iftar))
                    tile(Loc.s("Yarın sahur bitişi"), Fmt.time(nextImsak))
                }
            } else if let first = days.first {
                Text(Loc.s("Ramazan'a kalan")).font(.footnote).foregroundStyle(Theme.goldText)
                let n = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: first).day ?? 0
                Text(Loc.f("%lld gün", n)).font(.system(size: 54, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                Text(Loc.f("İlk oruç: %@", Fmt.longDate(first))).font(.subheadline)
            }
        }
        .foregroundStyle(Theme.cream)
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func tile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(Theme.goldText)
            Text(value).font(.title3.bold()).monospacedDigit()
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private func fastCell(day: Date, number: Int) -> some View {
        let key = SharedStore.dayKey(day)
        let value = SharedStore.fasting[key]
        let isToday = Calendar.current.isDateInToday(day)
        let future = day > Date() && !isToday
        let bg: Color = value == "tuttu" ? Theme.gold : value == "kaza" ? Theme.card : Theme.line
        let fg: Color = value == "tuttu" ? Theme.deep : value == "kaza" ? Color(hex: 0xB3261E) : Theme.muted
        let label = value == "tuttu" ? "Tutuldu" : value == "kaza" ? "Kazaya kaldı" : "Henüz gelmedi"
        return Button {
            let next: String? = value == nil ? "tuttu" : value == "tuttu" ? "kaza" : nil
            state.setFasting(day, next)
        } label: {
            Text(verbatim: "\(number)").font(.system(.subheadline, design: .rounded).bold())
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(bg, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isToday ? Theme.accent : value == "kaza" ? Color(hex: 0xB3261E) : Color.clear, lineWidth: 2))
                .foregroundStyle(fg)
        }
        .buttonStyle(.plain)
        .disabled(future)
        .accessibilityLabel(Loc.f("%lld. gün", number) + ", " + Loc.s(label))
    }

    private func legend(_ color: Color, filled: Bool, _ key: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(filled ? color : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: filled ? 0 : 2))
                .frame(width: 12, height: 12)
            Text(Loc.s(key))
        }
    }

    private func imsakiyeRow(day: Date, number: Int, total: Int) -> some View {
        let t = state.times(for: day)
        let isToday = Calendar.current.isDateInToday(day)
        let note: String? = number == 1 ? "İlk oruç" : number == 26 ? "Kadir Gecesi (akşam)" : number == total ? "Arife" : nil
        return HStack {
            Text(verbatim: "\(number)").font(.system(.subheadline, design: .rounded).bold()).frame(width: 40, alignment: .leading)
            VStack(alignment: .leading, spacing: 0) {
                Text(Fmt.shortDate(day)).font(.subheadline.weight(isToday ? .bold : .medium))
                if let note { Text(Loc.s(note)).font(.caption2.bold()).foregroundStyle(isToday ? Theme.gold : Theme.goldInk) }
            }
            Spacer()
            Text(t.map { Fmt.time($0.time(.fajr)) } ?? "–").frame(width: 60, alignment: .trailing)
            Text(t.map { Fmt.time($0.time(.maghrib)) } ?? "–").frame(width: 60, alignment: .trailing)
        }
        .font(.system(.subheadline, design: .rounded)).monospacedDigit()
        .padding(.horizontal, 8).frame(minHeight: 38)
        .foregroundStyle(isToday ? Color.white : Theme.text)
        .background(isToday ? Theme.bordo : number % 2 == 0 ? Theme.background : Color.clear, in: RoundedRectangle(cornerRadius: 10))
    }
}
