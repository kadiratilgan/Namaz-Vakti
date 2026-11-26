import ActivityKit
import Foundation

/// Keeps one Live Activity showing the countdown to the next prayer.
/// The countdown itself runs on its own (timer text); the app refreshes it on launch and in background refresh.
enum LiveActivityService {
    static func sync(enabled: Bool, island: Bool, place: Place) {
        let activities = Activity<PrayerActivityAttributes>.activities
        guard enabled, ActivityAuthorizationInfo().areActivitiesEnabled,
              let m = PrayerEngine.moment(at: Date(), place: place) else {
            Task { for a in activities { await a.end(nil, dismissalPolicy: .immediate) } }
            return
        }
        let state = PrayerActivityAttributes.ContentState(
            currentKey: m.current.rawValue, nextKey: m.next.rawValue,
            currentStart: m.currentStart, nextDate: m.nextDate, showIsland: island)
        let content = ActivityContent(state: state, staleDate: m.nextDate.addingTimeInterval(60))

        if let existing = activities.first, existing.attributes.city == place.city {
            Task { await existing.update(content) }
            for extra in activities.dropFirst() { Task { await extra.end(nil, dismissalPolicy: .immediate) } }
        } else {
            Task { for a in activities { await a.end(nil, dismissalPolicy: .immediate) } }
            _ = try? Activity.request(attributes: PrayerActivityAttributes(city: place.city), content: content, pushType: nil)
        }
    }
}
