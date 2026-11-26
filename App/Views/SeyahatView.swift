import SwiftUI

struct SeyahatView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let recent = SharedStore.get(SharedStore.Key.recentCities, as: [RecentCity].self) ?? []
        ScreenScroll {
            ScreenTitle(title: Loc.s("Seyahat modu"), subtitle: Loc.s("Yeni bir şehre gidince vakitler kendiliğinden güncellenir"))

            if let t = state.lastTravel {
                VStack(alignment: .leading, spacing: 10) {
                    Label(Loc.f("Yeni konum: %@", t.to.city), systemImage: "mappin.and.ellipse").font(.headline)
                    Text(Loc.f("Vakitler artık %@ için gösteriliyor.", t.to.city) + " " + Loc.f("%@ uzaklıkta", Fmt.km(t.km)))
                        .font(.subheadline).foregroundStyle(Theme.goldText)
                    HStack(spacing: 8) {
                        Button(Loc.f("%@ konumuna geri dön", t.from.city)) { state.undoTravel() }
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cream.opacity(0.35)))
                        Button(Loc.s("Tamam")) { state.lastTravel = nil }
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Theme.deep)
                    }
                    .font(.subheadline.weight(.semibold)).buttonStyle(.plain)
                }
                .foregroundStyle(Theme.cream)
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 20))
            }

            Card {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Loc.s("Şu anki konum")).font(.caption).foregroundStyle(Theme.muted)
                        Text(verbatim: state.place.city).font(.title3.bold()).foregroundStyle(Theme.text)
                        if let t = state.times(for: Date()) {
                            Text(verbatim: "\(PrayerKind.dhuhr.name) \(Fmt.time(t.time(.dhuhr))) · \(PrayerKind.maghrib.name) \(Fmt.time(t.time(.maghrib)))")
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    Spacer()
                    Text(Loc.s(state.autoLocation ? "OTOMATİK" : "MANUEL")).font(.caption2.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.soft, in: RoundedRectangle(cornerRadius: 8)).foregroundStyle(Theme.accent)
                }
            }

            SectionTitle(key: "AYARLAR")
            Card(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ToggleRow(title: Loc.s("Seyahat modu"), subtitle: Loc.s("Şehir değişince vakitleri otomatik güncelle"), isOn: $state.travelMode)
                    RowDivider()
                    ToggleRow(title: Loc.s("Şehir değişince bildir"), subtitle: Loc.s("Yeni şehrin vakitleriyle kısa bir bildirim"), isOn: $state.travelNotify)
                    RowDivider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.s("Ne kadar uzaklaşınca güncellensin?")).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                        ChipPicker(options: [(10, "10 km"), (25, "25 km"), (50, "50 km")], selection: $state.travelDistance)
                    }
                    .padding(.vertical, 12)
                    RowDivider()
                    ToggleRow(title: Loc.s("Seferîlik hatırlatması"), subtitle: Loc.s("90 km'yi aşan yolculuklarda bilgi notu gösterir"), isOn: $state.travelSafar)
                    if state.travelMode && state.location.authorization != .authorizedAlways {
                        RowDivider()
                        Button(Loc.s("Arka planda da çalışsın (konuma “Her zaman” izni ver)")) {
                            state.location.requestAlwaysForTravel()
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 14)
            }

            if !recent.isEmpty {
                SectionTitle(key: "SON ŞEHİRLER")
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(recent.prefix(5).enumerated()), id: \.offset) { index, c in
                            if index > 0 { RowDivider() }
                            Button {
                                state.setManualPlace(Place(lat: c.lat, lon: c.lon, city: c.city))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: c.city).font(.body.weight(.semibold)).foregroundStyle(Theme.text)
                                        Text(Fmt.shortDate(c.date)).font(.caption).foregroundStyle(Theme.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.uturn.left").foregroundStyle(Theme.muted)
                                }
                                .frame(minHeight: 54)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            Text(Loc.s("Seferîlik bilgisi yalnızca hatırlatma amaçlıdır; dini hükümler için bir din görevlisine danış."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
