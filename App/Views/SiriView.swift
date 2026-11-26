import SwiftUI
import AppIntents

struct SiriView: View {
    @EnvironmentObject private var state: AppState
    @State private var selected = 0

    private let phrases = [
        "Akşam ezanı ne zaman?",
        "Sıradaki vakit ne zaman?",
        "Bugünkü namaz vakitleri",
        "Kıble ne tarafta?",
        "İftara ne kadar kaldı?",
        "Zikirmatiği aç"
    ]

    var body: some View {
        ScreenScroll {
            ScreenTitle(title: Loc.s("Siri ve kısayollar"), subtitle: Loc.s("Uygulamayı açmadan sesle sor"))
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: Loc.s(phrases[selected]))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(hex: 0x3A3666), in: RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(verbatim: SiriAnswers.answer(for: selected, place: state.place))
                    .font(.subheadline)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            }
            .foregroundStyle(.white)
            .padding(16)
            .background(LinearGradient(colors: [Color(hex: 0x1C1A2E), Color(hex: 0x0E0D18)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            SiriTipView(intent: NextPrayerIntent())

            SectionTitle(key: "SİRİ'YE SÖYLEYEBİLECEKLERİN")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(phrases.enumerated()), id: \.offset) { i, p in
                        if i > 0 { RowDivider() }
                        Button { selected = i } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.fill").font(.footnote)
                                    .frame(width: 32, height: 32)
                                    .background(i == selected ? Theme.accent : Theme.soft, in: Circle())
                                    .foregroundStyle(i == selected ? Theme.onAccent : Theme.accent)
                                Text(verbatim: "“\(Loc.s(p))”").font(.body.weight(i == selected ? .bold : .regular)).foregroundStyle(Theme.text)
                                Spacer()
                            }
                            .frame(minHeight: 54).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
            Text(Loc.s("Bir ifadeye dokununca Siri'nin cevabını yukarıda görürsün. Kurulum gerekmez: uygulama yüklenince bu kısayollar Siri'de ve Kısayollar uygulamasında hazır olur."))
                .font(.caption).foregroundStyle(Theme.muted)
            Card(padding: 0) {
                ToggleRow(title: Loc.s("Siri önerilerinde göster"), subtitle: Loc.s("Vakit yaklaşınca Spotlight'ta öneri"), isOn: $state.siriSuggestions)
                    .padding(.horizontal, 14)
            }
            ShortcutsLink()
                .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The answers Siri speaks; shared by the App Intents and the preview above.
enum SiriAnswers {
    static func answer(for index: Int, place: Place, now: Date = Date()) -> String {
        guard let t = PrayerEngine.times(for: now, place: place),
              let m = PrayerEngine.moment(at: now, place: place) else { return "" }
        switch index {
        case 0: return prayerTime(.maghrib, place: place, now: now)
        case 1:
            return Loc.f("Sıradaki vakit %@, %@. %@ kaldı.", m.next.name, Fmt.time(m.nextDate), duration(m.nextDate.timeIntervalSince(now)))
        case 2:
            return PrayerKind.allCases.map { "\($0.name) \(Fmt.time(t.time($0)))" }.joined(separator: ", ")
        case 3:
            return Loc.f("Kıble, kuzeyden saat yönünde %lld derece.", Int(PrayerEngine.qibla(place).rounded()))
        case 4:
            if PrayerEngine.isRamadan(now) {
                return Loc.f("İftar %@, %@ kaldı.", Fmt.time(t.time(.maghrib)), duration(t.time(.maghrib).timeIntervalSince(now)))
            }
            return Loc.s("Şu an Ramazan değil. Ramazan'da sorarsan iftara kalan süreyi söylerim.")
        default:
            return Loc.s("Zikirmatik açılıyor.")
        }
    }

    static func prayerTime(_ kind: PrayerKind, place: Place, now: Date = Date()) -> String {
        guard let t = PrayerEngine.times(for: now, place: place) else { return "" }
        var at = t.time(kind)
        if at < now, let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now),
           let t2 = PrayerEngine.times(for: tomorrow, place: place) { at = t2.time(kind) }
        return Loc.f("%@ · %@: %@, %@ sonra.", place.city, kind.name, Fmt.time(at), duration(at.timeIntervalSince(now)))
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        var cal = Calendar.current
        cal.locale = Loc.locale
        f.calendar = cal
        f.unitsStyle = .full
        f.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        return f.string(from: max(60, seconds)) ?? ""
    }
}
