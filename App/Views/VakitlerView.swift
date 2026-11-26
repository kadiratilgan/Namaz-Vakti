import SwiftUI

struct VakitlerView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(now: context.date)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        ScreenScroll {
            header
            if let m = state.moment(at: now) {
                if state.isRamadanMode(now), let t = state.times(for: now) {
                    RamadanHero(now: now, times: t)
                } else {
                    Hero(now: now, moment: m)
                }
                if let t = state.times(for: now) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Loc.s("Bugünün vakitleri")).font(.headline).foregroundStyle(Theme.text)
                        Spacer()
                        NavigationLink(destination: TakipView()) {
                            Text(Loc.f("%@ kılındı ›", "\(SharedStore.prayedCount(on: now))/5"))
                                .font(.footnote.weight(.semibold)).foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(.horizontal, 4)
                    TimesList(now: now, times: t, moment: m)
                }
            }
            NavigationLink(destination: TakipView()) { StreakCard() }.buttonStyle(.plain)
            if state.contentOnHome {
                NavigationLink(destination: GununIcerigiView()) { VerseCard() }.buttonStyle(.plain)
            }
        }
    }

    private var header: some View {
        HStack {
            AppBadge(size: 36)
            Text(Loc.s("Namaz Vakti")).font(.title3.bold()).foregroundStyle(Theme.text)
            Spacer()
            NavigationLink(destination: KonumView()) {
                Label(state.place.city, systemImage: "mappin.and.ellipse")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).frame(minHeight: 36)
                    .background(Theme.card, in: Capsule())
                    .foregroundStyle(Theme.text)
            }
            .accessibilityLabel(Loc.f("Konum: %@", state.place.city))
        }
    }
}

