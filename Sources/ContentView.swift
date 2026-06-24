import SwiftUI

// MARK: - ContentView — the home of the gateway
//
// A NavigationStack with:
//   • the Portail wordmark + a FR|EN switch + a layout toggle (grid / sections)
//   • the Délice du jour featured at the top (tap → open)
//   • favourites & recents rails (when present)
//   • platform filter chips + a "seulement en ligne" toggle
//   • .searchable instant, diacritic-insensitive search
//   • grouped-by-theme sections OR an accent-chip tile grid
//
// Tapping any app routes to AppDetail; web apps open in SFSafariViewController.

enum BrowseMode: String { case sections, grid }

struct ContentView: View {
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var store: Store
    @EnvironmentObject var status: LiveStatus
    @EnvironmentObject var nav: NavState

    @State private var mode: BrowseMode = .sections
    @AppStorage("atelier_portail_browse_mode") private var modeRaw: String = BrowseMode.sections.rawValue

    private var lang: Lang { loc.lang }

    /// Apps after search + platform + only-live filtering.
    private var filtered: [AppEntry] {
        var apps = Catalog.search(nav.query, lang: lang)
        if let p = nav.platformFilter { apps = apps.filter { $0.platform == p } }
        if nav.onlyLive {
            apps = apps.filter { $0.platform == .web && status.state(for: $0) == .live }
        }
        return apps
    }

    private var isFiltering: Bool {
        !nav.query.isEmpty || nav.platformFilter != nil || nav.onlyLive
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PortalBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22, pinnedViews: []) {

                        if !isFiltering {
                            DeliceCard().padding(.horizontal, 16).padding(.top, 4)
                            railsSection
                        }

                        FilterBar(mode: $mode).padding(.horizontal, 16)

                        if filtered.isEmpty {
                            emptyState
                        } else if isFiltering || mode == .grid {
                            // Flat result set — grid.
                            AppGrid(apps: filtered).padding(.horizontal, 16)
                                .padding(.bottom, 32)
                        } else {
                            // Browse by theme — sections.
                            ForEach(Catalog.themesInUse) { theme in
                                ThemeSection(theme: theme,
                                             apps: filteredApps(in: theme))
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .navigationTitle("")
            .toolbar { toolbarContent }
            .searchable(text: $nav.query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: t("Chercher dans La Shop…", "Search La Shop…"))
            .navigationDestination(item: $nav.presentedApp) { app in
                AppDetail(app: app)
            }
        }
        .onAppear {
            if let saved = BrowseMode(rawValue: modeRaw) { mode = saved }
            if nav.demoScreen == "grid" { mode = .grid }
        }
        .onChange(of: mode) { _, v in modeRaw = v.rawValue }
    }

    private func filteredApps(in theme: Theme) -> [AppEntry] {
        Catalog.apps(in: theme).filter { app in
            (nav.platformFilter == nil || app.platform == nav.platformFilter) &&
            (!nav.onlyLive || (app.platform == .web && status.state(for: app) == .live))
        }
    }

    // MARK: Rails (favourites / recents)

    @ViewBuilder private var railsSection: some View {
        if !store.favoriteApps.isEmpty {
            AppRail(title: t("Favoris", "Favourites"),
                    symbol: "star.fill", apps: store.favoriteApps)
        }
        if !store.recentApps.isEmpty {
            AppRail(title: t("Récents", "Recent"),
                    symbol: "clock.arrow.circlepath", apps: store.recentApps)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.inkFaint)
            Text(t("Rien trouvé", "Nothing found"))
                .font(.headline).foregroundStyle(Palette.inkSoft)
            Text(t("Essaie un autre mot ou enlève un filtre.",
                   "Try another word or clear a filter."))
                .font(.subheadline).foregroundStyle(Palette.inkFaint)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    // MARK: Toolbar — wordmark + language + count

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 8) {
                PortalGlyph().frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: -2) {
                    Text("Le Portail")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(t("La Shop · \(Catalog.all.count) apps",
                           "La Shop · \(Catalog.all.count) apps"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Palette.gold.opacity(0.8))
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                loc.toggle()
            } label: {
                Text(lang == .fr ? "FR" : "EN")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.bg0)
                    .frame(width: 34, height: 26)
                    .background(Capsule().fill(Palette.gold))
            }
            .accessibilityLabel(t("Changer de langue", "Switch language"))
        }
    }
}

// MARK: - Délice du jour

struct DeliceCard: View {
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var nav: NavState
    private var app: AppEntry { Catalog.delice() }

    var body: some View {
        Button {
            nav.presentedApp = app
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.system(size: 12, weight: .bold))
                    Text(t("Délice du jour", "Today's delight").uppercased())
                        .font(.system(size: 11, weight: .heavy)).tracking(1.5)
                }
                .foregroundStyle(Palette.gold)

                HStack(spacing: 14) {
                    AccentChip(app: app, size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text(app.tagline(loc.lang))
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(2).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                }
                HStack {
                    PlatformBadge(platform: app.platform)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(t(openVerb, openVerb))
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Palette.gold)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Palette.cardHi, Palette.card],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Palette.gold.opacity(0.55), app.accent.opacity(0.3)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var openVerb: String {
        switch app.platform {
        case .web: return t("Ouvrir", "Open")
        case .iOS, .mac: return t("Voir", "View")
        }
    }
}

// MARK: - Portal glyph (wordmark mark)

struct PortalGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // The arch / doorway.
                Path { p in
                    let w = s, h = s
                    p.move(to: CGPoint(x: w*0.5, y: h*0.06))
                    p.addCurve(to: CGPoint(x: w*0.94, y: h*0.5),
                               control1: CGPoint(x: w*0.82, y: h*0.06),
                               control2: CGPoint(x: w*0.94, y: h*0.24))
                    p.addLine(to: CGPoint(x: w*0.94, y: h*0.94))
                    p.addLine(to: CGPoint(x: w*0.06, y: h*0.94))
                    p.addLine(to: CGPoint(x: w*0.06, y: h*0.5))
                    p.addCurve(to: CGPoint(x: w*0.5, y: h*0.06),
                               control1: CGPoint(x: w*0.06, y: h*0.24),
                               control2: CGPoint(x: w*0.18, y: h*0.06))
                }
                .stroke(Palette.gold, lineWidth: s*0.09)
                // inner light
                Circle()
                    .fill(RadialGradient(colors: [Palette.gold.opacity(0.9), .clear],
                                         center: .center, startRadius: 0, endRadius: s*0.4))
                    .frame(width: s*0.5, height: s*0.5)
                    .offset(y: s*0.06)
            }
        }
    }
}
