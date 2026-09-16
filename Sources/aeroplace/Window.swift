import ApplicationServices
import Foundation

struct AXWindow {
    let element: AXUIElement

    static func match(pid: pid_t, title: String, attempts: Int = 20, interval: TimeInterval = 0.05) -> AXWindow? {
        for _ in 0..<attempts {
            let windows = all(pid: pid)
            if !windows.isEmpty {
                let named = windows.filter { $0.title() == title }
                return named.count == 1 ? named[0] : windows[0]
            }
            Thread.sleep(forTimeInterval: interval)
        }
        return nil
    }

    private static func all(pid: pid_t) -> [AXWindow] {
        var value: CFTypeRef?
        let app = AXUIElementCreateApplication(pid)
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let elements = value as? [AXUIElement]
        else { return [] }
        return elements.map { AXWindow(element: $0) }
    }

    func title() -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &value) == .success
        else { return nil }
        return value as? String
    }

    func size() -> CGSize? {
        guard let value = axValue(kAXSizeAttribute) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    func setPosition(_ point: CGPoint) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
    }

    func setSize(_ size: CGSize) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value)
    }

    private func axValue(_ attribute: String) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let raw = value, CFGetTypeID(raw) == AXValueGetTypeID()
        else { return nil }
        return (raw as! AXValue)
    }
}
