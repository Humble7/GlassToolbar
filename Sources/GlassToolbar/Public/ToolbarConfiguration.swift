//
//  ToolbarConfiguration.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - Accessory Display State Machine

/// Accessory view display state
public enum AccessoryDisplayState: Equatable, Sendable {
    case collapsed
    case primaryOnly
    case primaryAndSecondary

    func nextState(hasSecondary: Bool, secondaryShownInCycle: Bool) -> (state: AccessoryDisplayState, markSecondaryShown: Bool) {
        switch self {
        case .collapsed:
            return (.primaryOnly, false)

        case .primaryOnly:
            if hasSecondary && !secondaryShownInCycle {
                return (.primaryAndSecondary, true)
            } else {
                return (.collapsed, false)
            }

        case .primaryAndSecondary:
            return (.primaryOnly, false)
        }
    }

    var showsPrimary: Bool {
        switch self {
        case .collapsed:
            return false
        case .primaryOnly, .primaryAndSecondary:
            return true
        }
    }

    var showsSecondary: Bool {
        switch self {
        case .collapsed, .primaryOnly:
            return false
        case .primaryAndSecondary:
            return true
        }
    }
}

// MARK: - Accessory State

/// Per-item accessory state
struct AccessoryItemState: Sendable {
    var displayState: AccessoryDisplayState = .primaryOnly
    var secondaryShownInCycle: Bool = false

    mutating func handleTap(hasSecondary: Bool) {
        let (nextState, markSecondaryShown) = displayState.nextState(
            hasSecondary: hasSecondary,
            secondaryShownInCycle: secondaryShownInCycle
        )

        if displayState == .collapsed && nextState == .primaryOnly {
            secondaryShownInCycle = false
        }

        if markSecondaryShown {
            secondaryShownInCycle = true
        }

        displayState = nextState
    }

    mutating func reset() {
        displayState = .primaryOnly
        secondaryShownInCycle = false
    }
}

// MARK: - Toolbar Appearance Configuration

/// Toolbar appearance configuration via dependency injection
public struct ToolbarAppearanceConfiguration: Sendable {

    // MARK: - Size

    public var toolbarHeight: CGFloat
    public var toolbarPadding: CGFloat
    public var floatingButtonSize: CGFloat
    public var toolbarToSideButtonSpacing: CGFloat

    // MARK: - Item Size

    public var itemIconSize: CGFloat
    public var itemFullSize: CGSize
    public var itemCompactSize: CGSize
    public var itemFontSize: CGFloat
    public var floatingButtonIconSize: CGFloat

    // MARK: - Animation

    public var animationDuration: TimeInterval
    public var springDamping: CGFloat
    public var springVelocity: CGFloat
    public var animationTranslationY: CGFloat
    public var secondaryAccessoryShowDelay: TimeInterval
    public var tapScaleFactor: CGFloat
    public var pressScaleFactor: CGFloat
    public var pressAlpha: CGFloat
    public var selectionAnimationDuration: TimeInterval
    public var selectionSpringDamping: CGFloat

    // MARK: - Shadow

    public var toolbarShadowRadius: CGFloat
    public var toolbarShadowOpacity: Float
    public var toolbarShadowOffset: CGSize
    public var floatingButtonShadowRadius: CGFloat
    public var floatingButtonShadowOpacity: Float
    public var floatingButtonShadowOffset: CGSize

    // MARK: - Glass Effect

    public var glossTopAlpha: CGFloat
    public var glossMiddleAlpha: CGFloat
    public var borderTopAlpha: CGFloat
    public var borderBottomAlpha: CGFloat
    public var selectionIndicatorAlpha: CGFloat

    // MARK: - Accessory

    public var accessoryToToolbarSpacing: CGFloat
    public var secondaryAccessorySpacing: CGFloat
    public var accessoryContentInsetsTop: CGFloat
    public var accessoryContentInsetsLeft: CGFloat
    public var accessoryContentInsetsBottom: CGFloat
    public var accessoryContentInsetsRight: CGFloat

    // MARK: - Ultra Minimal Mode

    public var ultraMinimalItemWidth: CGFloat
    public var ultraMinimalToolbarPadding: CGFloat
    public var ultraMinimalSideButtonSize: CGFloat

    // MARK: - Corner Radius

    public var toolbarCornerRadius: CGFloat?
    public var selectionIndicatorCornerRadius: CGFloat?
    public var accessoryCornerRadius: CGFloat

    // MARK: - Internal Spacing

