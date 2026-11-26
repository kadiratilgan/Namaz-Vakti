import SwiftUI
import CoreLocation

/// App-wide state. Settings are persisted in the shared App Group so widgets see the same values.
@MainActor
final class AppState: ObservableObject {
    private let d = SharedStore.defaults
    private typealias K = SharedStore.Key

    @Published var place: Place = SharedStore.place
    @Published var language: String { didSet { d.set(language, forKey: K.language); afterChange() } }
    @Published var theme: String { didSet { d.set(theme, forKey: K.theme) } }
    @Published var autoLocation: Bool { didSet { d.set(autoLocation, forKey: K.autoLocation); if autoLocation { location.requestOnce() } } }
    @Published var notif: NotifSettings { didSet { NotifSettings.stored = notif; reschedule() } }
    @Published var special: SpecialReminders { didSet { SpecialReminders.stored = special; reschedule() } }
    @Published var liveActivity: Bool { didSet { d.set(liveActivity, forKey: K.liveActivity); syncLiveActivity() } }
    @Published var dynamicIsland: Bool { didSet { d.set(dynamicIsland, forKey: K.dynamicIsland); syncLiveActivity() } }
    @Published var travelMode: Bool { didSet { d.set(travelMode, forKey: K.travelMode); location.configureTravel(travelMode) } }
    @Published var travelNotify: Bool { didSet { d.set(travelNotify, forKey: K.travelNotify) } }
    @Published var travelDistance: Int { didSet { d.set(travelDistance, forKey: K.travelDistance) } }
    @Published var travelSafar: Bool { didSet { d.set(travelSafar, forKey: K.travelSafar) } }
    @Published var ramadanAuto: Bool { didSet { d.set(ramadanAuto, forKey: K.ramadanAuto); SharedStore.reloadWidgets() } }
    @Published var contentOnHome: Bool { didSet { d.set(contentOnHome, forKey: K.contentOnHome) } }
    @Published var contentMorning: Bool { didSet { d.set(contentMorning, forKey: K.contentMorning); reschedule() } }
    @Published var siriSuggestions: Bool { didSet { d.set(siriSuggestions, forKey: K.siriSuggestions) } }
    @Published var onboarded: Bool { didSet { d.set(onboarded, forKey: K.onboarded) } }

    /// Bumped whenever tracking data changes so views re-read the store.
    @Published var revision = 0
    /// Last city change detected by travel mode (for the in-app banner).
    @Published var lastTravel: TravelEvent?

    struct TravelEvent: Equatable {
        let from: Place
        let to: Place
        let km: Double
    }

    let location = LocationService()

    init() {
        language = d.string(forKey: K.language) ?? "oto"
        theme = d.string(forKey: K.theme) ?? "sistem"
        autoLocation = SharedStore.bool(K.autoLocation, default: true)
        notif = NotifSettings.stored
        special = SpecialReminders.stored
        liveActivity = SharedStore.bool(K.liveActivity, default: true)
        dynamicIsland = SharedStore.bool(K.dynamicIsland, default: true)
        travelMode = SharedStore.bool(K.travelMode, default: true)
        travelNotify = SharedStore.bool(K.travelNotify, default: true)
        travelDistance = d.object(forKey: K.travelDistance) as? Int ?? 25
        travelSafar = SharedStore.bool(K.travelSafar, default: true)
        ramadanAuto = SharedStore.bool(K.ramadanAuto, default: true)
        contentOnHome = SharedStore.bool(K.contentOnHome, default: true)
        contentMorning = SharedStore.bool(K.contentMorning, default: true)
        siriSuggestions = SharedStore.bool(K.siriSuggestions, default: true)
        onboarded = d.bool(forKey: K.onboarded)

        // UI tests: skip onboarding, use a fixed city and the requested language/theme.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uitest") {
            onboarded = true
            autoLocation = false
            let p = Place(lat: 52.52, lon: 13.405, city: "Berlin")
            place = p
            SharedStore.place = p
            if let i = args.firstIndex(of: "-lang"), i + 1 < args.count { language = args[i + 1]; d.set(language, forKey: K.language) }
            if let i = args.firstIndex(of: "-theme"), i + 1 < args.count { theme = args[i + 1] }
        }

