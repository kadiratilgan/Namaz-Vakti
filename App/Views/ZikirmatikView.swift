import SwiftUI

struct ZikirmatikView: View {
    @AppStorage(SharedStore.Key.zikirHaptics, store: SharedStore.defaults) private var haptics = true
    @AppStorage("zikir.step", store: SharedStore.defaults) private var step = 2
    @AppStorage("zikir.target", store: SharedStore.defaults) private var target = 33
    @AppStorage("zikir.count", store: SharedStore.defaults) private var count = 0
    @State private var tapTick = 0
    @State private var doneTick = 0

    private struct Step {
        let name: String
        let times: Int
        let textKey: String
    }

    private let steps: [Step] = [
        Step(name: "Allâhümme ente's-selâm", times: 1, textKey: "Allâhümme ente's-selâmü ve minke's-selâm, tebârekte yâ ze'l-celâli ve'l-ikrâm"),
        Step(name: "Âyetü'l-Kürsî", times: 1, textKey: "Bakara Suresi, 255. ayet"),
        Step(name: "Sübhânallâh", times: 33, textKey: "Allah'ı her türlü eksiklikten tenzih ederim"),
        Step(name: "Elhamdülillâh", times: 33, textKey: "Hamd yalnızca Allah'a mahsustur"),
        Step(name: "Allâhu ekber", times: 33, textKey: "Allah en büyüktür"),
        Step(name: "Kelime-i tevhid", times: 1, textKey: "Lâ ilâhe illallâhu vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamdü ve hüve alâ külli şey'in kadîr"),
        Step(name: "Dua", times: 1, textKey: "Ellerini açarak dilediğin gibi dua et")
    ]

    var body: some View {
        let i = min(max(step, 0), steps.count - 1)
        let current = steps[i]
        let done = target > 0 && count >= target
        let progress = target > 0 ? min(1, Double(count) / Double(target)) : Double(count % 33) / 33

        ScreenScroll {
            ScreenTitle(title: Loc.s("Zikirmatik"), subtitle: Loc.s("Dokundukça say · namaz sonrası tesbihat rehberi"))
            Card {
                VStack(spacing: 4) {
                    Text(Loc.f("TESBİHAT · %lld/%lld", i + 1, steps.count)).font(.caption.weight(.bold)).foregroundStyle(Theme.goldInk)
                    Text(verbatim: current.name).font(.title2.bold()).foregroundStyle(Theme.text)
                    Text(Loc.s(current.textKey)).font(.footnote).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            Picker("", selection: $target) {
                Text(verbatim: "33").tag(33)
                Text(verbatim: "99").tag(99)
                Text(verbatim: "100").tag(100)
                Text(Loc.s("Serbest")).tag(0)
            }
            .pickerStyle(.segmented)
            .onChange(of: target) { _, _ in count = 0 }

            Button {
                guard !done else { return }
                count += 1
                tapTick += 1
                if target > 0 && count >= target { doneTick += 1 }
            } label: {
                ZStack {
                    Circle().fill(Theme.heroGradient)
                    Circle().stroke(Theme.cream.opacity(0.16), lineWidth: 10).padding(14)
                    Circle().trim(from: 0, to: progress).stroke(Theme.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90)).padding(14)
                    VStack(spacing: 2) {
                        Text(verbatim: "\(count)").font(.system(size: 72, weight: .bold, design: .rounded)).monospacedDigit()
                        Text(done ? Loc.s("Tamamlandı ✓") : target > 0 ? "/ \(target)" : Loc.s("serbest sayım"))
                            .font(.subheadline).foregroundStyle(Theme.goldText)
                    }
                    .foregroundStyle(Theme.cream)
                }
                .frame(width: 260, height: 260)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(current.name)
            .accessibilityValue("\(count)")
            .accessibilityHint(Loc.s("Saymak için dokun"))
            .sensoryFeedback(.impact(weight: .light), trigger: tapTick) { _, _ in haptics }
            .sensoryFeedback(.success, trigger: doneTick) { _, _ in haptics }

            HStack(spacing: 8) {
                smallButton("Geri al") { count = max(0, count - 1) }
                smallButton("Sıfırla") { count = 0 }
                Button {
                    guard i < steps.count - 1 else { return }
                    go(to: i + 1)
                } label: {
                    Text(Loc.s("Sıradaki ›")).font(.subheadline.bold()).frame(maxWidth: .infinity, minHeight: 44)
                        .background(i < steps.count - 1 ? Theme.gold : Theme.line, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Theme.deep)
                }
                .buttonStyle(.plain)
                .disabled(i >= steps.count - 1)
            }
            Card(padding: 0) {
                ToggleRow(title: Loc.s("Titreşim"), subtitle: Loc.s("Her dokunuşta hafif, hedefte güçlü titreşim"), isOn: $haptics)
                    .padding(.horizontal, 14)
            }

            SectionTitle(key: "NAMAZ SONRASI TESBİHAT")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { k, s in
                        if k > 0 { RowDivider() }
                        Button { go(to: k) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text(verbatim: k < i ? "✓" : "\(k + 1)").font(.footnote.bold())
                                    .frame(width: 28, height: 28)
                                    .background(k == i ? Theme.bordo : k < i ? Theme.gold : Theme.line, in: Circle())
                                    .foregroundStyle(k == i ? Color.white : Theme.deep)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(verbatim: s.times > 1 ? "\(s.name)  × \(s.times)" : s.name).font(.body.bold()).foregroundStyle(Theme.text)
                                    Text(Loc.s(s.textKey)).font(.footnote).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
            Text(Loc.s("Bir adıma dokununca sayaç o zikre ve sayısına geçer. 33'e ulaşınca “Sıradaki” ile bir sonraki adıma geç."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func go(to k: Int) {
        step = k
        target = steps[k].times == 1 ? 0 : steps[k].times
        count = 0
    }

    private func smallButton(_ key: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(Loc.s(key)).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Theme.text)
        }
        .buttonStyle(.plain)
    }
}
