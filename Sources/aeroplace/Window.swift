import ApplicationServices
import Foundation

@_silgen_name("_AXUIElementGetWindow")
private func axWindowId(_ element: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

struct AXWindow {
    let element: AXUIElement

    static func match(
        pid: pid_t, id: CGWindowID, attempts: Int = 20, interval: TimeInterval = 0.05
    ) -> AXWindow? {
        for _ in 0..<attempts {
            if let window = all(pid: pid).first(where: { $0.id() == id }) { return window }
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

    func id() -> CGWindowID? {
        var id: CGWindowID = 0
        return axWindowId(element, &id) == .success ? id : nil
    }

    func size() -> CGSize? {
        guard let value = axValue(kAXSizeAttribute) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    @discardableResult
    func setPosition(_ point: CGPoint) -> Bool {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return false }
        return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value) == .success
    }

    @discardableResult
    func setSize(_ size: CGSize) -> Bool {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return false }
        return AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value) == .success
    }

    private func axValue(_ attribute: String) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let raw = value, CFGetTypeID(raw) == AXValueGetTypeID()
        else { return nil }
        return (raw as! AXValue)
    }
}
