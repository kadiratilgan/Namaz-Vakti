import SwiftUI

struct TakipView: View {
    @EnvironmentObject private var state: AppState

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private let kazaNames: [(String, String)] = [
        ("fajr", "Sabah"), ("dhuhr", "Öğle"), ("asr", "İkindi"),
        ("maghrib", "Akşam"), ("isha", "Yatsı"), ("witr", "Vitir (vacip)")
    ]

    var body: some View {
        let _ = state.revision
        let now = Date()
        ScreenScroll {
            ScreenTitle(title: Loc.s("Namaz takibi"), subtitle: Loc.s("Kıldığın namazları işaretle, serini ve kazalarını takip et"))
            streakCard(now: now)

            SectionTitle(key: "BUGÜN")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(PrayerKind.fard.enumerated()), id: \.element) { index, kind in
                        if index > 0 { RowDivider() }
                        todayRow(kind, now: now)
                    }
                }
                .padding(.horizontal, 14)
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bell").foregroundStyle(Theme.goldInk)
                Text(Loc.s("“Kıldım” olarak işaretlediğin vakit için “vakit çıkmadan uyar” bildirimi gelmez. Bildirimdeki “Kıldım” butonuyla da işaretleyebilirsin."))
                    .font(.footnote).foregroundStyle(Theme.text)
            }
            .padding(12)
            .background(Theme.softGold, in: RoundedRectangle(cornerRadius: 14))

            SectionTitle(key: "KAZA NAMAZLARI")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(kazaNames.enumerated()), id: \.offset) { index, item in
                        if index > 0 { RowDivider() }
                        kazaRow(id: item.0, nameKey: item.1)
                    }
                    RowDivider()
                    HStack {
                        Text(Loc.s("Kılman gereken toplam kaza")).foregroundStyle(Theme.muted)
                        Spacer()
                        Text(verbatim: "\(SharedStore.kaza.values.reduce(0, +))").font(.title3.bold()).foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 14)
            }
            Text(Loc.s("Vaktinde işaretlenmeyen bir namaz, ertesi gün sana sorularak kaza listesine eklenir. Kaza kıldıkça “−” ile azalt."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { askYesterday() }
        .alert(Loc.s("Dünkü namazlar"), isPresented: $showYesterday) {
            Button(Loc.s("Kaza listesine ekle")) { addYesterdayToKaza() }
            Button(Loc.s("Hepsini kıldım"), role: .cancel) { markYesterdayPrayed() }
        } message: {
            Text(Loc.f("Dün %lld vakit işaretlenmedi. Kaza listesine eklensin mi?", missedYesterday.count))
        }
    }

    // MARK: Yesterday's unmarked prayers → ask once, then add to kaza

    @State private var showYesterday = false
    @State private var missedYesterday: [PrayerKind] = []

    private func askYesterday() {
        guard let y = cal.date(byAdding: .day, value: -1, to: Date()) else { return }
        let key = "askedKaza.\(SharedStore.dayKey(y))"
        guard !SharedStore.defaults.bool(forKey: key) else { return }
        missedYesterday = PrayerKind.fard.filter { !SharedStore.isPrayed($0, on: y) }
        // Only ask when the user is actually tracking (marked at least one prayer yesterday).
        if !missedYesterday.isEmpty && missedYesterday.count < 5 { showYesterday = true }
        SharedStore.defaults.set(true, forKey: key)
    }

    private func addYesterdayToKaza() {
        for k in missedYesterday { state.changeKaza(k.rawValue, by: 1) }
    }

    private func markYesterdayPrayed() {
        guard let y = cal.date(byAdding: .day, value: -1, to: Date()) else { return }
        for k in missedYesterday { state.setPrayed(k, on: y, true) }
    }

    // MARK: Pieces

    private func streakCard(now: Date) -> some View {
        let start = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        let done = days.filter { $0 <= now }.reduce(0) { $0 + SharedStore.prayedCount(on: $1) }
        let due = days.filter { $0 <= now }.count * 5
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Loc.f("%lld gün", SharedStore.streak())).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(Theme.gold)
                    Text(Loc.s("kesintisiz seri")).font(.footnote).foregroundStyle(Theme.goldText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(verbatim: "\(done)/\(due)").font(.title2.bold())
                    Text(Loc.s("bu hafta")).font(.caption).foregroundStyle(Theme.goldText)
                }
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isToday = cal.isDateInToday(day)
                    VStack(spacing: 6) {
                        Text(Fmt.weekdayShort(day)).font(.caption2.bold()).foregroundStyle(isToday ? Theme.gold : Theme.goldText)
                        VStack(spacing: 3) {
                            ForEach(PrayerKind.fard) { k in
                                Circle().fill(SharedStore.isPrayed(k, on: day) ? Theme.gold : Theme.cream.opacity(0.2)).frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.vertical, 8).frame(maxWidth: .infinity)
                    .background(isToday ? Theme.cream.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Fmt.longDate(day) + ": " + "\(SharedStore.prayedCount(on: day))/5")
                }
            }
        }
        .foregroundStyle(Theme.cream)
        .padding(18)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func todayRow(_ kind: PrayerKind, now: Date) -> some View {
        let t = state.times(for: now)?.time(kind) ?? now
        let entered = now >= t
        let done = state.isPrayed(kind, on: now)
        let status = done ? "Kılındı" : entered ? "Henüz işaretlenmedi" : "Vakti henüz girmedi"
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(kind.name) · \(Fmt.time(t))").font(.body.weight(.bold)).foregroundStyle(Theme.text)
                Text(Loc.s(status)).font(.caption).foregroundStyle(done ? Color(hex: 0x2E7D4F) : Theme.muted)
            }
            Spacer()
            Button { state.setPrayed(kind, on: now, !done) } label: { CheckCircle(checked: done, size: 34) }
                .buttonStyle(.plain).disabled(!entered)
                .accessibilityLabel(kind.name + ", " + Loc.s(status))
        }
        .opacity(entered ? 1 : 0.5)
        .frame(minHeight: 58)
    }

    private func kazaRow(id: String, nameKey: String) -> some View {
        let n = SharedStore.kaza[id] ?? 0
        return HStack(spacing: 10) {
            Text(Loc.s(nameKey)).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
            Spacer()
            Button { state.changeKaza(id, by: -1) } label: {
                Image(systemName: "minus").frame(width: 36, height: 36)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(Loc.f("%@ kazasını bir azalt", Loc.s(nameKey)))
            Text(verbatim: "\(n)").font(.title3.bold()).monospacedDigit().frame(minWidth: 34).foregroundStyle(Theme.text)
            Button { state.changeKaza(id, by: 1) } label: {
                Image(systemName: "plus").frame(width: 36, height: 36)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(Loc.f("%@ kazasını bir artır", Loc.s(nameKey)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.accent)
        .frame(minHeight: 52)
    }
}
