import CoreLocation
import Foundation

/// Location for prayer times (one-shot), compass heading for the qibla, and significant-change
/// monitoring for travel mode. The location never leaves the device.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var heading: Double?
    @Published var headingAccuracy: Double = -1
    @Published var lastLocation: CLLocation?

    var onLocation: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.headingFilter = 1
        authorization = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestOnce() {
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized {
            manager.requestLocation()
        }
    }

    func startHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() { manager.stopUpdatingHeading() }

    /// Travel mode relaunches the app after large moves when "Always" is allowed; otherwise
    /// the location is checked whenever the app becomes active.
    func configureTravel(_ on: Bool) {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        if on && authorization == .authorizedAlways {
            manager.startMonitoringSignificantLocationChanges()
        } else {
            manager.stopMonitoringSignificantLocationChanges()
        }
    }

    func requestAlwaysForTravel() {
        manager.requestAlwaysAuthorization()
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorization = status
            if self.isAuthorized { manager.requestLocation() }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.lastLocation = loc
            self.onLocation?(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        DispatchQueue.main.async {
            self.heading = value
            self.headingAccuracy = accuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A failed one-shot request keeps the last known place; nothing to show to the user here.
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
