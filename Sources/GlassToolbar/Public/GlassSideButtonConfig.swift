//
//  GlassSideButtonConfig.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - SwipeDirection

/// Swipe direction for gesture recognition
public enum SwipeDirection: Sendable, CaseIterable {
    case up
    case down
    case left
    case right
}

// MARK: - SideButtonGestureConfig

/// Gesture configuration for side button
/// Supports tap, swipe (4 directions), with extensibility for long press and pan
@MainActor
public struct SideButtonGestureConfig {

    // MARK: - Callbacks

    /// Tap gesture callback
    public var onTap: (@MainActor () -> Void)?

    /// Swipe gesture callback with direction
    public var onSwipe: (@MainActor (SwipeDirection) -> Void)?

    // MARK: - Configuration

    /// Enabled swipe directions (default: all directions)
    public var enabledDirections: Set<SwipeDirection>

    /// Minimum distance to trigger swipe (in points)
    public var swipeThreshold: CGFloat

    /// Minimum velocity to trigger swipe (in points per second)
    public var swipeVelocityThreshold: CGFloat

    // MARK: - Initialization

    public init(
        onTap: (@MainActor () -> Void)? = nil,
        onSwipe: (@MainActor (SwipeDirection) -> Void)? = nil,
        enabledDirections: Set<SwipeDirection> = Set(SwipeDirection.allCases),
        swipeThreshold: CGFloat = 30,
        swipeVelocityThreshold: CGFloat = 200
    ) {
        self.onTap = onTap
        self.onSwipe = onSwipe
        self.enabledDirections = enabledDirections
        self.swipeThreshold = swipeThreshold
        self.swipeVelocityThreshold = swipeVelocityThreshold
    }

    // MARK: - Cleanup

    mutating func cleanup() {
        onTap = nil
        onSwipe = nil
    }
}

// MARK: - Side floating button configuration

/// Side floating button configuration
@MainActor
public struct GlassSideButtonConfig {
    public var icon: UIImage?
    public var backgroundColor: UIColor
    public var tintColor: UIColor

    /// Legacy action callback (for backward compatibility)
    /// Use `gestures.onTap` for new implementations
    public var action: (@MainActor () -> Void)?

    /// Gesture configuration for advanced gesture support
    public var gestures: SideButtonGestureConfig?

    public let priority: SideButtonPriority
    public let overflowTitle: String?

    // MARK: - Initialization

    public init(
        icon: UIImage?,
        backgroundColor: UIColor = .systemBlue,
        tintColor: UIColor = .white,
        priority: SideButtonPriority = .primary,
        overflowTitle: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        gestures: SideButtonGestureConfig? = nil
    ) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.priority = priority
        self.overflowTitle = overflowTitle
        self.action = action
        self.gestures = gestures
    }

    // MARK: - Computed Properties

    /// Effective tap action (gestures.onTap takes priority over action)
    var effectiveTapAction: (@MainActor () -> Void)? {
        gestures?.onTap ?? action
    }

    /// Effective swipe handler
    var effectiveSwipeHandler: (@MainActor (SwipeDirection) -> Void)? {
        gestures?.onSwipe
    }

    /// Check if swipe is enabled for a direction
    func isSwipeEnabled(for direction: SwipeDirection) -> Bool {
        guard let gestures = gestures else { return false }
        return gestures.enabledDirections.contains(direction) && gestures.onSwipe != nil
    }

    /// Check if any swipe gesture is enabled
    var hasSwipeGestures: Bool {
        guard let gestures = gestures else { return false }
        return !gestures.enabledDirections.isEmpty && gestures.onSwipe != nil
    }

    // MARK: - Layout Info

    func toLayoutInfo() -> SideButtonLayoutInfo {
        return SideButtonLayoutInfo(priority: priority, overflowTitle: overflowTitle)
    }

    // MARK: - Cleanup

    mutating func cleanup() {
        action = nil
        gestures?.cleanup()
        gestures = nil
    }
}
