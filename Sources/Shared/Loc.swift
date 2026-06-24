import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Loc — the little bilingual engine (shared Atelier pattern)
//
// Le Portail speaks French and English. Every user-visible literal goes through
// `t(_ fr:_ en:)`. The language defaults to the system language (FR fallback —
// Jac is FR-first) and can be flipped in-app via the FR|EN switch. The override
// persists in the shared app-group UserDefaults under `atelier_lang`, so the
// app AND the Home Screen widget render in the same language.

enum Lang: String, Codable {
    case fr, en
}

let kAtelierLang = "atelier_lang"
let kAppGroup = "group.app.atelier.portail"

/// Shared defaults — app-group backed when available, standard otherwise.
/// UserDefaults is internally thread-safe; the global is read-only here.
nonisolated(unsafe) let sharedDefaults: UserDefaults = UserDefaults(suiteName: kAppGroup) ?? .standard

func detectLang() -> Lang {
    if let saved = sharedDefaults.string(forKey: kAtelierLang),
       let l = Lang(rawValue: saved) {
        return l
    }
    let pref = (Locale.preferredLanguages.first ?? "fr").lowercased()
    return pref.hasPrefix("en") ? .en : .fr
}

#if canImport(Combine)
@MainActor
final class Loc: ObservableObject {
    static let shared = Loc()

    @Published private(set) var lang: Lang

    private init() {
        let l = detectLang()
        self.lang = l
        Loc.current = l
    }

    nonisolated(unsafe) fileprivate(set) static var current: Lang = .fr

    func set(_ l: Lang) {
        guard l != lang else { return }
        lang = l
        Loc.current = l
        sharedDefaults.set(l.rawValue, forKey: kAtelierLang)
        objectWillChange.send()
    }

    func toggle() { set(lang == .fr ? .en : .fr) }
}
#endif

func t(_ fr: String, _ en: String) -> String {
    #if canImport(Combine)
    return Loc.current == .fr ? fr : en
    #else
    return detectLang() == .fr ? fr : en
    #endif
}
