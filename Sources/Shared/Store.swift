import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Store — favourites, recents, and cached web-status
//
// Lightweight persistence on the shared app-group UserDefaults so the widget can
// read the same favourites/recents the app writes. Slugs only; everything else
// is resolved from the (shared, compiled-in) Catalog.

#if canImport(Combine)
@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    private let kFavorites = "atelier_portail_favorites"
    private let kRecents   = "atelier_portail_recents"
    private let maxRecents = 12

    @Published private(set) var favorites: [String]
    @Published private(set) var recents: [String]

    private init() {
        favorites = sharedDefaults.stringArray(forKey: kFavorites) ?? []
        recents   = sharedDefaults.stringArray(forKey: kRecents) ?? []
    }

    // MARK: Favourites

    func isFavorite(_ id: String) -> Bool { favorites.contains(id) }

    func toggleFavorite(_ id: String) {
        if let i = favorites.firstIndex(of: id) {
            favorites.remove(at: i)
        } else {
            favorites.insert(id, at: 0)
        }
        sharedDefaults.set(favorites, forKey: kFavorites)
        objectWillChange.send()
    }

    var favoriteApps: [AppEntry] { favorites.compactMap { Catalog.app(id: $0) } }

    // MARK: Recents

    func markOpened(_ id: String) {
        recents.removeAll { $0 == id }
        recents.insert(id, at: 0)
        if recents.count > maxRecents { recents = Array(recents.prefix(maxRecents)) }
        sharedDefaults.set(recents, forKey: kRecents)
        objectWillChange.send()
    }

    var recentApps: [AppEntry] { recents.compactMap { Catalog.app(id: $0) } }
}
#endif
