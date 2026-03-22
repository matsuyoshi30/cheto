import AppKit

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isFloatingPanel = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
