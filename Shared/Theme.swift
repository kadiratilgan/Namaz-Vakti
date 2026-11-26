import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Brand colours from the chosen "Cami" icon: bordeaux, cream and gold.
enum Theme {
    static let bordo = Color(hex: 0x7A2438)
    static let deep = Color(hex: 0x3E0F1C)
    static let cream = Color(hex: 0xF3E3C3)
    static let gold = Color(hex: 0xE0A84B)
    static let goldText = Color(hex: 0xE9C78A)

    static let heroGradient = LinearGradient(colors: [bordo, deep], startPoint: .topLeading, endPoint: .bottomTrailing)

    #if os(iOS)
    static let background = adaptive(light: 0xF7EEEA, dark: 0x1A0C10)
    static let card = adaptive(light: 0xFFFFFF, dark: 0x2A1519)
    static let text = adaptive(light: 0x3E0F1C, dark: 0xF3E3C3)
    static let muted = adaptive(light: 0x745D62, dark: 0xBFA8AC)
    static let line = adaptive(light: 0xF1E6E2, dark: 0x3A2228)
    static let accent = adaptive(light: 0x7A2438, dark: 0xE0A84B)
    static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x1A0C10)
    static let soft = adaptive(light: 0xF7E6E1, dark: 0x3A1A20)
    static let softGold = adaptive(light: 0xF8E8C8, dark: 0x3A2A12)
    static let goldInk = adaptive(light: 0x8A5A12, dark: 0xE0A84B)

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    #else
    static let background = Color.black
    static let card = Color(hex: 0x1C1416)
    static let text = Color.white
    static let muted = Color(hex: 0xB8A9AC)
    static let line = Color(hex: 0x2A2427)
    static let accent = Color(hex: 0xE0A84B)
    static let onAccent = Color(hex: 0x1A0C10)
    static let soft = Color(hex: 0x3A1A20)
    static let softGold = Color(hex: 0x3A2A12)
    static let goldInk = Color(hex: 0xE0A84B)
    #endif
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

#if os(iOS)
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
#endif

/// The mosque mark from the app icon, drawn as a SwiftUI shape so it stays crisp at any size.
struct MosqueMark: View {
    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height) / 100
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * s, y: y * s, width: w * s, height: h * s) }
            let cream = GraphicsContext.Shading.color(Theme.cream)
            let gold = GraphicsContext.Shading.color(Theme.gold)
            var body = Path()
            body.addRoundedRect(in: r(15.5, 34, 7, 42), cornerSize: CGSize(width: s, height: s))
            body.addRoundedRect(in: r(77.5, 34, 7, 42), cornerSize: CGSize(width: s, height: s))
            body.move(to: CGPoint(x: 15.5 * s, y: 34 * s)); body.addLine(to: CGPoint(x: 19 * s, y: 21 * s)); body.addLine(to: CGPoint(x: 22.5 * s, y: 34 * s)); body.closeSubpath()
            body.move(to: CGPoint(x: 77.5 * s, y: 34 * s)); body.addLine(to: CGPoint(x: 81 * s, y: 21 * s)); body.addLine(to: CGPoint(x: 84.5 * s, y: 34 * s)); body.closeSubpath()
            var dome = Path()
            dome.move(to: CGPoint(x: 25 * s, y: 76 * s))
            dome.addLine(to: CGPoint(x: 25 * s, y: 60 * s))
            dome.addLine(to: CGPoint(x: 31 * s, y: 60 * s))
            dome.addQuadCurve(to: CGPoint(x: 50 * s, y: 35 * s), control: CGPoint(x: 31 * s, y: 40 * s))
            dome.addQuadCurve(to: CGPoint(x: 69 * s, y: 60 * s), control: CGPoint(x: 69 * s, y: 40 * s))
            dome.addLine(to: CGPoint(x: 75 * s, y: 60 * s))
            dome.addLine(to: CGPoint(x: 75 * s, y: 76 * s))
            dome.closeSubpath()
            var door = Path()
            door.move(to: CGPoint(x: 45.5 * s, y: 76 * s))
            door.addLine(to: CGPoint(x: 45.5 * s, y: 68 * s))
            door.addArc(center: CGPoint(x: 50 * s, y: 68 * s), radius: 4.5 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            door.addLine(to: CGPoint(x: 54.5 * s, y: 76 * s))
            door.closeSubpath()
            dome.addPath(door)
            ctx.fill(body, with: cream)
            ctx.fill(dome, with: cream, style: FillStyle(eoFill: true))
            ctx.fill(Path(roundedRect: r(14, 44, 10, 3.5), cornerRadius: 1.75 * s), with: gold)
            ctx.fill(Path(roundedRect: r(76, 44, 10, 3.5), cornerRadius: 1.75 * s), with: gold)
            ctx.fill(Path(roundedRect: r(48.7, 27.5, 2.6, 8.5), cornerRadius: 0.6 * s), with: gold)
            ctx.fill(Path(ellipseIn: r(47, 22.5, 6, 6)), with: gold)
            ctx.fill(Path(roundedRect: r(12, 79.5, 76, 3), cornerRadius: 1.5 * s), with: gold)
        }
        .accessibilityHidden(true)
    }
}

struct AppBadge: View {
    var size: CGFloat = 36
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Theme.heroGradient)
            .frame(width: size, height: size)
            .overlay(MosqueMark().padding(size * 0.08))
    }
}
