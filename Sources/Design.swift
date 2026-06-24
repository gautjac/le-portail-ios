import SwiftUI

// MARK: - Design — the Portail look
//
// A luminous threshold. A deep, slightly warm night-blue background with a soft
// vertical aurora, brass/gold as the primary accent (the "doorway light"), and
// each app's own theme colour as its chip. Clean iOS system typography, with a
// rounded display weight for the wordmark. Respects Reduce Motion.

/// The portal backdrop — deep gradient + a faint radial "threshold glow".
struct PortalBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bg0, Palette.bg1, Palette.bg2],
                           startPoint: .top, endPoint: .bottom)

            // Threshold glow — a doorway of light at the top.
            RadialGradient(
                colors: [Palette.gold.opacity(0.20), Palette.brass.opacity(0.06), .clear],
                center: .init(x: 0.5, y: -0.05),
                startRadius: 8,
                endRadius: 520)
                .opacity(glow ? 1.0 : 0.78)
                .animation(reduceMotion ? nil :
                    .easeInOut(duration: 6).repeatForever(autoreverses: true), value: glow)

            // Cool aurora wash, lower-left.
            RadialGradient(
                colors: [Palette.aurora2.opacity(0.16), .clear],
                center: .init(x: 0.05, y: 1.05),
                startRadius: 8, endRadius: 480)
        }
        .ignoresSafeArea()
        .onAppear { glow = true }
    }
}

/// A frosted, hairline-bordered surface for cards.
struct PortalCard: ViewModifier {
    var accent: Color = Palette.gold
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [accent.opacity(0.45), .white.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
    }
}

extension View {
    func portalCard(accent: Color = Palette.gold) -> some View {
        modifier(PortalCard(accent: accent))
    }
}

/// The reusable accent monogram chip every app tile/row shows.
struct AccentChip: View {
    let app: AppEntry
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(
                LinearGradient(colors: [app.accent, app.accent.opacity(0.62)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                Text(app.monogram)
                    .font(.system(size: size * 0.44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            )
            .frame(width: size, height: size)
            .shadow(color: app.accent.opacity(0.35), radius: 6, y: 3)
    }
}

/// Platform chip (Web / app iOS / Mac).
struct PlatformBadge: View {
    let platform: Platform
    @EnvironmentObject var loc: Loc

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: platform.symbol).font(.system(size: 9, weight: .bold))
            Text(platform.badge(loc.lang)).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(platform.tint)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(platform.tint.opacity(0.14)))
        .overlay(Capsule().strokeBorder(platform.tint.opacity(0.30), lineWidth: 0.5))
    }
}

/// Live/down/checking dot for web apps.
struct StatusDot: View {
    let reach: Reach
    var body: some View {
        Group {
            switch reach {
            case .live:    Circle().fill(Palette.live)
            case .down:    Circle().fill(Palette.down)
            case .checking: Circle().fill(Palette.inkFaint).opacity(0.6)
            case .unknown:  Circle().fill(Palette.inkFaint).opacity(0.3)
            }
        }
        .frame(width: 8, height: 8)
        .overlay(Circle().strokeBorder(.black.opacity(0.2), lineWidth: 0.5))
    }
}
