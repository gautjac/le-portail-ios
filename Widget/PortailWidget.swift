import WidgetKit
import SwiftUI

// MARK: - PortailWidget — the Délice du jour, on the Home Screen
//
// Small + medium widget showing today's deterministic pick (same FNV-1a daily
// logic the app uses, shared via the compiled-in Catalog). Tapping it deep-links
// into the app to that app's card via the portail://app/<slug> URL scheme.
// The timeline refreshes at the next local midnight so the delight rolls over.

struct DeliceEntry: TimelineEntry {
    let date: Date
    let app: AppEntry
    let lang: Lang
}

struct DeliceProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeliceEntry {
        DeliceEntry(date: Date(), app: Catalog.delice(), lang: detectLang())
    }

    func getSnapshot(in context: Context, completion: @escaping (DeliceEntry) -> Void) {
        completion(DeliceEntry(date: Date(), app: Catalog.delice(), lang: detectLang()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeliceEntry>) -> Void) {
        let now = Date()
        let entry = DeliceEntry(date: now, app: Catalog.delice(for: now), lang: detectLang())
        // Refresh just after the next local midnight.
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(after: now,
                                        matching: DateComponents(hour: 0, minute: 0, second: 5),
                                        matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct PortailWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DeliceEntry

    var body: some View {
        switch family {
        case .systemSmall: small
        default:           medium
        }
    }

    private var deepLink: URL { URL(string: "portail://app/\(entry.app.id)")! }

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles").font(.system(size: 9, weight: .bold))
                Text(label.uppercased()).font(.system(size: 8, weight: .heavy)).tracking(1)
            }
            .foregroundStyle(Palette.gold)
            Spacer(minLength: 0)
            chip(size: 34)
            Text(entry.app.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.ink)
                .lineLimit(2).minimumScaleFactor(0.8)
            Text(entry.app.tagline(entry.lang))
                .font(.system(size: 10))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .containerBackground(for: .widget) { background }
        .widgetURL(deepLink)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            chip(size: 56)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles").font(.system(size: 9, weight: .bold))
                    Text(label.uppercased()).font(.system(size: 9, weight: .heavy)).tracking(1.2)
                }
                .foregroundStyle(Palette.gold)
                Text(entry.app.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(entry.app.tagline(entry.lang))
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .containerBackground(for: .widget) { background }
        .widgetURL(deepLink)
    }

    private func chip(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(LinearGradient(colors: [entry.app.accent, entry.app.accent.opacity(0.6)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Text(entry.app.monogram)
                    .font(.system(size: size * 0.44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95)))
            .frame(width: size, height: size)
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Palette.bg1, Palette.bg2],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [entry.app.accent.opacity(0.22), .clear],
                           center: .topTrailing, startRadius: 4, endRadius: 220)
        }
    }

    private var label: String {
        entry.lang == .fr ? "Délice du jour" : "Today's delight"
    }
}

struct PortailWidget: Widget {
    let kind = "PortailDelice"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeliceProvider()) { entry in
            PortailWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(detectLang() == .fr ? "Délice du jour" : "Today's delight")
        .description(detectLang() == .fr
                     ? "L'app de La Shop à découvrir aujourd'hui."
                     : "Today's app to discover from La Shop.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PortailWidgetBundle: WidgetBundle {
    var body: some Widget {
        PortailWidget()
    }
}
