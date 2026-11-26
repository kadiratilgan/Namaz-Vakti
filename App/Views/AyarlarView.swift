import SwiftUI
import MapKit

struct AyarlarView: View {
    @EnvironmentObject private var state: AppState

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ScreenScroll {
                ScreenTitle(title: Loc.s("Ayarlar"))

                SectionTitle(key: "GÖRÜNÜM")
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(Loc.s("Tema")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                        Picker(Loc.s("Tema"), selection: $state.theme) {
                            Text(Loc.s("Açık")).tag("acik")
                            Text(Loc.s("Koyu")).tag("koyu")
                            Text(Loc.s("Sistem")).tag("sistem")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                SectionTitle(key: "DİL")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        languageRow("oto", Loc.s("Otomatik"), Loc.f("Cihazın diline göre seçilir · şu an %@", languageName(Loc.activeLanguage)), first: true)
                        languageRow("tr", "Türkçe", nil)
                        languageRow("en", "English", nil)
                        languageRow("de", "Deutsch", nil)
                    }
                    .padding(.horizontal, 14)
                }

                SectionTitle(key: "KONUM")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ToggleRow(title: Loc.s("Otomatik konum"), subtitle: Loc.s("Vakitler bulunduğun yere göre güncellenir"), isOn: $state.autoLocation)
                        RowDivider()
                        linkRow(Loc.s("Manuel konum"), value: state.place.city,
                                subtitle: Loc.s(state.autoLocation ? "Otomatik konum kapalıyken kullanılır" : "Şu an bu konum kullanılıyor")) { KonumView() }
                        RowDivider()
                        HStack {
                            Text(Loc.s("Hesaplama yöntemi")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                            Spacer()
                            Text(verbatim: "Diyanet").foregroundStyle(Theme.muted)
                        }
                        .frame(minHeight: 52)
                        RowDivider()
                        linkRow(Loc.s("Seyahat modu"), value: nil,
                                subtitle: Loc.s(state.travelMode ? "Açık · şehir değişince vakitler güncellenir" : "Kapalı")) { SeyahatView() }
                    }
                    .padding(.horizontal, 14)
                }

                SectionTitle(key: "BİLDİRİMLER")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ToggleRow(title: Loc.s("Vakit bildirimleri"), isOn: $state.notif.master)
                        RowDivider()
                        linkRow(Loc.s("Vakit bazlı bildirimler"),
                                value: "\(PrayerKind.allCases.filter { state.notif.setting($0).on }.count)/6",
                                subtitle: Loc.s("Her vakit için hatırlatma, ses ve “vakit çıkmadan” uyarısı")) { BildirimlerView() }
                        RowDivider()
                        linkRow(Loc.s("Özel hatırlatmalar"), value: nil, subtitle: Loc.s("Cuma, sahur, iftar, kandiller")) { BildirimlerView() }
                    }
                    .padding(.horizontal, 14)
                    .opacity(state.notif.master ? 1 : 0.5)
                }

                SectionTitle(key: "CANLI ETKİNLİK")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ToggleRow(title: Loc.s("Kilit ekranında geri sayım"), subtitle: Loc.s("Sıradaki vakte kalan süre"), isOn: $state.liveActivity)
                        RowDivider()
                        ToggleRow(title: Loc.s("Dynamic Island'da göster"), isOn: $state.dynamicIsland)
                    }
                    .padding(.horizontal, 14)
                }

                SectionTitle(key: "WİDGET'LAR")
                Card {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.s("Ana ekrana widget ekle")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                        Text(Loc.s("Ana ekranda boş bir yere basılı tut, sol üstteki Düzenle › Widget Ekle'ye dokun ve “Namaz Vakti”ni seç. Küçük, orta, büyük ve kilit ekranı boyutları var."))
                            .font(.footnote).foregroundStyle(Theme.muted)
                    }
                }

                SectionTitle(key: "HAKKINDA")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(Loc.s("Sürüm")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                            Spacer()
                            Text(verbatim: version).foregroundStyle(Theme.muted)
                        }
                        .frame(minHeight: 48)
                        RowDivider()
                        linkRow(Loc.s("Gizlilik politikası"), value: nil, subtitle: nil) { LegalView(kind: .privacy) }
                        RowDivider()
                        linkRow(Loc.s("Künye (Impressum)"), value: nil, subtitle: nil) { LegalView(kind: .imprint) }
                        RowDivider()
                        Link(destination: URL(string: "mailto:\(LegalInfo.email)")!) {
                            HStack {
                                Text(Loc.s("Bize ulaşın")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                                Spacer()
                                Image(systemName: "envelope").foregroundStyle(Theme.muted)
                            }
                            .frame(minHeight: 48)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "tr": return "Türkçe"
        case "de": return "Deutsch"
        default: return "English"
        }
    }

    private func languageRow(_ id: String, _ title: String, _ subtitle: String?, first: Bool = false) -> some View {
        VStack(spacing: 0) {
            if !first { RowDivider() }
            Button { state.language = id } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: title).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                        if let subtitle { Text(verbatim: subtitle).font(.caption).foregroundStyle(Theme.muted) }
                    }
                    Spacer()
                    if state.language == id { Image(systemName: "checkmark").font(.body.bold()).foregroundStyle(Theme.accent) }
                }
                .frame(minHeight: 54).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(state.language == id ? .isSelected : [])
        }
    }

    private func linkRow<D: View>(_ title: String, value: String?, subtitle: String?, @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                    if let subtitle { Text(verbatim: subtitle).font(.caption).foregroundStyle(Theme.muted) }
                }
                Spacer()
                if let value { Text(verbatim: value).font(.subheadline).foregroundStyle(Theme.muted) }
                Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(Theme.muted)
            }
            .frame(minHeight: 56).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Manual location

