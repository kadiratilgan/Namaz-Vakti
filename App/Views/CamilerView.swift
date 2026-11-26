import SwiftUI
import MapKit

struct CamilerView: View {
    @EnvironmentObject private var state: AppState
    @State private var results: [Mosque] = []
    @State private var selected: Mosque.ID?
    @State private var position: MapCameraPosition = .automatic
    @State private var loading = true

    struct Mosque: Identifiable, Hashable {
        let id: String
        let name: String
        let item: MKMapItem
        let km: Double
        static func == (a: Mosque, b: Mosque) -> Bool { a.id == b.id }
        func hash(into h: inout Hasher) { h.combine(id) }
    }

    var body: some View {
        ScreenScroll {
            ScreenTitle(title: Loc.s("Yakındaki camiler"),
                        subtitle: results.isEmpty ? state.place.city
                        : Loc.f("%lld cami %@ içinde · en yakın %@", results.count, Fmt.km(results.last?.km ?? 0), Fmt.km(results.first?.km ?? 0)))
            Map(position: $position, selection: $selected) {
                UserAnnotation()
                ForEach(Array(results.enumerated()), id: \.element.id) { index, m in
                    Marker(m.name, monogram: Text(verbatim: "\(index + 1)"), coordinate: m.item.placemark.coordinate)
                        .tint(selected == m.id ? Theme.gold : Theme.bordo)
                        .tag(m.id)
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if results.isEmpty {
                Text(Loc.s("Yakında cami bulunamadı.")).foregroundStyle(Theme.muted)
            } else {
                Card(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, m in
                            if index > 0 { RowDivider() }
                            row(m, number: index + 1)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            Text(Loc.s("Yol tarifi Apple Haritalar'da açılır."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: state.place) { await search() }
    }

    private func row(_ m: Mosque, number: Int) -> some View {
        HStack(spacing: 12) {
            Button { selected = m.id; position = .item(m.item) } label: {
                Text(verbatim: "\(number)").font(.subheadline.bold()).frame(width: 34, height: 34)
                    .background(selected == m.id ? Theme.gold : Theme.bordo, in: Circle()).foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Loc.f("%@ haritada göster", m.name))
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: m.name).font(.body.bold()).foregroundStyle(Theme.text)
                Text(verbatim: "\(Fmt.km(m.km)) · " + Loc.f("yürüyerek %@", Loc.f("%lld dk", Int((m.km / 4.8 * 60).rounded()))))
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            Spacer()
            Button {
                m.item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            } label: {
                Label(Loc.s("Yol tarifi"), systemImage: "location.north.line").font(.footnote.bold())
                    .padding(.horizontal, 12).frame(minHeight: 38)
                    .background(Theme.bordo, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
    }

    private func search() async {
        loading = true
        let center = CLLocationCoordinate2D(latitude: state.place.lat, longitude: state.place.lon)
        var found: [Mosque] = []
        for query in ["mosque", "cami", "Moschee"] {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(center: center, latitudinalMeters: 6000, longitudinalMeters: 6000)
            request.resultTypes = .pointOfInterest
            if let response = try? await MKLocalSearch(request: request).start() {
                for item in response.mapItems {
                    let c = item.placemark.coordinate
                    let km = PrayerEngine.distance(from: state.place, toLat: c.latitude, lon: c.longitude)
                    let id = "\(item.name ?? "")-\(Int(c.latitude * 10000))-\(Int(c.longitude * 10000))"
                    if !found.contains(where: { $0.id == id }) {
                        found.append(Mosque(id: id, name: item.name ?? Loc.s("Cami"), item: item, km: km))
                    }
                }
            }
        }
        results = Array(found.sorted { $0.km < $1.km }.prefix(10))
        loading = false
    }
}
