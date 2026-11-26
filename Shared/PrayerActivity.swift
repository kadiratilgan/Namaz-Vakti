#if os(iOS)
import ActivityKit
import Foundation

/// Live Activity: countdown to the next prayer on the Lock Screen and in the Dynamic Island.
struct PrayerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentKey: String     // PrayerKind.rawValue
        var nextKey: String
        var currentStart: Date
        var nextDate: Date
        var showIsland: Bool
    }

    var city: String
}
#endif