struct KonumView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [MKMapItem] = []

    var body: some View {
        List {
            Section {
                Button {
                    state.autoLocation = true
                    dismiss()
                } label: {
                    Label(Loc.s("Bulunduğum konumu kullan"), systemImage: "location.fill")
                }
            }
            Section(Loc.s("Şehir ara")) {
                ForEach(results, id: \.self) { item in
                    Button {
                        let c = item.placemark.coordinate
                        state.setManualPlace(Place(lat: c.latitude, lon: c.longitude, city: item.name ?? item.placemark.locality ?? ""))
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(verbatim: item.name ?? "").foregroundStyle(Theme.text)
                            Text(verbatim: [item.placemark.administrativeArea, item.placemark.country].compactMap { $0 }.joined(separator: ", "))
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: Loc.s("Şehir ara"))
        .task(id: query) {
            guard query.count >= 2 else { results = []; return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .address
            results = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
        }
        .navigationTitle(Loc.s("Manuel konum"))
    }
}

// MARK: - Legal texts

/// Fill these in before release (German law requires an Impressum for apps offered in the App Store).
enum LegalInfo {
    static let name = "[AD SOYAD]"
    static let address = "[SOKAK NO, POSTA KODU ŞEHİR, ÜLKE]"
    static let email = "destek@example.com"
}

struct LegalView: View {
    enum Kind { case privacy, imprint }
    let kind: Kind

    var body: some View {
        ScreenScroll {
            switch kind {
            case .privacy:
                ScreenTitle(title: Loc.s("Gizlilik politikası"))
                Text(Loc.s("Namaz Vakti kişisel veri toplamaz. Konumun yalnızca cihazında, namaz vakitlerini ve kıble yönünü hesaplamak için kullanılır ve hiçbir sunucuya gönderilmez. Uygulamada reklam, analiz veya takip aracı yoktur. Namaz takibi, oruç ve zikir kayıtların yalnızca cihazında saklanır. Yakındaki camiler aranırken Apple Haritalar kullanılır; bu arama Apple'ın gizlilik koşullarına tabidir."))
            case .imprint:
                ScreenTitle(title: Loc.s("Künye (Impressum)"))
                Text(verbatim: "\(LegalInfo.name)\n\(LegalInfo.address)\nE-Mail: \(LegalInfo.email)")
            }
        }
        .foregroundStyle(Theme.text)
        .navigationBarTitleDisplayMode(.inline)
    }
}
