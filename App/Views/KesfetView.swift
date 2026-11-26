import SwiftUI

struct KesfetView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            ScreenScroll {
                ScreenTitle(title: Loc.s("Keşfet"), subtitle: Loc.s("Namaz Vakti'nin tüm özellikleri"))
                NavigationLink(destination: GununIcerigiView()) {
                    let h = DailyContent.item(.hadis)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.s("GÜNÜN HADİSİ")).font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(Theme.gold)
                        Text(verbatim: "“\(h.localizedText)”").font(.system(.headline, design: .serif)).multilineTextAlignment(.leading)
                        Text(h.localizedSource).font(.caption).foregroundStyle(Theme.goldText)
                    }
                    .foregroundStyle(Theme.cream)
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    tile("Namaz takibi", trackingSubtitle, "checkmark.circle") { TakipView() }
                    tile("Ramazan", "İmsakiye, sahur ve iftar, oruç takibi", "moon.stars") { RamazanView() }
                    tile("Zikirmatik", "Tesbih sayacı ve tesbihat", "circle.dotted") { ZikirmatikView() }
                    tile("Günün içeriği", "Ayet, hadis ve dua her gün yenilenir", "book") { GununIcerigiView() }
                    tile("Yakındaki camiler", "Harita ve yol tarifi", "mappin.and.ellipse") { CamilerView() }
                    tile("Seyahat modu", state.travelMode ? "Açık · şehir değişince vakitler güncellenir" : "Kapalı", "airplane") { SeyahatView() }
                    tile("Apple Watch", "Saat ekranında sıradaki vakit", "applewatch") { WatchInfoView() }
                    tile("Siri ve kısayollar", "“Akşam ezanı ne zaman?”", "mic") { SiriView() }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var trackingSubtitle: String {
        let _ = state.revision
        return Loc.f("%lld gün seri", SharedStore.streak())
    }

    private func tile<D: View>(_ titleKey: String, _ subtitleKey: String, _ icon: String, @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.title3).foregroundStyle(Theme.accent)
                    .frame(width: 40, height: 40).background(Theme.soft, in: RoundedRectangle(cornerRadius: 12))
                Text(Loc.s(titleKey)).font(.headline).foregroundStyle(Theme.text)
                Text(Loc.s(subtitleKey)).font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(14).frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Short explainer for the watch app (the watch app itself lives in the Watch target).
struct WatchInfoView: View {
    var body: some View {
        ScreenScroll {
            ScreenTitle(title: Loc.s("Apple Watch"), subtitle: Loc.s("Saat ekranında sıradaki vakit"))
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Label(Loc.s("Saat ekranına Namaz Vakti komplikasyonunu ekle: halka kalan dakikayı, dikdörtgen sıradaki vakti gösterir."), systemImage: "applewatch.watchface")
                    Label(Loc.s("Saat uygulamasında vakte dokununca “Kıldım” olarak işaretlenir."), systemImage: "checkmark.circle")
                    Label(Loc.s("Bildirimler bileğine hafif titreşimle gelir; iPhone'daki bildirim ayarları kullanılır."), systemImage: "waveform")
                }
                .font(.subheadline).foregroundStyle(Theme.text)
            }
            Text(Loc.s("Saat uygulaması iPhone uygulamasıyla birlikte otomatik yüklenir. Yüklenmediyse iPhone'daki Watch uygulamasından Namaz Vakti'ni aç."))
                .font(.footnote).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
