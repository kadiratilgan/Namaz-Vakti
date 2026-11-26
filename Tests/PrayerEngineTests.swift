import XCTest
@testable import NamazVakti

final class PrayerEngineTests: XCTestCase {
    private let cities: [Place] = [
        Place(lat: 41.0082, lon: 28.9784, city: "İstanbul"),
        Place(lat: 39.9334, lon: 32.8597, city: "Ankara"),
        Place(lat: 52.52, lon: 13.405, city: "Berlin"),
        Place(lat: 48.1351, lon: 11.582, city: "München"),
        Place(lat: 21.4225, lon: 39.8262, city: "Mekke")
    ]

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testTimesAreInOrderAllYear() {
        for place in cities {
            for month in 1...12 {
                let t = PrayerEngine.times(for: date(2026, month, 15), place: place)
                XCTAssertNotNil(t, "\(place.city) \(month)")
                guard let t else { continue }
                let list = PrayerKind.allCases.map { t.time($0) }
                XCTAssertEqual(list, list.sorted(), "\(place.city) month \(month) out of order")
            }
        }
    }

    func testMomentAlwaysHasFutureNext() {
        let place = cities[2]
        var now = date(2026, 11, 26)
        for _ in 0..<48 {
            let m = PrayerEngine.moment(at: now, place: place)
            XCTAssertNotNil(m)
            if let m {
                XCTAssertGreaterThan(m.nextDate, now)
                XCTAssertLessThanOrEqual(m.currentStart, now)
                XCTAssert((0...1).contains(m.progress(at: now)))
            }
            now = now.addingTimeInterval(1800)
        }
    }

    func testQiblaAndDistance() {
        XCTAssertEqual(PrayerEngine.qibla(cities[2]), 136.7, accuracy: 1.0)   // Berlin
        XCTAssertEqual(PrayerEngine.qibla(cities[0]), 151.6, accuracy: 1.5)   // İstanbul
        XCTAssertEqual(PrayerEngine.distanceToKaaba(cities[2]), 4130, accuracy: 30)
    }

    func testIstanbulSummerTimesArePlausible() {
        // Diyanet İstanbul, late June: imsak ~03:2x, akşam ~20:3x (local time)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let d = cal.date(from: DateComponents(year: 2026, month: 6, day: 21, hour: 12))!
        let t = PrayerEngine.times(for: d, place: cities[0], calendar: cal)!
        let hm = { (x: Date) -> Int in let c = cal.dateComponents([.hour, .minute], from: x); return c.hour! * 60 + c.minute! }
        XCTAssert((3 * 60 + 10...3 * 60 + 40).contains(hm(t.time(.fajr))), "imsak \(hm(t.time(.fajr)))")
        XCTAssert((20 * 60 + 25...20 * 60 + 45).contains(hm(t.time(.maghrib))), "akşam \(hm(t.time(.maghrib)))")
    }

    func testRamadanDetection() {
        // Ramadan 1448 begins around 8 February 2027
        XCTAssertTrue(PrayerEngine.isRamadan(date(2027, 2, 20)))
        XCTAssertFalse(PrayerEngine.isRamadan(date(2026, 11, 26)))
    }

    func testEveryPrayerHasTranslations() {
        for lang in ["en", "de"] {
            guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: path) else {
                return XCTFail("missing \(lang).lproj")
            }
            for k in PrayerKind.allCases {
                let v = b.localizedString(forKey: k.key, value: nil, table: nil)
                XCTAssertNotEqual(v, k.key, "\(k.key) not translated to \(lang)")
            }
        }
    }

    func testStreakCountsFullDays() {
        let day = date(2026, 1, 10)
        for offset in 0..<3 {
            let d = Calendar.current.date(byAdding: .day, value: -offset, to: day)!
            for k in PrayerKind.fard { SharedStore.setPrayed(k, on: d, true) }
        }
        XCTAssertGreaterThanOrEqual(SharedStore.streak(now: day), 3)
    }
}
