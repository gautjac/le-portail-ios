import Foundation
import Combine

// MARK: - LiveStatus — async reachability pings for WEB apps
//
// For each web app we fire a short-timeout HEAD-ish request and treat any 2xx/3xx
// as "live" → a green dot. Native (iOS/mac) apps get a platform badge instead and
// are never pinged. Results are cached in-memory (and persisted briefly) so the UI
// never blocks; the grid renders instantly and dots fill in.

enum Reach: Equatable {
    case unknown
    case checking
    case live
    case down
}

@MainActor
final class LiveStatus: ObservableObject {
    static let shared = LiveStatus()

    @Published private(set) var states: [String: Reach] = [:]

    private let session: URLSession
    private let cacheKey = "atelier_portail_status_cache"
    private let cacheTTL: TimeInterval = 60 * 30   // 30 min

    private init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 6
        cfg.timeoutIntervalForResource = 8
        cfg.waitsForConnectivity = false
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: cfg)
        loadCache()
    }

    func state(for app: AppEntry) -> Reach {
        guard app.platform == .web else { return .unknown }
        return states[app.id] ?? .unknown
    }

    /// Kick off pings for all web apps that are still unknown. Idempotent.
    func refreshAll(force: Bool = false) {
        for app in Catalog.all where app.platform == .web {
            let current = states[app.id] ?? .unknown
            if force || current == .unknown {
                ping(app)
            }
        }
    }

    func ping(_ app: AppEntry) {
        guard app.platform == .web, let s = app.url, let url = URL(string: s) else { return }
        states[app.id] = .checking
        Task { [weak self] in
            guard let self else { return }
            let reach = await Self.check(url, session: self.session)
            await MainActor.run {
                self.states[app.id] = reach
                self.persistCache()
            }
        }
    }

    private static func check(_ url: URL, session: URLSession) async -> Reach {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (_, resp) = try await session.data(for: req)
            if let http = resp as? HTTPURLResponse {
                return (200...399).contains(http.statusCode) ? .live : .down
            }
            return .down
        } catch {
            // Some hosts reject HEAD — retry with a tiny GET before declaring down.
            var get = URLRequest(url: url)
            get.httpMethod = "GET"
            get.setValue("bytes=0-0", forHTTPHeaderField: "Range")
            do {
                let (_, resp) = try await session.data(for: get)
                if let http = resp as? HTTPURLResponse {
                    return (200...399).contains(http.statusCode) ? .live : .down
                }
            } catch { /* fall through */ }
            return .down
        }
    }

    // MARK: Cache (brief — survives a backgrounding, not a cold reinstall)

    private struct CacheEntry: Codable { var live: Bool; var at: TimeInterval }

    private func persistCache() {
        var dict: [String: CacheEntry] = [:]
        let now = Date().timeIntervalSince1970
        for (id, reach) in states {
            switch reach {
            case .live: dict[id] = CacheEntry(live: true, at: now)
            case .down: dict[id] = CacheEntry(live: false, at: now)
            default: break
            }
        }
        if let data = try? JSONEncoder().encode(dict) {
            sharedDefaults.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() {
        guard let data = sharedDefaults.data(forKey: cacheKey),
              let dict = try? JSONDecoder().decode([String: CacheEntry].self, from: data) else { return }
        let now = Date().timeIntervalSince1970
        for (id, e) in dict where now - e.at < cacheTTL {
            states[id] = e.live ? .live : .down
        }
    }
}
