import XCTest
@testable import LePortail

// MARK: - CatalogTests — integrity, search, daily-pick, platform classification
//
// Pure-logic tests over the shared Catalog (the same code compiled into the
// widget). No simulator UI required.

final class CatalogTests: XCTestCase {

    // MARK: Integrity

    func testCatalogCount() {
        XCTAssertEqual(Catalog.all.count, 115,
                       "Catalog should hold all 115 La Shop apps")
    }

    func testPlatformSplitSumsToTotal() {
        let split = Catalog.webCount + Catalog.iosCount + Catalog.macCount
        XCTAssertEqual(split, Catalog.all.count,
                       "Every app must be exactly one platform")
    }

    func testKnownPlatformSplit() {
        // 94 web, 8 native-iOS, 13 native-mac — the verified breakdown.
        XCTAssertEqual(Catalog.webCount, 94, "web count")
        XCTAssertEqual(Catalog.iosCount, 8, "iOS-native count")
        XCTAssertEqual(Catalog.macCount, 13, "macOS-native count")
    }

    func testEveryAppHasNameAndTaglines() {
        for app in Catalog.all {
            XCTAssertFalse(app.name.trimmingCharacters(in: .whitespaces).isEmpty,
                           "\(app.id) has a name")
            XCTAssertFalse(app.taglineFR.trimmingCharacters(in: .whitespaces).isEmpty,
                           "\(app.id) has a FR tagline")
            XCTAssertFalse(app.taglineEN.trimmingCharacters(in: .whitespaces).isEmpty,
                           "\(app.id) has an EN tagline")
        }
    }

    func testEveryAppHasAThemeRepresented() {
        for app in Catalog.all {
            XCTAssertTrue(Theme.allCases.contains(app.theme), "\(app.id) theme valid")
        }
        // All seven themes are present in the catalog.
        for theme in Theme.allCases {
            XCTAssertFalse(Catalog.apps(in: theme).isEmpty,
                           "theme \(theme.rawValue) should have apps")
        }
    }

    func testIDsAreUnique() {
        let ids = Catalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "slugs must be unique")
    }

    // MARK: Platform classification + URL validity

    func testWebAppsHaveValidHTTPSURL() {
        for app in Catalog.all where app.platform == .web {
            guard let s = app.url else {
                return XCTFail("\(app.id) is web but has no URL")
            }
            XCTAssertTrue(s.hasPrefix("https://"), "\(app.id) URL must be https")
            XCTAssertNotNil(URL(string: s), "\(app.id) URL must parse")
        }
    }

    func testNativeAppsHaveNoURLButABundleID() {
        for app in Catalog.all where app.platform != .web {
            XCTAssertNil(app.url, "\(app.id) native should have no web URL")
            XCTAssertNotNil(app.bundleID, "\(app.id) native should carry a bundleID")
        }
    }

    func testKnownIOSNativesAreTaggedIOS() {
        let ios = Set(["le-souffle", "le-tintamarre", "amorce", "pareidolia",
                       "la-berceuse", "le-mentaliste", "cabri", "topo"])
        for id in ios {
            XCTAssertEqual(Catalog.app(id: id)?.platform, .iOS, "\(id) should be iOS")
        }
    }

    func testKnownMacNativesAreTaggedMac() {
        let mac = Set(["letabli", "l-accordeur", "le-volet", "le-bout-de-la-langue",
                       "le-pochoir", "prise", "darwin", "l-equerre", "l-horizon",
                       "le-trombone", "punaise", "le-seuil", "la-regie"])
        for id in mac {
            XCTAssertEqual(Catalog.app(id: id)?.platform, .mac, "\(id) should be mac")
        }
    }

    // MARK: Search

    func testSearchEmptyReturnsAll() {
        XCTAssertEqual(Catalog.search("").count, Catalog.all.count)
        XCTAssertEqual(Catalog.search("   ").count, Catalog.all.count)
    }

    func testSearchByName() {
        let r = Catalog.search("accordeur")
        XCTAssertTrue(r.contains { $0.id == "l-accordeur" })
    }

    func testSearchIsDiacriticInsensitive() {
        // "regal" should find "Le Régal".
        let r = Catalog.search("regal")
        XCTAssertTrue(r.contains { $0.id == "le-regal" }, "diacritic-insensitive name match")
        // And the reverse: accented query finds it too.
        XCTAssertTrue(Catalog.search("régal").contains { $0.id == "le-regal" })
    }

    func testSearchMatchesTagline() {
        let r = Catalog.search("backgammon")
        XCTAssertTrue(r.contains { $0.id == "le-jacquet" }, "tagline match")
    }

    func testSearchANDsTerms() {
        // Both terms must appear in the same app's haystack.
        let r = Catalog.search("guitare accordeur")
        XCTAssertTrue(r.contains { $0.id == "l-accordeur" })
        let none = Catalog.search("accordeur backgammon")
        XCTAssertTrue(none.isEmpty, "no app matches both unrelated terms")
    }

    // MARK: Daily-pick determinism (shared with the widget)

    func testDailyPickIsDeterministicForSameKey() {
        let a = Catalog.deliceIndex(forKey: "2026-06-24")
        let b = Catalog.deliceIndex(forKey: "2026-06-24")
        XCTAssertEqual(a, b, "same date → same index")
    }

    func testDailyPickIsInBounds() {
        for d in ["2026-01-01", "2026-06-24", "2026-12-31", "2030-02-28"] {
            let i = Catalog.deliceIndex(forKey: d)
            XCTAssertTrue((0..<Catalog.all.count).contains(i), "index in bounds for \(d)")
        }
    }

    func testDailyPickVariesAcrossDays() {
        // Across a year of keys, we expect a healthy spread (not one fixed app).
        var seen = Set<Int>()
        var day = DateComponents(year: 2026, month: 1, day: 1)
        let cal = Calendar(identifier: .gregorian)
        var date = cal.date(from: day)!
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        for _ in 0..<365 {
            seen.insert(Catalog.deliceIndex(forKey: fmt.string(from: date)))
            date = cal.date(byAdding: .day, value: 1, to: date)!
        }
        _ = day
        XCTAssertGreaterThan(seen.count, 40,
                             "daily pick should spread across many apps over a year")
    }

    func testDeliceMatchesIndex() {
        let date = DateComponents(calendar: .init(identifier: .gregorian),
                                  year: 2026, month: 6, day: 24).date!
        let idx = Catalog.deliceIndex(for: date)
        XCTAssertEqual(Catalog.delice(for: date).id, Catalog.all[idx].id,
                       "delice(for:) must agree with deliceIndex(for:)")
    }

    // MARK: Helpers

    func testAppLookupBySlug() {
        XCTAssertEqual(Catalog.app(id: "le-vertige")?.name, "Le Vertige")
        XCTAssertNil(Catalog.app(id: "does-not-exist"))
    }

    func testMonogramStripsLApostrophe() {
        XCTAssertEqual(Catalog.app(id: "l-accordeur")?.monogram, "A")
        XCTAssertEqual(Catalog.app(id: "le-vertige")?.monogram, "L")
    }
}
