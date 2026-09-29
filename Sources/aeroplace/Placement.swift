import AppKit

struct UsableArea {
    static let areaStages = 4
    static let widthExponent = 2.0 / 3.0
    static let heightExponent = 1.0 / 3.0

    let origin: CGPoint
    let size: CGSize

    init(screen: NSScreen, primaryHeight: CGFloat, bottomInset: Double) {
        let visible = screen.visibleFrame
        size = CGSize(
            width: visible.width,
            height: max(visible.height - bottomInset, 1)
        )
        origin = CGPoint(
            x: visible.origin.x,
            y: primaryHeight - (visible.origin.y + visible.height)
        )
    }

    func centre(for rect: CGSize) -> CGPoint {
        CGPoint(
            x: (origin.x + (size.width - rect.width) / 2).rounded(),
            y: (origin.y + (size.height - rect.height) / 2).rounded()
        )
    }

    func stageAfter(height: CGFloat) -> CGSize {
        let fractions = (1...Self.areaStages).map { Double($0) / Double(Self.areaStages) }
        let heights = fractions.map { (size.height * pow($0, Self.heightExponent)).rounded() }
        let nearest = heights.indices.min { abs(heights[$0] - height) < abs(heights[$1] - height) } ?? 0
        let next = (nearest + 1) % fractions.count
        return CGSize(
            width: (size.width * pow(fractions[next], Self.widthExponent)).rounded(),
            height: heights[next]
        )
    }
}

enum Screen {
    static func resolve(index: Int) -> (screen: NSScreen, primaryHeight: CGFloat)? {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return nil }
        let chosen = (index >= 1 && index <= screens.count) ? screens[index - 1] : NSScreen.main
        guard let chosen else { return nil }
        return (chosen, primary.frame.height)
    }

    static func visibleFrame(index: Int) -> CGRect? {
        guard let (screen, primaryHeight) = resolve(index: index) else { return nil }
        let visible = screen.visibleFrame
        return CGRect(
            x: visible.origin.x,
            y: primaryHeight - (visible.origin.y + visible.height),
            width: visible.width,
            height: visible.height
        )
    }
}
