# Le Portail — iOS

The pocket gateway to **La Shop**: one Home Screen icon that opens into Jac's
whole family of Atelier apps (~131 of them), with one-tap entry into every web
app, instant search, theme browsing, a daily delight, and a Home Screen widget.

The iOS counterpart to the macOS menu-bar **Le Portail**. Native SwiftUI,
iOS 17+, iPhone + iPad. Bilingual (FR-first / EN).

## What it does

- **Browse** every Atelier app, grouped by the seven themes (Musique · Cinéma &
  doc · Écriture & poésie · BD & dessin · Délices du jour & local · Métiers &
  savoir-faire · Outils) or as an accent-chip tile grid.
- **Open web apps** in an in-app `SFSafariViewController`, with an "Ouvrir dans
  Safari" hand-off. This is the core feature.
- **Honest platform badges.** Each app is tagged **Web**, **app iOS**, or
  **Mac**:
  - Web → opens live in-app.
  - iOS-native → a rich info card ("sur ton écran d'accueil") — these register no
    URL scheme, so the app does **not** offer a launch button it can't honour.
  - macOS-native → an info card ("s'ouvre sur ton Mac") — not launchable from an
    iPhone.
- **Search** — instant, diacritic-insensitive, AND-matched over names + taglines.
- **Filters** — by platform (Tout / Web / iOS / Mac) and a "seulement en ligne"
  toggle.
- **Délice du jour** — a deterministic daily pick (FNV-1a of the date, the same
  logic as the macOS app), featured at the top.
- **Status dots** — async reachability pings for web apps (green = live), cached,
  never blocking the UI.
- **Favoris / Récents** — persisted in the shared app group.
- **Home Screen widget** — small + medium, showing the Délice du jour (name,
  tagline, accent colour); tapping it deep-links into the app to that app's card
  via `portail://app/<slug>`.

## Catalog

The catalog (`Sources/Shared/Catalog.swift`) is ported from the macOS Le
Portail's source of truth and is compiled into **both** the app and the widget
so the daily pick and data are identical. 131 apps:
**110 web · 8 native iOS · 13 native macOS.**

It stays lock-step with the macOS catalog via `le-portail/scripts/check-catalog-sync.py`,
which fails the macOS build if the two ever drift on any app's slug, name,
taglines, accent, category, or URL.

## Build

```sh
./gen.sh                                  # xcodegen → LePortail.xcodeproj
# Simulator (Debug)
xcodebuild -project LePortail.xcodeproj -scheme LePortail -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/le-portail-ios-dd build
# Tests
xcodebuild -project LePortail.xcodeproj -scheme LePortail \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
# Screenshots
./tools/screenshots.sh
# Device (Release) — real signing, team 9WZ66DZ69J, app group + embedded widget
xcodebuild -project LePortail.xcodeproj -scheme LePortail -configuration Release \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates \
  -derivedDataPath /tmp/le-portail-ios-rel build
```

- Bundle id: `app.atelier.portail.ios` (widget: `app.atelier.portail.ios.widget`)
- App group: `group.app.atelier.portail`
- URL scheme: `portail://app/<slug>`
- App icon is rendered by `tools/make_icon.swift` (opaque 1024², no alpha).
