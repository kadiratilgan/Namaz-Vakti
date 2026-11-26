import SwiftUI

struct KibleView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            KibleContent(location: state.location)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct KibleContent: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var location: LocationService
    @State private var lastAligned = false

    var body: some View {
        let qibla = PrayerEngine.qibla(state.place)
        let heading = location.heading
        let diff: Double? = heading.map { ((qibla - $0 + 540).truncatingRemainder(dividingBy: 360)) - 180 }
        let aligned = diff.map { abs($0) <= 3 } ?? false

        ScreenScroll {
            ScreenTitle(title: Loc.s("Kıble"),
                        subtitle: "\(state.place.city) · " + Loc.s(state.autoLocation ? "Otomatik konum açık" : "Manuel konum"))
            Card(padding: 18) {
                VStack(spacing: 14) {
                    Compass(heading: heading ?? 0, qibla: qibla)
                        .frame(width: 290, height: 290)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel(Loc.f("Kıble açısı %lld derece", Int(qibla.rounded())))
                    Group {
                        if let diff {
                            Text(aligned ? Loc.s("Kıble yönündesiniz")
                                 : Loc.f(diff > 0 ? "%lld° sağa çevirin" : "%lld° sola çevirin", Int(abs(diff).rounded())))
                        } else {
                            Text(Loc.s("Pusula bekleniyor…"))
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 16).frame(minHeight: 40)
                    .background(aligned ? Theme.gold : Theme.soft, in: Capsule())
                    .foregroundStyle(aligned ? Theme.deep : Theme.accent)
                    .accessibilityAddTraits(.updatesFrequently)
                }
            }
            HStack(spacing: 12) {
                info(Loc.s("Kıble açısı"), "\(Int(qibla.rounded()))°", Loc.s("Kuzeyden, saat yönünde"))
                info(Loc.s("Kâbe'ye uzaklık"), Fmt.km(PrayerEngine.distanceToKaaba(state.place)), Loc.s("Kuş uçuşu"))
            }
            if location.headingAccuracy < 0 || location.headingAccuracy > 20 {
                Text(Loc.s("Pusula hassasiyeti düşük. Telefonu havada 8 çizerek kalibre et."))
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            Text(Loc.s("Doğru sonuç için telefonu düz tut ve metal eşyalardan uzak dur."))
                .font(.footnote).foregroundStyle(Theme.muted)
        }
        .onAppear { location.startHeading() }
        .onDisappear { location.stopHeading() }
        .sensoryFeedback(.success, trigger: aligned) { _, new in new }
    }

    private func info(_ title: String, _ value: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
            Text(value).font(.system(.title2, design: .rounded).bold()).foregroundStyle(Theme.text)
            Text(sub).font(.caption).foregroundStyle(Theme.muted)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct Compass: View {
    let heading: Double
    let qibla: Double

    var body: some View {
        ZStack {
            ZStack {
                Circle().fill(Theme.background).overlay(Circle().stroke(Theme.line, lineWidth: 2))
                ForEach(0..<72, id: \.self) { i in
                    Rectangle().fill(i % 18 == 0 ? Theme.accent : Theme.muted.opacity(0.5))
                        .frame(width: i % 18 == 0 ? 3 : 1.5, height: i % 18 == 0 ? 14 : 7)
                        .offset(y: -128)
                        .rotationEffect(.degrees(Double(i) * 5))
                }
                ForEach(Array(["K", "D", "G", "B"].enumerated()), id: \.offset) { index, letter in
                    Text(Loc.s(letter)).font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(index == 0 ? Theme.accent : Theme.text)
                        .rotationEffect(.degrees(-Double(index) * 90 + heading))
                        .offset(y: -100)
                        .rotationEffect(.degrees(Double(index) * 90))
                }
                // Qibla direction
                ZStack {
                    Capsule().fill(Theme.gold).frame(width: 4, height: 90).offset(y: -45)
                    Image(systemName: "arrowtriangle.up.fill").font(.system(size: 22)).foregroundStyle(Theme.gold).offset(y: -96)
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x0B0507))
                        .overlay(Rectangle().fill(Theme.gold).frame(height: 3).offset(y: -5))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.gold, lineWidth: 1))
                        .frame(width: 22, height: 22).offset(y: -128)
                }
                .rotationEffect(.degrees(qibla))
            }
            .rotationEffect(.degrees(-heading))
            .animation(.easeOut(duration: 0.25), value: heading)

            Image(systemName: "arrowtriangle.down.fill").font(.system(size: 16)).foregroundStyle(Theme.accent).offset(y: -150)
            Circle().fill(Theme.heroGradient).frame(width: 60, height: 60)
                .overlay(Text(verbatim: "\(Int(heading.rounded()))°").font(.system(.headline, design: .rounded)).foregroundStyle(Theme.cream))
        }
    }
}