    public var toolbarInternalPadding: CGFloat
    public var selectionIndicatorHeight: CGFloat
    public var selectionIndicatorHeightCompact: CGFloat
    public var selectionIndicatorWidthInset: CGFloat

    // MARK: - Computed Properties

    public var accessoryContentInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: accessoryContentInsetsTop,
            left: accessoryContentInsetsLeft,
            bottom: accessoryContentInsetsBottom,
            right: accessoryContentInsetsRight
        )
    }

    // MARK: - Initialization

    public init(
        toolbarHeight: CGFloat = 56,
        toolbarPadding: CGFloat = 16,
        floatingButtonSize: CGFloat = 48,
        toolbarToSideButtonSpacing: CGFloat = 16,
        itemIconSize: CGFloat = 24,
        itemFullSize: CGSize = CGSize(width: 56, height: 48),
        itemCompactSize: CGSize = CGSize(width: 44, height: 48),
        itemFontSize: CGFloat = 10,
        floatingButtonIconSize: CGFloat = 24,
        animationDuration: TimeInterval = 0.35,
        springDamping: CGFloat = 0.85,
        springVelocity: CGFloat = 0.5,
        animationTranslationY: CGFloat = 32,
        secondaryAccessoryShowDelay: TimeInterval = 0.15,
        tapScaleFactor: CGFloat = 0.88,
        pressScaleFactor: CGFloat = 0.92,
        pressAlpha: CGFloat = 0.85,
        selectionAnimationDuration: TimeInterval = 0.35,
        selectionSpringDamping: CGFloat = 0.7,
        toolbarShadowRadius: CGFloat = 20,
        toolbarShadowOpacity: Float = 0.18,
        toolbarShadowOffset: CGSize = CGSize(width: 0, height: 8),
        floatingButtonShadowRadius: CGFloat = 12,
        floatingButtonShadowOpacity: Float = 0.18,
        floatingButtonShadowOffset: CGSize = CGSize(width: 0, height: 4),
        glossTopAlpha: CGFloat = 0.28,
        glossMiddleAlpha: CGFloat = 0.08,
        borderTopAlpha: CGFloat = 0.5,
        borderBottomAlpha: CGFloat = 0.15,
        selectionIndicatorAlpha: CGFloat = 0.22,
        accessoryToToolbarSpacing: CGFloat = 12,
        secondaryAccessorySpacing: CGFloat = 4,
        accessoryContentInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
        ultraMinimalItemWidth: CGFloat = 44,
        ultraMinimalToolbarPadding: CGFloat = 24,
        ultraMinimalSideButtonSize: CGFloat = 44,
        toolbarCornerRadius: CGFloat? = nil,
        selectionIndicatorCornerRadius: CGFloat? = nil,
        accessoryCornerRadius: CGFloat = 20,
        toolbarInternalPadding: CGFloat = 4,
        selectionIndicatorHeight: CGFloat = 44,
        selectionIndicatorHeightCompact: CGFloat = 36,
        selectionIndicatorWidthInset: CGFloat = -4
    ) {
        self.toolbarHeight = toolbarHeight
        self.toolbarPadding = toolbarPadding
        self.floatingButtonSize = floatingButtonSize
        self.toolbarToSideButtonSpacing = toolbarToSideButtonSpacing
        self.itemIconSize = itemIconSize
        self.itemFullSize = itemFullSize
        self.itemCompactSize = itemCompactSize
        self.itemFontSize = itemFontSize
        self.floatingButtonIconSize = floatingButtonIconSize
        self.animationDuration = animationDuration
        self.springDamping = springDamping
        self.springVelocity = springVelocity
        self.animationTranslationY = animationTranslationY
        self.secondaryAccessoryShowDelay = secondaryAccessoryShowDelay
        self.tapScaleFactor = tapScaleFactor
        self.pressScaleFactor = pressScaleFactor
        self.pressAlpha = pressAlpha
        self.selectionAnimationDuration = selectionAnimationDuration
        self.selectionSpringDamping = selectionSpringDamping
        self.toolbarShadowRadius = toolbarShadowRadius
        self.toolbarShadowOpacity = toolbarShadowOpacity
        self.toolbarShadowOffset = toolbarShadowOffset
        self.floatingButtonShadowRadius = floatingButtonShadowRadius
        self.floatingButtonShadowOpacity = floatingButtonShadowOpacity
        self.floatingButtonShadowOffset = floatingButtonShadowOffset
        self.glossTopAlpha = glossTopAlpha
        self.glossMiddleAlpha = glossMiddleAlpha
        self.borderTopAlpha = borderTopAlpha
        self.borderBottomAlpha = borderBottomAlpha
        self.selectionIndicatorAlpha = selectionIndicatorAlpha
        self.accessoryToToolbarSpacing = accessoryToToolbarSpacing
        self.secondaryAccessorySpacing = secondaryAccessorySpacing
        self.accessoryContentInsetsTop = accessoryContentInsets.top
        self.accessoryContentInsetsLeft = accessoryContentInsets.left
        self.accessoryContentInsetsBottom = accessoryContentInsets.bottom
        self.accessoryContentInsetsRight = accessoryContentInsets.right
        self.ultraMinimalItemWidth = ultraMinimalItemWidth
        self.ultraMinimalToolbarPadding = ultraMinimalToolbarPadding
        self.ultraMinimalSideButtonSize = ultraMinimalSideButtonSize
        self.toolbarCornerRadius = toolbarCornerRadius
        self.selectionIndicatorCornerRadius = selectionIndicatorCornerRadius
        self.accessoryCornerRadius = accessoryCornerRadius
        self.toolbarInternalPadding = toolbarInternalPadding
        self.selectionIndicatorHeight = selectionIndicatorHeight
        self.selectionIndicatorHeightCompact = selectionIndicatorHeightCompact
        self.selectionIndicatorWidthInset = selectionIndicatorWidthInset
    }

    public var effectiveToolbarCornerRadius: CGFloat {
        toolbarCornerRadius ?? (toolbarHeight / 2)
    }

    /// Auto-calculated selection indicator corner radius based on nested corner radius principle
    /// Formula: Inner radius = Outer radius - Vertical padding
    public var effectiveSelectionIndicatorCornerRadius: CGFloat {
        if let explicitRadius = selectionIndicatorCornerRadius {
            return explicitRadius
        }
        let verticalPadding = (toolbarHeight - selectionIndicatorHeight) / 2
        return max(0, effectiveToolbarCornerRadius - verticalPadding)
    }

    // MARK: - Presets

    public static let `default` = ToolbarAppearanceConfiguration()

    /// Compact preset - optimized for smaller screens while maintaining 44pt minimum touch targets
    public static let compact = ToolbarAppearanceConfiguration(
        toolbarHeight: 48,
        toolbarPadding: 12,
        floatingButtonSize: 44,
        toolbarToSideButtonSpacing: 12,
        itemIconSize: 20,
        itemFullSize: CGSize(width: 48, height: 44),
        itemCompactSize: CGSize(width: 44, height: 44),
        itemFontSize: 10,
        floatingButtonIconSize: 20,
        animationTranslationY: 24,
        toolbarShadowRadius: 16,
        toolbarShadowOpacity: 0.15,
        floatingButtonShadowRadius: 12,
        floatingButtonShadowOpacity: 0.15,
        accessoryToToolbarSpacing: 8,
        secondaryAccessorySpacing: 4,
        accessoryContentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
        ultraMinimalItemWidth: 44,
        ultraMinimalToolbarPadding: 16,
        ultraMinimalSideButtonSize: 44,
        accessoryCornerRadius: 16,
        toolbarInternalPadding: 4,
        selectionIndicatorHeight: 40,
        selectionIndicatorHeightCompact: 32,
        selectionIndicatorWidthInset: -4
    )

    /// Spacious preset - optimized for iPad and larger displays
    public static let spacious = ToolbarAppearanceConfiguration(
        toolbarHeight: 64,
        toolbarPadding: 24,
        floatingButtonSize: 56,
        toolbarToSideButtonSpacing: 24,
        itemIconSize: 28,
        itemFullSize: CGSize(width: 64, height: 56),
        itemCompactSize: CGSize(width: 52, height: 56),
        itemFontSize: 11,
        floatingButtonIconSize: 28,
        animationTranslationY: 32,
        toolbarShadowRadius: 24,
        toolbarShadowOpacity: 0.18,
        floatingButtonShadowRadius: 16,
        floatingButtonShadowOpacity: 0.18,
        accessoryToToolbarSpacing: 16,
        secondaryAccessorySpacing: 8,
        accessoryContentInsets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
        ultraMinimalItemWidth: 48,
        ultraMinimalToolbarPadding: 24,
        ultraMinimalSideButtonSize: 48,
        accessoryCornerRadius: 24,
        toolbarInternalPadding: 4,
        selectionIndicatorHeight: 52,
        selectionIndicatorHeightCompact: 40,
        selectionIndicatorWidthInset: -4
    )
}
