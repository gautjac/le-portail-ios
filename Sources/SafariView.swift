import SwiftUI
import SafariServices

// MARK: - SafariView — SFSafariViewController, the core of opening a web app
//
// Web apps open in an in-app Safari sheet (reader-disabled, themed to the app's
// accent). The native "open in Safari" affordance lives in SFSafariViewController's
// own chrome (the share/done bar), and we also surface a dedicated "Ouvrir dans
// Safari" button on the card.

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var tint: Color = Color(hex: "#E8C36A")

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        cfg.barCollapsingEnabled = true
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.preferredControlTintColor = UIColor(tint)
        vc.dismissButtonStyle = .done
        return vc
    }

    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
