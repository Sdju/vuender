import SwiftUI
import AppKit

struct KeyPressHandler: NSViewRepresentable {
    let onShiftChange: (Bool) -> Void
    let onCommandChange: (Bool) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyTrackingView()
        view.onShiftChange = onShiftChange
        view.onCommandChange = onCommandChange
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

class KeyTrackingView: NSView {
    var onShiftChange: ((Bool) -> Void)?
    var onCommandChange: ((Bool) -> Void)?
    private var eventMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)

        if newWindow == nil, let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isShiftPressed = event.modifierFlags.contains(.shift)
        let isCommandPressed = event.modifierFlags.contains(.command)

        onShiftChange?(isShiftPressed)
        onCommandChange?(isCommandPressed)
    }

    override var acceptsFirstResponder: Bool {
        return false
    }
}

