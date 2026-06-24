import SwiftUI

// MARK: - AppDetail — one app's card, and the honest launch behaviour
//
//   • web : a big "Ouvrir" button presents SFSafariViewController in a sheet,
//           plus an "Ouvrir dans Safari" affordance that hands off to the system
//           browser. A live status line shows reachability.
//   • iOS : an info card badged "app iOS" with a "sur ton écran d'accueil" note.
//           No launch button is offered (these register no URL scheme), which is
//           the honest answer — except the rare app with a confirmed scheme.
//   • mac : an info card badged "Mac" — not launchable on iPhone.

struct AppDetail: View {
    let app: AppEntry
    @EnvironmentObject var loc: Loc
    @EnvironmentObject var store: Store
    @EnvironmentObject var status: LiveStatus
    @Environment(\.openURL) private var openURL

    @State private var showSafari = false

    private var lang: Lang { loc.lang }

    var body: some View {
        ZStack {
            PortalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    actionBlock
                    metaBlock
                    Spacer(minLength: 12)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(app.id)
                } label: {
                    Image(systemName: store.isFavorite(app.id) ? "star.fill" : "star")
                        .foregroundStyle(Palette.gold)
                }
                .accessibilityLabel(t("Favori", "Favourite"))
            }
        }
        .sheet(isPresented: $showSafari) {
            if let s = app.url, let url = URL(string: s) {
                SafariView(url: url, tint: app.accent)
                    .ignoresSafeArea()
                    .onAppear { store.markOpened(app.id) }
            }
        }
        .onAppear {
            if app.platform == .web {
                status.ping(app)
                // Screenshot harness: auto-present Safari for the web-open shot.
                if Demo.openSafari {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showSafari = true }
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                AccentChip(app: app, size: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(app.name)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    HStack(spacing: 8) {
                        PlatformBadge(platform: app.platform)
                        HStack(spacing: 5) {
                            Image(systemName: app.theme.symbol)
                                .font(.system(size: 10, weight: .bold))
                            Text(app.theme.title(lang))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(app.theme.accent)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(app.tagline(lang))
                .font(.system(size: 16))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    // MARK: Action block — differs by platform

    @ViewBuilder private var actionBlock: some View {
        switch app.platform {
        case .web:   webActions
        case .iOS:   nativeInfo(isIOS: true)
        case .mac:   nativeInfo(isIOS: false)
        }
    }

    private var webActions: some View {
        VStack(spacing: 12) {
            // Reachability line.
            HStack(spacing: 8) {
                StatusDot(reach: status.state(for: app))
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                Spacer()
                if let s = app.url {
                    Text(displayHost(s))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .portalCard(accent: app.accent)

            // Primary: open in-app.
            Button {
                showSafari = true
            } label: {
                HStack {
                    Image(systemName: "safari.fill")
                    Text(t("Ouvrir l'app", "Open the app"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Palette.bg0)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.gold, Palette.goldDeep],
                                             startPoint: .top, endPoint: .bottom))
                )
            }
            .buttonStyle(PressableStyle())

            // Secondary: hand off to Safari proper.
            Button {
                if let s = app.url, let url = URL(string: s) {
                    store.markOpened(app.id)
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text(t("Ouvrir dans Safari", "Open in Safari"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Palette.gold.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(PressableStyle())
        }
    }

    private func nativeInfo(isIOS: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isIOS ? "iphone" : "macbook")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(app.platform.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isIOS
                         ? t("Application iOS native", "Native iOS app")
                         : t("Application macOS native", "Native macOS app"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text(isIOS
                         ? t("Sur ton écran d'accueil.", "On your Home Screen.")
                         : t("S'ouvre sur ton Mac.", "Opens on your Mac."))
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            Text(isIOS
                 ? t("Cette app vit en natif sur l'iPhone. Le Portail ne peut pas la lancer directement — touche son icône sur l'écran d'accueil.",
                     "This one runs natively on iPhone. Le Portail can't launch it directly — tap its icon on your Home Screen.")
                 : t("Cette app est conçue pour macOS. Ouvre-la depuis le Dock ou le Launchpad de ton Mac.",
                     "This one is built for macOS. Open it from your Mac's Dock or Launchpad."))
                .font(.system(size: 13))
                .foregroundStyle(Palette.inkFaint)
            if let b = app.bundleID {
                Text(b)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.inkFaint.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .portalCard(accent: app.accent)
    }

    // MARK: Meta

    private var metaBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("À PROPOS", "ABOUT"))
                .font(.system(size: 11, weight: .heavy)).tracking(1.5)
                .foregroundStyle(Palette.inkFaint)
            row(t("Thème", "Theme"), app.theme.title(lang))
            row(t("Plateforme", "Platform"), app.platform.badge(lang))
            row(t("Bilingue", "Bilingual"),
                t("Cette fiche s'affiche en FR ou EN.", "This card renders in FR or EN."))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .portalCard(accent: app.accent)
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top) {
            Text(k).font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.inkSoft).frame(width: 88, alignment: .leading)
            Text(v).font(.system(size: 13)).foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
        }
    }

    private var statusText: String {
        switch status.state(for: app) {
        case .live:     return t("En ligne", "Online")
        case .down:     return t("Injoignable", "Unreachable")
        case .checking: return t("Vérification…", "Checking…")
        case .unknown:  return t("Statut inconnu", "Status unknown")
        }
    }

    private func displayHost(_ s: String) -> String {
        URL(string: s)?.host ?? s
    }
}
