import AppKit

enum Screen {
    static func visibleFrame(index: Int) -> CGRect? {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return nil }
        let chosen = (index >= 1 && index <= screens.count) ? screens[index - 1] : NSScreen.main
        guard let visible = chosen?.visibleFrame else { return nil }
        return CGRect(
            x: visible.origin.x,
            y: primary.frame.height - (visible.origin.y + visible.height),
            width: visible.width,
            height: visible.height
        )
    }
}
