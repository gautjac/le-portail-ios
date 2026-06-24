import SwiftUI

// MARK: - PortailApp — the entry point
//
// One home-screen icon → the gateway to all of La Shop. Handles the widget deep
// link (portail://app/<slug>) by routing to that app's card. Demo launch args
// (--demo-lang fr|en, --demo-screen home|theme|search|filter|open) drive the
// screenshot harness deterministically.

@main
struct PortailApp: App {
    @StateObject private var loc = Loc.shared
    @StateObject private var store = Store.shared
    @StateObject private var status = LiveStatus.shared
    @StateObject private var nav = NavState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loc)
                .environmentObject(store)
                .environmentObject(status)
                .environmentObject(nav)
                .preferredColorScheme(.dark)
                .tint(Palette.gold)
                .onOpenURL { url in nav.handleDeepLink(url) }
                .task {
                    Demo.applyLaunchArguments()
                    nav.applyDemoDefaults()
                    status.refreshAll()
                }
        }
    }
}

// MARK: - Navigation / deep-link state

@MainActor
final class NavState: ObservableObject {
    /// When set, ContentView presents that app's detail card.
    @Published var presentedApp: AppEntry?
    /// Search text driven by the demo harness or the search field.
    @Published var query: String = ""
    /// Active platform filter.
    @Published var platformFilter: Platform? = nil
    /// "seulement en ligne" — only show web apps confirmed live.
    @Published var onlyLive: Bool = false
    /// Demo override for which screen to land on (screenshots).
    @Published var demoScreen: String? = nil

    /// Pull any demo launch-arg overrides into navigation state (screenshots).
    func applyDemoDefaults() {
        if let screen = Demo.screen { demoScreen = screen }
        if let q = Demo.query { query = q }
        if let p = Demo.platform { platformFilter = p }
        if let openSlug = Demo.openSlug, let app = Catalog.app(id: openSlug) {
            presentedApp = app
        }
    }

    func handleDeepLink(_ url: URL) {
        // portail://app/<slug>
        guard url.scheme == "portail" else { return }
        let slug: String?
        if url.host == "app" {
            slug = url.pathComponents.dropFirst().first
        } else {
            slug = url.host
        }
        if let slug, let app = Catalog.app(id: slug) {
            presentedApp = app
        }
    }
}

// MARK: - Demo harness (deterministic screenshots)

@MainActor
enum Demo {
    static var lang: Lang?
    static var screen: String?
    static var query: String?
    static var platform: Platform?
    static var openSlug: String?
    static var openSafari: Bool = false
    static var fixedDeliceDate: Date?

    static func applyLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let l = value("--demo-lang"), let lg = Lang(rawValue: l) {
            lang = lg
            sharedDefaults.set(l, forKey: kAtelierLang)
            Loc.shared.set(lg)
        }
        screen = value("--demo-screen")
        query = value("--demo-query")
        openSlug = value("--demo-open")
        openSafari = args.contains("--demo-safari")
        if let p = value("--demo-platform") { platform = Platform(rawValue: p) }
    }
}
