//
//  SwipePagingCaptureView.swift
//  LaunchPad
//
//  Captures horizontal mouse drag gestures for page navigation with visual feedback.
//  Provides real-time drag offset during dragging and final swipe direction on release.
//

import SwiftUI
import AppKit

struct SwipePagingCaptureView: NSViewRepresentable {
    var onDragChanged: (CGFloat) -> Void  // Real-time drag offset (deltaX)
    var onDragEnded: (SwipeDirection?) -> Void  // Final swipe direction or nil if cancelled

    enum SwipeDirection {
        case left  // Swipe left = next page
        case right // Swipe right = previous page
    }

    func makeNSView(context: Context) -> NSView {
        let view = SwipeCaptureNSView()
        view.onDragChanged = onDragChanged
        view.onDragEnded = onDragEnded
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? SwipeCaptureNSView {
            view.onDragChanged = onDragChanged
            view.onDragEnded = onDragEnded
        }
    }
}

private final class SwipeCaptureNSView: NSView {
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: ((SwipePagingCaptureView.SwipeDirection?) -> Void)?

    private var dragStartLocation: NSPoint?
    private var dragStartTime: Date?
    private var isDragging: Bool = false
    private var lastDragLocation: NSPoint?
    private var hasMoved: Bool = false  // Track if mouse has moved significantly
    private let minDragDistance: CGFloat = 5  // Minimum distance to consider it a drag (not a click)
    private let swipeDistanceThreshold: CGFloat = 120 // Minimum drag distance to trigger page change
    private let swipeVelocityThreshold: CGFloat = 600 // Minimum velocity (points per second) to trigger page change

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        dragStartLocation = location
        lastDragLocation = location
        dragStartTime = Date()
        isDragging = false
        hasMoved = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startLocation = dragStartLocation else { return }
        
        let currentLocation = convert(event.locationInWindow, from: nil)
        let deltaX = currentLocation.x - startLocation.x
        let deltaY = currentLocation.y - startLocation.y
        let totalDistance = sqrt(deltaX * deltaX + deltaY * deltaY)
        
        // Check if mouse has moved enough to be considered a drag
        if !hasMoved && totalDistance > minDragDistance {
            hasMoved = true
        }
        
        // Only process horizontal drags
        guard abs(deltaX) > abs(deltaY) else { return }
        
        if !isDragging {
            isDragging = true
        }
        
        // Report real-time drag offset
        onDragChanged?(deltaX)
        lastDragLocation = currentLocation
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            dragStartLocation = nil
            dragStartTime = nil
            lastDragLocation = nil
            isDragging = false
            hasMoved = false
            // Reset drag offset
            onDragChanged?(0)
        }

        // If no significant movement occurred, treat as click and let it pass through
        guard hasMoved,
              isDragging,
              let startLocation = dragStartLocation,
              let startTime = dragStartTime,
              let endLocation = lastDragLocation else {
            // No drag occurred - this is a click, forward to background layer
            // Post notification to dismiss Launchpad (same as clicking background)
            NotificationCenter.default.post(name: NSNotification.Name("DismissLaunchpad"), object: nil)
            return
        }

        let deltaX = endLocation.x - startLocation.x
        let deltaY = endLocation.y - startLocation.y
        let timeElapsed = max(Date().timeIntervalSince(startTime), 0.001)

        // Only consider horizontal swipes
        guard abs(deltaX) > abs(deltaY) else {
            onDragEnded?(nil)
            return
        }

        // Calculate velocity
        let velocity = abs(deltaX) / timeElapsed
        let distance = abs(deltaX)

        // Determine swipe direction: BOTH distance AND velocity must meet thresholds
        var direction: SwipePagingCaptureView.SwipeDirection?
        if distance >= swipeDistanceThreshold && velocity >= swipeVelocityThreshold {
            direction = deltaX > 0 ? .right : .left
        }

        onDragEnded?(direction)
    }

    // Allow this view to receive mouse events for dragging
    override func hitTest(_ point: NSPoint) -> NSView? {
        return self
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}


