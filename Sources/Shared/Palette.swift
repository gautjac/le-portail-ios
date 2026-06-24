import SwiftUI

// MARK: - Palette — the Portail colour system (shared with the widget)
//
// A luminous threshold: a warm-midnight field, brass→gold as the doorway light,
// and an aurora counterpoint. Lives in Shared so the Home Screen widget renders
// in the exact same palette as the app.

enum Palette {
    // Deep portal background — warm midnight.
    static let bg0    = Color(hex: "#0C1020")
    static let bg1    = Color(hex: "#11162B")
    static let bg2    = Color(hex: "#161D38")
    static let card   = Color(hex: "#1A2240")
    static let cardHi = Color(hex: "#222C52")

    // The doorway light: brass → gold.
    static let gold     = Color(hex: "#E8C36A")
    static let goldDeep = Color(hex: "#C99A3E")
    static let brass    = Color(hex: "#B8863B")

    // Aurora accent (cool counterpoint to the gold).
    static let aurora1 = Color(hex: "#4C6FB0")
    static let aurora2 = Color(hex: "#6D4C9F")

    static let ink      = Color(hex: "#F4F1E8")
    static let inkSoft  = Color(hex: "#B9BFD2")
    static let inkFaint = Color(hex: "#7E869E")

    static let live = Color(hex: "#54D98C")
    static let down = Color(hex: "#C75C5C")
}
