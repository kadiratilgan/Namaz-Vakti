import XCTest

/// Opens every screen and keeps a screenshot of each (exported by CI for review).
final class ScreenshotTests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    private func snap(_ app: XCUIApplication, _ name: String) {
        sleep(1)
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    private func run(lang: String, theme: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "-lang", lang, "-theme", theme]
        app.launch()
        let p = "\(lang)-\(theme)"
        snap(app, "\(p)-01-vakitler")
        let tabs = app.tabBars.buttons
        guard tabs.count >= 5 else { return XCTFail("tab bar not found") }
        tabs.element(boundBy: 1).tap(); snap(app, "\(p)-02-takvim")
        tabs.element(boundBy: 2).tap(); snap(app, "\(p)-03-kible")
        tabs.element(boundBy: 4).tap(); snap(app, "\(p)-05-ayarlar")
        app.swipeUp(); snap(app, "\(p)-05b-ayarlar")
        tabs.element(boundBy: 3).tap(); snap(app, "\(p)-04-kesfet")
        // Each feature screen from Discover
        let buttons = app.scrollViews.firstMatch.buttons
        let count = buttons.count
        for i in 1..<min(count, 9) {
            tabs.element(boundBy: 3).tap()
            let b = app.scrollViews.firstMatch.buttons.element(boundBy: i)
            if b.exists && b.isHittable {
                b.tap()
                snap(app, "\(p)-04-kesfet-\(i)")
                if app.navigationBars.buttons.firstMatch.exists { app.navigationBars.buttons.firstMatch.tap() }
            }
        }
        app.terminate()
    }

    func testTurkishLight() { run(lang: "tr", theme: "acik") }
    func testTurkishDark() { run(lang: "tr", theme: "koyu") }
    func testGerman() { run(lang: "de", theme: "acik") }
    func testEnglish() { run(lang: "en", theme: "acik") }
}
