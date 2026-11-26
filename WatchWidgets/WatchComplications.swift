import WidgetKit
import SwiftUI

@main
struct NamazVaktiComplications: WidgetBundle {
    var body: some Widget {
        NextPrayerComplication()
    }
}

struct NextPrayerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextPrayerWatch", provider: PrayerProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(Loc.s("Sıradaki vakit"))
        .description(Loc.s("Sıradaki vakte kalan süre"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        switch family {
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        case .accessoryInline: AccessoryInlineView(entry: entry)
        case .accessoryCorner:
            if let m = entry.moment {
                Text(verbatim: "\(Fmt.minutes(m.nextDate.timeIntervalSince(entry.date)))")
                    .font(.system(.title3, design: .rounded).bold())
                    .widgetLabel { Text(verbatim: "\(m.next.name) \(Fmt.time(m.nextDate))") }
            }
        default: AccessoryCircularView(entry: entry)
        }
    }
}
