import SwiftUI
import CoreLocation
import WidgetKit

@main
struct NamazVaktiWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView().environmentObject(model)
        }
    }
}

/// The watch keeps its own location and tracking data (it can run without the iPhone nearby).
final class WatchModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var place: Place = SharedStore.place
    @Published var revision = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            manager.requestLocation()
        }
    }

    func toggle(_ kind: PrayerKind) {
        let now = Date()
        SharedStore.setPrayed(kind, on: now, !SharedStore.isPrayed(kind, on: now))
        revision += 1
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        CLGeocoder().reverseGeocodeLocation(loc) { marks, _ in
            let city = marks?.first?.locality ?? self.place.city
            DispatchQueue.main.async {
                let p = Place(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude, city: city, tz: marks?.first?.timeZone?.identifier)
                self.place = p
                SharedStore.place = p
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct WatchRootView: View {
    @EnvironmentObject private var model: WatchModel
    @Environment(\.scenePhase) private var phase

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            let times = PrayerEngine.times(for: now, place: model.place)
            let m = PrayerEngine.moment(at: now, place: model.place)
            let _ = model.revision
            List {
                if let m {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Loc.s(m.next.untilKey)).font(.caption2).foregroundStyle(Theme.goldText)
                        Text(Fmt.countdown(m.nextDate.timeIntervalSince(now)))
                            .font(.system(.title2, design: .rounded).bold()).monospacedDigit().foregroundStyle(Theme.gold)
                        Text(verbatim: model.place.city).font(.caption2).foregroundStyle(.secondary)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Theme.heroGradient))
                }
                if let times {
                    ForEach(PrayerKind.allCases) { k in
                        Button {
                            if k.isFard && now >= times.time(k) { model.toggle(k) }
                        } label: {
                            HStack {
                                if k.isFard {
                                    Image(systemName: SharedStore.isPrayed(k, on: now) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(Theme.gold)
                                }
                                Text(k.name)
                                Spacer()
                                Text(Fmt.time(times.time(k))).monospacedDigit().fontWeight(.semibold)
                            }
                            .foregroundStyle(k == m?.next ? Theme.gold : .white)
                        }
                        .accessibilityLabel(k.name + " " + Fmt.time(times.time(k)))
                    }
                }
            }
            .navigationTitle(Loc.s("Vakitler"))
        }
        .onAppear { model.refresh() }
        .onChange(of: phase) { _, p in if p == .active { model.refresh() } }
    }
}
