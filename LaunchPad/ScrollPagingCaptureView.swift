//
//  ScrollPagingCaptureView.swift
//  LaunchPad
//
//  A tiny NSViewRepresentable that captures scroll-wheel events and forwards
//  vertical delta to SwiftUI. Used to flip pages with mouse wheel / trackpad scroll.
//

import SwiftUI
import AppKit

struct ScrollPagingCaptureView: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ScrollCaptureNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollCaptureNSView)?.onScroll = onScroll
    }
}

private final class ScrollCaptureNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        // Install a local event monitor for scroll-wheel events so we don't
        // interfere with normal hit testing (background taps etc.).
        if window != nil, monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.onScroll?(event.scrollingDeltaY)
                return event
            }
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // Don't intercept mouse clicks; let them pass through to SwiftUI layers beneath.
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}




