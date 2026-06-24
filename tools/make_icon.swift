// Renders the Le Portail app icon — a luminous golden doorway/threshold on a
// deep midnight field. Opaque, exactly 1024×1024, NO alpha channel.
// Run: swift make_icon.swift <out.png>
import AppKit

let W: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

func col(_ hex: Int, _ a: CGFloat = 1) -> CGColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF)/255,
            green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a).cgColor
}

// Opaque RGB context — noneSkipLast => no alpha component in the buffer.
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(W), height: Int(W),
                          bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("ctx")
}

// Background gradient (warm midnight, top→bottom).
let bg = CGGradient(colorsSpace: cs, colors: [col(0x141A33), col(0x0A0E1C)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: W), end: CGPoint(x: 0, y: 0), options: [])

// Radial threshold glow.
let glow = CGGradient(colorsSpace: cs,
                      colors: [col(0xE8C36A, 0.55), col(0xC99A3E, 0.12), col(0xC99A3E, 0.0)] as CFArray,
                      locations: [0, 0.45, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: W/2, y: W*0.56), startRadius: 0,
                       endCenter: CGPoint(x: W/2, y: W*0.56), endRadius: W*0.5, options: [])

func portalPath(inset: CGFloat) -> CGMutablePath {
    let p = CGMutablePath()
    let l = inset, r = W - inset
    let bottom = inset * 1.05
    let shoulder = W * 0.52
    p.move(to: CGPoint(x: l, y: bottom))
    p.addLine(to: CGPoint(x: l, y: shoulder))
    p.addQuadCurve(to: CGPoint(x: W/2, y: W - inset), control: CGPoint(x: l, y: W - inset))
    p.addQuadCurve(to: CGPoint(x: r, y: shoulder), control: CGPoint(x: r, y: W - inset))
    p.addLine(to: CGPoint(x: r, y: bottom))
    return p
}

// Inner light fill.
ctx.saveGState()
ctx.addPath(portalPath(inset: W*0.235)); ctx.clip()
let inner = CGGradient(colorsSpace: cs,
                       colors: [col(0xFFE9B0, 0.85), col(0xE8C36A, 0.22), col(0xE8C36A, 0.0)] as CFArray,
                       locations: [0, 0.55, 1])!
ctx.drawLinearGradient(inner, start: CGPoint(x: W/2, y: W*0.86),
                       end: CGPoint(x: W/2, y: W*0.18), options: [])
ctx.restoreGState()

// Outer gold stroke.
ctx.saveGState()
ctx.addPath(portalPath(inset: W*0.20))
ctx.setStrokeColor(col(0xE8C36A))
ctx.setLineWidth(W*0.052); ctx.setLineJoin(.round); ctx.setLineCap(.round)
ctx.strokePath()
ctx.restoreGState()

// Threshold line at the foot.
ctx.setStrokeColor(col(0xFFE9B0))
ctx.setLineWidth(W*0.018); ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: W*0.255, y: W*0.215))
ctx.addLine(to: CGPoint(x: W*0.745, y: W*0.215))
ctx.strokePath()

guard let cg = ctx.makeImage() else { fatalError("image") }
let rep = NSBitmapImageRep(cgImage: cg)
rep.size = NSSize(width: W, height: W)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
