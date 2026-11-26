import SwiftUI

struct BildirimlerView: View {
    @EnvironmentObject private var state: AppState
    @State private var open: PrayerKind? = .asr
    @State private var tested = false

    var body: some View {
        ScreenScroll {
            ScreenTitle(title: Loc.s("Bildirimler"),
                        subtitle: Loc.f("%lld vakit açık · %@ saatine göre", PrayerKind.allCases.filter { state.notif.setting($0).on }.count, state.place.city))

            SectionTitle(key: "VAKİTLER")
            ForEach(PrayerKind.allCases) { kind in prayerCard(kind) }

            SectionTitle(key: "ÖZEL HATIRLATMALAR")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ToggleRow(title: Loc.s("Cuma namazı"), subtitle: Loc.s("Cuma günü öğleden 45 dk önce"), isOn: $state.special.friday)
                    RowDivider()
                    ToggleRow(title: Loc.s("Sahur (Ramazan)"), subtitle: Loc.s("İmsaktan 45 dk önce uyandırır"), isOn: $state.special.suhoor)
                    RowDivider()
                    ToggleRow(title: Loc.s("İftar (Ramazan)"), subtitle: Loc.s("Akşam vaktinde iftar bildirimi"), isOn: $state.special.iftar)
                    RowDivider()
                    ToggleRow(title: Loc.s("Kandiller ve dini günler"), subtitle: Loc.s("Bir gün önce akşam vaktinde"), isOn: $state.special.holyNights)
                    RowDivider()
                    ToggleRow(title: Loc.s("Kerahat vakitleri"), subtitle: Loc.s("Namaz kılınması mekruh vakitlerde uyarı"), isOn: $state.special.makruh)
                }
                .padding(.horizontal, 14)
            }

            SectionTitle(key: "GENEL")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ToggleRow(title: Loc.s("Sessiz saatler"), subtitle: Loc.s("23:00 – 04:30 arası sessiz (İmsak hariç)"), isOn: $state.notif.quietHours)
                    RowDivider()
                    ToggleRow(title: Loc.s("Sessiz modda titreşim"), subtitle: Loc.s("Bildirimler ses çalmaz, yalnızca titreşir"), isOn: $state.notif.vibrateOnly)
                }
                .padding(.horizontal, 14)
            }
            Button {
                NotificationService.sendNow(title: Loc.f("%@ vakti girdi", PrayerKind.asr.name), body: "\(state.place.city) · " + Loc.s("Test bildirimi"))
                tested = true
            } label: {
                Text(Loc.s(tested ? "Test bildirimi gönderildi ✓" : "Test bildirimi gönder"))
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 1))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            Text(Loc.s("Ezan sesi için uygulamaya lisanslı ses dosyaları eklenmelidir; eklenmezse iPhone'un bildirim sesi çalar."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(_ kind: PrayerKind) -> Binding<PrayerNotifSetting> {
        Binding(
            get: { state.notif.setting(kind) },
            set: { var n = state.notif; n.perPrayer[kind.rawValue] = $0; state.notif = n }
        )
    }

    private func summary(_ s: PrayerNotifSetting, kind: PrayerKind) -> String {
        guard s.on else { return Loc.s("Kapalı") }
        var parts = [Loc.s(soundKey(s.sound))]
        if s.before > 0 { parts.append(Loc.f("%@ önce", Loc.f("%lld dk", s.before))) }
        if kind.isFard && s.beforeEnd > 0 { parts.append(Loc.f("çıkmadan %@", Loc.f("%lld dk", s.beforeEnd))) }
        return parts.joined(separator: " · ")
    }

    private func soundKey(_ s: String) -> String {
        switch s {
        case "ezan": return "Ezan"
        case "kisa": return "Kısa ezan"
        case "titresim": return "Titreşim"
        default: return "Bildirim"
        }
    }

    private func prayerCard(_ kind: PrayerKind) -> some View {
        let b = binding(kind)
        let isOpen = open == kind
        let time = state.times(for: Date())?.time(kind)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button { withAnimation(.easeInOut(duration: 0.2)) { open = isOpen ? nil : kind } } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "\(kind.name) · \(time.map(Fmt.time) ?? "")").font(.body.bold()).foregroundStyle(Theme.text)
                            Text(verbatim: summary(b.wrappedValue, kind: kind)).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.down").rotationEffect(.degrees(isOpen ? 180 : 0)).foregroundStyle(Theme.muted)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityValue(Loc.s(isOpen ? "açık" : "kapalı"))
                Toggle("", isOn: b.on).labelsHidden().tint(Theme.accent)
                    .accessibilityLabel(Loc.f("%@ bildirimi", kind.name))
            }
            .frame(minHeight: 60)

            if isOpen {
                VStack(alignment: .leading, spacing: 14) {
                    RowDivider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.s("Vakitten önce hatırlat")).font(.subheadline.weight(.semibold))
                        ChipPicker(options: [0, 5, 10, 15, 30].map { ($0, $0 == 0 ? Loc.s("Kapalı") : Loc.f("%lld dk", $0)) }, selection: b.before)
                    }
                    if kind.isFard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Loc.s("Vakit çıkmadan uyar")).font(.subheadline.weight(.semibold))
                            + Text(verbatim: " ") + Text(Loc.s("· “Kıldım” işaretlediysen gelmez")).font(.footnote).foregroundStyle(Theme.muted)
                            ChipPicker(options: [0, 15, 30, 45].map { ($0, $0 == 0 ? Loc.s("Kapalı") : Loc.f("%lld dk", $0)) }, selection: b.beforeEnd)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.s("Ses")).font(.subheadline.weight(.semibold))
                        ChipPicker(options: ["ezan", "kisa", "bildirim", "titresim"].map { ($0, Loc.s(soundKey($0))) }, selection: b.sound)
                    }
                }
                .foregroundStyle(Theme.text)
                .padding(.bottom, 16)
                .opacity(b.wrappedValue.on ? 1 : 0.45)
                .disabled(!b.wrappedValue.on)
            }
        }
        .padding(.horizontal, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isOpen ? Theme.accent : Color.clear, lineWidth: 1))
    }
}
