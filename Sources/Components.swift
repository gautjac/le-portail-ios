import SwiftUI

// MARK: - FilterBar — platform chips, only-live toggle, layout switch

struct FilterBar: View {
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var nav: NavState
    @Binding var mode: BrowseMode

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: t("Tout", "All"), symbol: "square.grid.2x2",
                         active: nav.platformFilter == nil) { nav.platformFilter = nil }
                    chip(title: t("Web", "Web"), symbol: Platform.web.symbol,
                         active: nav.platformFilter == .web) { toggle(.web) }
                    chip(title: t("iOS", "iOS"), symbol: Platform.iOS.symbol,
                         active: nav.platformFilter == .iOS) { toggle(.iOS) }
                    chip(title: t("Mac", "Mac"), symbol: Platform.mac.symbol,
                         active: nav.platformFilter == .mac) { toggle(.mac) }

                    Divider().frame(height: 22).overlay(Palette.inkFaint.opacity(0.4))

                    chip(title: t("En ligne", "Online"), symbol: "dot.radiowaves.left.and.right",
                         active: nav.onlyLive) { nav.onlyLive.toggle() }
                }
                .padding(.vertical, 1)
            }

            HStack {
                Text(countLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.inkFaint)
                Spacer()
                Picker("", selection: $mode) {
                    Image(systemName: "list.bullet").tag(BrowseMode.sections)
                    Image(systemName: "square.grid.2x2").tag(BrowseMode.grid)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
    }

    private var countLabel: String {
        var apps = Catalog.search(nav.query, lang: loc.lang)
        if let p = nav.platformFilter { apps = apps.filter { $0.platform == p } }
        let n = apps.count
        return t("\(n) apps", "\(n) apps")
    }

    private func toggle(_ p: Platform) {
        nav.platformFilter = (nav.platformFilter == p) ? nil : p
    }

    private func chip(title: String, symbol: String, active: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(active ? Palette.bg0 : Palette.inkSoft)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(
                Capsule().fill(active ? Palette.gold : Palette.card)
            )
            .overlay(
                Capsule().strokeBorder(active ? .clear : Palette.inkFaint.opacity(0.3),
                                       lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppGrid — accent-chip tiles

struct AppGrid: View {
    let apps: [AppEntry]
    private let cols = [GridItem(.adaptive(minimum: 158), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(apps) { AppTile(app: $0) }
        }
    }
}

struct AppTile: View {
    let app: AppEntry
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var nav: NavState
    @EnvironmentObject var status: LiveStatus
    @EnvironmentObject var store: Store

    var body: some View {
        Button { nav.presentedApp = app } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    AccentChip(app: app, size: 42)
                    Spacer()
                    if app.platform == .web {
                        StatusDot(reach: status.state(for: app))
                    }
                    if store.isFavorite(app.id) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11)).foregroundStyle(Palette.gold)
                    }
                }
                Text(app.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(app.tagline(loc.lang))
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(2).multilineTextAlignment(.leading)
                    .frame(height: 28, alignment: .top)
                PlatformBadge(platform: app.platform)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .portalCard(accent: app.accent)
        }
        .buttonStyle(PressableStyle())
        .contextMenu { favMenu(app: app, store: store) }
    }
}

// MARK: - ThemeSection — grouped rows under a theme header

struct ThemeSection: View {
    let theme: Theme
    let apps: [AppEntry]
    @EnvironmentObject var loc: Loc

    var body: some View {
        if !apps.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: theme.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.accent)
                    Text(theme.title(loc.lang))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text("\(apps.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.inkFaint)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    ForEach(apps) { AppRow(app: $0) }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct AppRow: View {
    let app: AppEntry
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var nav: NavState
    @EnvironmentObject var status: LiveStatus
    @EnvironmentObject var store: Store

    var body: some View {
        Button { nav.presentedApp = app } label: {
            HStack(spacing: 12) {
                AccentChip(app: app, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(app.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        if store.isFavorite(app.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10)).foregroundStyle(Palette.gold)
                        }
                    }
                    Text(app.tagline(loc.lang))
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(2).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 6) {
                    if app.platform == .web {
                        StatusDot(reach: status.state(for: app))
                    }
                    PlatformBadge(platform: app.platform)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .portalCard(accent: app.accent)
        }
        .buttonStyle(PressableStyle())
        .contextMenu { favMenu(app: app, store: store) }
    }
}

// MARK: - AppRail — horizontal scroller for favourites / recents

struct AppRail: View {
    let title: String
    let symbol: String
    let apps: [AppEntry]
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var nav: NavState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.gold)
                Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(apps) { app in
                        Button { nav.presentedApp = app } label: {
                            VStack(spacing: 7) {
                                AccentChip(app: app, size: 52)
                                Text(app.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Palette.inkSoft)
                                    .lineLimit(1).frame(width: 72)
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Shared bits

@ViewBuilder
func favMenu(app: AppEntry, store: Store) -> some View {
    Button {
        store.toggleFavorite(app.id)
    } label: {
        Label(store.isFavorite(app.id)
              ? t("Retirer des favoris", "Remove favourite")
              : t("Ajouter aux favoris", "Add to favourites"),
              systemImage: store.isFavorite(app.id) ? "star.slash" : "star")
    }
}

/// A subtle press-down feedback that respects Reduce Motion.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12),
                       value: configuration.isPressed)
    }
}
