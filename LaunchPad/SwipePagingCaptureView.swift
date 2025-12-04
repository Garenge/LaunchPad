//
//  SwipePagingCaptureView.swift
//  LaunchPad
//
//  Captures horizontal mouse drag gestures (swipe) for page navigation.
//  Detects left/right drag gestures and triggers page changes when threshold is reached.
//

import SwiftUI
import AppKit

struct SwipePagingCaptureView: NSViewRepresentable {
    var onSwipe: (SwipeDirection) -> Void

    enum SwipeDirection {
        case left  // Swipe left = next page
        case right // Swipe right = previous page
    }

    func makeNSView(context: Context) -> NSView {
        let view = SwipeCaptureNSView()
        view.onSwipe = onSwipe
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? SwipeCaptureNSView)?.onSwipe = onSwipe
    }
}

private final class SwipeCaptureNSView: NSView {
    var onSwipe: ((SwipePagingCaptureView.SwipeDirection) -> Void)?

    private var dragStartLocation: NSPoint?
    private let swipeThreshold: CGFloat = 50 // Minimum drag distance to trigger page change

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        dragStartLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        guard let startLocation = dragStartLocation else { return }

        let currentLocation = convert(event.locationInWindow, from: nil)
        let deltaX = currentLocation.x - startLocation.x

        // Only trigger swipe if horizontal movement is significant
        if abs(deltaX) > swipeThreshold {
            if deltaX > 0 {
                // Dragging right = previous page
                onSwipe?(.right)
            } else {
                // Dragging left = next page
                onSwipe?(.left)
            }
            // Reset start location to prevent multiple triggers during one drag
            dragStartLocation = nil
        }
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        dragStartLocation = nil
    }

    // Don't intercept mouse clicks; let them pass through to SwiftUI layers beneath.
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

