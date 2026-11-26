import SwiftUI

struct GununIcerigiView: View {
    @EnvironmentObject private var state: AppState
    @State private var dayOffset = 0
    @State private var saved: Set<String> = Set(SharedStore.get(SharedStore.Key.savedContent, as: [String].self) ?? [])

    var body: some View {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        ScreenScroll {
            ScreenTitle(title: Loc.s("Günün içeriği"), subtitle: Loc.s("Her gün yenilenen ayet, hadis ve dua"))
            HStack {
                Button(Loc.s("‹ Dün")) { dayOffset -= 1 }
                Spacer()
                Text(Fmt.longDate(date)).font(.subheadline.bold()).foregroundStyle(Theme.text)
                Spacer()
                Button(Loc.s("Yarın ›")) { dayOffset += 1 }.disabled(dayOffset >= 0)
            }
            .font(.subheadline.weight(.semibold))
            .padding(8)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))

            ForEach(Array(DailyContent.today(date).enumerated()), id: \.element.id) { index, item in
                contentCard(item, highlighted: index == 1)
            }

            SectionTitle(key: "AYARLAR")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ToggleRow(title: Loc.s("Ana ekranda göster"), subtitle: Loc.s("Vakitler ekranının altında günün ayeti"), isOn: $state.contentOnHome)
                    RowDivider()
                    ToggleRow(title: Loc.s("Sabah bildirimi"), subtitle: Loc.f("Her gün %@'de günün içeriği", "08:00"), isOn: $state.contentMorning)
                }
                .padding(.horizontal, 14)
            }

            let savedItems = DailyContent.all.filter { saved.contains($0.id) }
            if !savedItems.isEmpty {
                SectionTitle(key: "KAYDEDİLENLER")
                ForEach(savedItems) { item in contentCard(item, highlighted: false) }
            }
            Text(Loc.s("İçerik her gün yenilenir. Widget olarak eklemek için ana ekranda boş bir yere basılı tut ve Namaz Vakti widget'larını seç."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func contentCard(_ item: ContentItem, highlighted: Bool) -> some View {
        let isSaved = saved.contains(item.id)
        let shareText = "“\(item.localizedText)” — \(item.localizedSource)"
        return VStack(alignment: .leading, spacing: 10) {
            Text(Loc.s(item.labelKey)).font(.caption.weight(.bold)).tracking(0.8)
                .foregroundStyle(highlighted ? Theme.gold : Theme.goldInk)
            Text(verbatim: "“\(item.localizedText)”").font(.system(.title3, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            if let t = item.translit {
                Text(verbatim: t).font(.footnote.italic()).foregroundStyle(highlighted ? Theme.goldText : Theme.muted)
            }
            Text(item.localizedSource).font(.footnote).foregroundStyle(highlighted ? Theme.goldText : Theme.muted)
            HStack(spacing: 8) {
                ShareLink(item: shareText) {
                    Label(Loc.s("Paylaş"), systemImage: "square.and.arrow.up").font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14).frame(minHeight: 36)
                        .overlay(Capsule().stroke(highlighted ? Theme.cream.opacity(0.35) : Theme.line))
                }
                Button {
                    if isSaved { saved.remove(item.id) } else { saved.insert(item.id) }
                    SharedStore.set(Array(saved), for: SharedStore.Key.savedContent)
                } label: {
                    Label(Loc.s(isSaved ? "Kaydedildi" : "Kaydet"), systemImage: isSaved ? "heart.fill" : "heart").font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14).frame(minHeight: 36)
                        .background(isSaved ? (highlighted ? Theme.gold : Theme.accent) : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(highlighted ? Theme.cream.opacity(0.35) : Theme.line))
                        .foregroundStyle(isSaved ? (highlighted ? Theme.deep : Theme.onAccent) : (highlighted ? Theme.cream : Theme.text))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(highlighted ? Theme.cream : Theme.text)
            .padding(.top, 4)
        }
        .foregroundStyle(highlighted ? Theme.cream : Theme.text)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlighted ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.card), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