private struct Hero: View {
    @EnvironmentObject private var state: AppState
    let now: Date
    let moment: PrayerMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Fmt.longDate(now)).font(.subheadline.weight(.semibold))
                    Text(PrayerEngine.hijriString(now)).font(.footnote).foregroundStyle(Theme.goldText)
                }
                Spacer()
                Text(verbatim: "DIYANET").font(.caption.weight(.semibold)).tracking(1)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.cream.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            }
            Text(Fmt.time(now)).font(.system(size: 66, weight: .bold, design: .rounded)).monospacedDigit()
            Rectangle().fill(Theme.cream.opacity(0.18)).frame(height: 1)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Loc.s("Şu anki vakit")).font(.caption.weight(.medium)).foregroundStyle(Theme.goldText)
                    Text(moment.current.name).font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Loc.s(moment.next.untilKey)).font(.caption.weight(.medium)).foregroundStyle(Theme.goldText)
                    Text(Fmt.countdown(moment.nextDate.timeIntervalSince(now)))
                        .font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.gold)
                }
            }
            ProgressView(value: moment.progress(at: now)).tint(Theme.gold)
            HStack {
                Text(verbatim: "\(moment.current.name) \(Fmt.time(moment.currentStart))")
                Spacer()
                Text(verbatim: "\(moment.next.name) \(Fmt.time(moment.nextDate))")
            }
            .font(.caption).foregroundStyle(Theme.goldText).monospacedDigit()
        }
        .foregroundStyle(Theme.cream)
        .padding(20)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct RamadanHero: View {
    @EnvironmentObject private var state: AppState
    let now: Date
    let times: DayTimes

    var body: some View {
        let iftar = times.time(.maghrib), imsak = times.time(.fajr)
        let fasting = SharedStore.fasting[SharedStore.dayKey(now)] == "tuttu"
        let day = PrayerEngine.ramadanDay(now) ?? 1
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Fmt.longDate(now)).font(.subheadline.weight(.semibold))
                    Text(Loc.f("Ramazan %@ · %lld. gün", String(PrayerEngine.hijriYear(now)), day)).font(.footnote).foregroundStyle(Theme.goldText)
                }
                Spacer()
                Text(Loc.s("RAMAZAN")).font(.caption.weight(.semibold)).tracking(1).foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.gold.opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(Loc.s(now < iftar ? "İftara kalan" : "Sahura kalan")).font(.footnote.weight(.medium)).foregroundStyle(Theme.goldText)
                Text(Fmt.countdown((now < iftar ? iftar : nextImsak).timeIntervalSince(now)))
                    .font(.system(size: 56, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(Theme.gold)
            }
            ProgressView(value: min(1, max(0, now.timeIntervalSince(imsak) / iftar.timeIntervalSince(imsak)))).tint(Theme.gold)
            HStack(spacing: 10) {
                tile(Loc.s("Sahur bitişi (İmsak)"), Fmt.time(imsak))
                tile(Loc.s("İftar (Akşam)"), Fmt.time(iftar))
            }
            Button {
                state.setFasting(now, fasting ? nil : "tuttu")
            } label: {
                Text(Loc.s(fasting ? "Bugün oruçluyum ✓" : "Bugün oruç tutuyorum olarak işaretle"))
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                    .background(fasting ? Theme.gold : Color.clear, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold, lineWidth: 1))
                    .foregroundStyle(fasting ? Theme.deep : Theme.gold)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Theme.cream)
        .padding(20)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var nextImsak: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return state.times(for: tomorrow)?.time(.fajr) ?? now
    }

    private func tile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(Theme.goldText)
            Text(value).font(.title3.bold()).monospacedDigit()
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct TimesList: View {
    @EnvironmentObject private var state: AppState
    let now: Date
    let times: DayTimes
    let moment: PrayerMoment

    var body: some View {
        VStack(spacing: 0) {
            ForEach(PrayerKind.allCases) { kind in
                row(kind)
            }
        }
        .padding(6)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(_ kind: PrayerKind) -> some View {
        let isNow = kind == moment.current && Calendar.current.isDate(moment.currentStart, inSameDayAs: now)
        let isNext = kind == moment.next
        let entered = now >= times.time(kind)
        let prayed = state.isPrayed(kind, on: now)
        let notifOn = state.notif.setting(kind).on
        return HStack(spacing: 10) {
            if kind.isFard {
                Button { state.setPrayed(kind, on: now, !prayed) } label: { CheckCircle(checked: prayed) }
                    .buttonStyle(.plain)
                    .disabled(!entered)
                    .opacity(entered ? 1 : 0.4)
                    .accessibilityLabel(kind.name + ", " + Loc.s(prayed ? "Kılındı" : "Henüz işaretlenmedi"))
            } else {
                Image(systemName: "sunrise").foregroundStyle(Theme.goldInk).frame(width: 30)
            }
            Text(kind.name).font(.body.weight(isNow ? .bold : .medium)).foregroundStyle(Theme.text)
            if isNow {
                Text(Loc.s("ŞİMDİ")).font(.caption2.weight(.bold)).padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Theme.bordo, in: RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
            } else if isNext {
                let left = moment.nextDate.timeIntervalSince(now)
                Text(left > 0 ? Fmt.inRelative(left) : Loc.s("vakit girdi"))
                    .font(.caption2.weight(.semibold)).padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Theme.softGold, in: RoundedRectangle(cornerRadius: 8)).foregroundStyle(Theme.goldInk)
            }
            Spacer()
            Text(Fmt.time(times.time(kind))).font(.system(.body, design: .rounded).weight(.bold)).monospacedDigit().foregroundStyle(Theme.text)
            Button {
                var n = state.notif
                var s = n.setting(kind)
                s.on.toggle()
                n.perPrayer[kind.rawValue] = s
                state.notif = n
            } label: {
                Image(systemName: notifOn ? "bell.fill" : "bell.slash")
                    .foregroundStyle(notifOn ? Theme.accent : Theme.muted)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Loc.f("%@ bildirimi %@", kind.name, Loc.s(notifOn ? "açık" : "kapalı")))
        }
        .padding(.leading, 8).frame(minHeight: 50)
        .background(isNow ? Theme.soft : Color.clear, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StreakCard: View {
    @EnvironmentObject private var state: AppState
    var body: some View {
        let _ = state.revision
        let week = weekCount()
        let kaza = SharedStore.kaza.values.reduce(0, +)
        HStack(spacing: 12) {
            Image(systemName: "flame.fill").foregroundStyle(Theme.goldInk)
                .frame(width: 40, height: 40).background(Theme.softGold, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(Loc.f("%lld gün seri", SharedStore.streak())).font(.headline).foregroundStyle(Theme.text)
                Text(Loc.f("Bu hafta %lld/%lld vakit · %lld kaza namazı kaldı", week.0, week.1, kaza)).font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Prayers marked this week (Monday-based) and prayers due so far.
    private func weekCount() -> (Int, Int) {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let now = Date()
        guard let start = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return (0, 0) }
        var done = 0, due = 0
        var day = start
        while day <= now {
            done += SharedStore.prayedCount(on: day)
            due += 5
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return (done, due)
    }
}

struct VerseCard: View {
    var body: some View {
        let item = DailyContent.item(.ayet)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Loc.s("GÜNÜN AYETİ")).font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(Theme.goldInk)
                Spacer()
                Text(Loc.s("Hadis ve dua ›")).font(.caption).foregroundStyle(Theme.muted)
            }
            Text(verbatim: "“\(item.localizedText)”").font(.system(.title3, design: .serif)).foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.localizedSource).font(.footnote).foregroundStyle(Theme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