        location.onLocation = { [weak self] loc in
            Task { @MainActor in self?.handle(location: loc) }
        }
        location.configureTravel(travelMode)
    }

    // MARK: Derived values

    var colorScheme: ColorScheme? {
        switch theme {
        case "acik": return .light
        case "koyu": return .dark
        default: return nil
        }
    }

    func times(for day: Date) -> DayTimes? { PrayerEngine.times(for: day, place: place) }
    func moment(at now: Date) -> PrayerMoment? { PrayerEngine.moment(at: now, place: place) }

    func isRamadanMode(_ date: Date = Date()) -> Bool { ramadanAuto && PrayerEngine.isRamadan(date) }

    // MARK: Tracking

    func isPrayed(_ kind: PrayerKind, on day: Date) -> Bool {
        _ = revision
        return SharedStore.isPrayed(kind, on: day)
    }

    func setPrayed(_ kind: PrayerKind, on day: Date, _ value: Bool) {
        SharedStore.setPrayed(kind, on: day, value)
        if value { NotificationService.removeEndWarning(kind: kind, day: day) } else { reschedule() }
        revision += 1
    }

    func changeKaza(_ name: String, by delta: Int) {
        var k = SharedStore.kaza
        k[name] = max(0, (k[name] ?? 0) + delta)
        SharedStore.kaza = k
        revision += 1
    }

    func setFasting(_ day: Date, _ value: String?) {
        var f = SharedStore.fasting
        f[SharedStore.dayKey(day)] = value
        SharedStore.fasting = f
        revision += 1
    }

    // MARK: Location

    func setManualPlace(_ p: Place) {
        autoLocation = false
        apply(place: p)
    }

    private func apply(place p: Place) {
        let previous = place
        place = p
        SharedStore.place = p
        var recent = SharedStore.get(K.recentCities, as: [RecentCity].self) ?? []
        if previous.city != p.city {
            recent.removeAll { $0.city == previous.city }
            recent.insert(RecentCity(city: previous.city, lat: previous.lat, lon: previous.lon, date: Date()), at: 0)
            SharedStore.set(Array(recent.prefix(10)), for: K.recentCities)
        }
        afterChange()
    }

    func undoTravel() {
        guard let t = lastTravel else { return }
        autoLocation = false
        apply(place: t.from)
        lastTravel = nil
    }

    private func handle(location loc: CLLocation) {
        guard autoLocation else { return }
        let current = place
        let km = PrayerEngine.distance(from: current, toLat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        let threshold = travelMode ? Double(travelDistance) : 3
        guard !SharedStore.placeIsSet || km >= threshold else { return }
        CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: Loc.locale) { [weak self] marks, _ in
            let city = marks?.first?.locality ?? marks?.first?.administrativeArea ?? String(format: "%.2f, %.2f", loc.coordinate.latitude, loc.coordinate.longitude)
            Task { @MainActor in
                guard let self else { return }
                let newPlace = Place(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude, city: city)
                let wasSet = SharedStore.placeIsSet
                self.apply(place: newPlace)
                if wasSet && self.travelMode && current.city != city {
                    self.lastTravel = TravelEvent(from: current, to: newPlace, km: km)
                    if self.travelNotify {
                        var body = Loc.f("Vakitler artık %@ için gösteriliyor.", city)
                        if self.travelSafar && km >= 90 { body += " " + Loc.s("90 km'yi aştın: seferîlik hükümleri geçerli olabilir.") }
                        NotificationService.sendNow(title: Loc.f("Yeni konum: %@", city), body: body)
                    }
                }
            }
        }
    }

    // MARK: Side effects

    func afterChange() {
        reschedule()
        syncLiveActivity()
        SharedStore.reloadWidgets()
    }

    func reschedule() {
        let p = place, n = notif, s = special, morning = contentMorning
        Task { await NotificationService.reschedule(place: p, settings: n, special: s, morningContent: morning) }
    }

    func syncLiveActivity() {
        LiveActivityService.sync(enabled: liveActivity, island: dynamicIsland, place: place)
    }

    func refreshAll() {
        if autoLocation { location.requestOnce() }
        afterChange()
    }
}

struct RecentCity: Codable, Hashable {
    let city: String
    let lat: Double
    let lon: Double
    let date: Date
}
