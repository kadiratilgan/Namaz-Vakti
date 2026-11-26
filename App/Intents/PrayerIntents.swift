import AppIntents
import Foundation

enum PrayerAppEnum: String, AppEnum {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Vakit"
    static var caseDisplayRepresentations: [PrayerAppEnum: DisplayRepresentation] = [
        .fajr: "İmsak", .sunrise: "Güneş", .dhuhr: "Öğle",
        .asr: "İkindi", .maghrib: "Akşam", .isha: "Yatsı"
    ]

    var kind: PrayerKind { PrayerKind(rawValue: rawValue) ?? .dhuhr }
}

struct NextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Sıradaki vakit ne zaman?"
    static var description = IntentDescription("Sıradaki namaz vaktini ve kalan süreyi söyler.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: SiriAnswers.answer(for: 1, place: SharedStore.place)))
    }
}

struct PrayerTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Vakit ne zaman?"
    static var description = IntentDescription("Seçilen namaz vaktinin saatini söyler.")

    @Parameter(title: "Vakit", default: .maghrib)
    var prayer: PrayerAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$prayer) ne zaman?")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: SiriAnswers.prayerTime(prayer.kind, place: SharedStore.place)))
    }
}

struct TodayTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Bugünkü namaz vakitleri"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: SiriAnswers.answer(for: 2, place: SharedStore.place)))
    }
}

struct QiblaIntent: AppIntent {
    static var title: LocalizedStringResource = "Kıble ne tarafta?"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: SiriAnswers.answer(for: 3, place: SharedStore.place)))
    }
}

struct IftarIntent: AppIntent {
    static var title: LocalizedStringResource = "İftara ne kadar kaldı?"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: SiriAnswers.answer(for: 4, place: SharedStore.place)))
    }
}

struct OpenZikirmatikIntent: AppIntent {
    static var title: LocalizedStringResource = "Zikirmatiği aç"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct NamazVaktiShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: NextPrayerIntent(),
                    phrases: ["\(.applicationName) sıradaki vakit", "\(.applicationName) sıradaki vakit ne zaman"],
                    shortTitle: "Sıradaki vakit", systemImageName: "clock")
        AppShortcut(intent: PrayerTimeIntent(),
                    phrases: ["\(.applicationName) \(\.$prayer) ne zaman", "\(.applicationName) \(\.$prayer) vakti"],
                    shortTitle: "Vakit ne zaman?", systemImageName: "sunset")
        AppShortcut(intent: TodayTimesIntent(),
                    phrases: ["\(.applicationName) bugünkü vakitler"],
                    shortTitle: "Bugünkü namaz vakitleri", systemImageName: "list.bullet")
        AppShortcut(intent: QiblaIntent(),
                    phrases: ["\(.applicationName) kıble ne tarafta"],
                    shortTitle: "Kıble", systemImageName: "location.north.circle")
        AppShortcut(intent: IftarIntent(),
                    phrases: ["\(.applicationName) iftara ne kadar kaldı"],
                    shortTitle: "İftar", systemImageName: "moon.stars")
        AppShortcut(intent: OpenZikirmatikIntent(),
                    phrases: ["\(.applicationName) zikirmatiği aç"],
                    shortTitle: "Zikirmatik", systemImageName: "circle.dotted")
    }
}
