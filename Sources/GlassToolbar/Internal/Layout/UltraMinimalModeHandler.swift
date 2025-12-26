//
//  UltraMinimalModeHandler.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - UltraMinimalLayoutResult

/// Ultra minimal mode layout result
struct UltraMinimalLayoutResult {
    let visibleItemIndex: Int
    let itemDisplayModes: [Int: ItemDisplayMode]
    let visibleIndices: [Int]
    let overflowIndices: [Int]
    let toolbarWidth: CGFloat
    let sideButtonMode: SideButtonDisplayMode

    func toApplicationParams() -> ToolbarLayoutApplication {
        ToolbarLayoutApplication(
            itemDisplayModes: itemDisplayModes,
            visibleIndices: visibleIndices,
            itemSpacing: 0,
            showOverflowButton: false,
            toolbarWidth: toolbarWidth,
            sideButtonMode: sideButtonMode,
            accessoryWidth: nil,
            compressionLevel: .iconOnly  // Ultra minimal always uses compact indicator
        )
    }
}

// MARK: - UltraMinimalModeHandlerDelegate

@MainActor
protocol UltraMinimalModeHandlerDelegate: AnyObject {
    var selectedIndex: Int { get }
    var items: [GlassToolbarItem] { get }
    var currentSideButtonConfig: GlassSideButtonConfig? { get }
    var appearanceConfiguration: ToolbarAppearanceConfiguration { get }
    var containerWidth: CGFloat { get }

    func hideAllAccessoryViews(animated: Bool)
    func restoreAccessoryViewsIfNeeded()
    func restoreNormalLayout(animated: Bool)
    func applyLayoutChanges(_ params: ToolbarLayoutApplication, animated: Bool)
}

// MARK: - UltraMinimalModeHandler

/// Manages ultra minimal mode lifecycle including state, layout calculation and mode switching
@MainActor
final class UltraMinimalModeHandler {

    // MARK: - Properties

    weak var delegate: UltraMinimalModeHandlerDelegate?
    private(set) var isEnabled: Bool = false
    var onModeChanged: (@MainActor (Bool) -> Void)?

    // MARK: - Computed Configuration

    private var compactSideButtonSize: CGFloat {
        delegate?.appearanceConfiguration.ultraMinimalSideButtonSize ?? 44
    }

    private var compactSideButtonSpacing: CGFloat {
        // Use a smaller spacing in ultra minimal mode
        (delegate?.appearanceConfiguration.toolbarToSideButtonSpacing ?? 16) / 2
    }

    // MARK: - Initialization

    init() {}

    deinit {
        MainActor.assumeIsolated {
            onModeChanged = nil
        }
    }

    // MARK: - Public Methods

    func setEnabled(_ enabled: Bool, animated: Bool) {
        guard isEnabled != enabled else { return }
        isEnabled = enabled
        applyMode(animated: animated)
        onModeChanged?(enabled)
    }

    func toggle(animated: Bool = true) {
        setEnabled(!isEnabled, animated: animated)
    }

    func refreshLayoutIfNeeded(animated: Bool) {
        guard isEnabled else { return }
        performLayoutUpdate(animated: animated)
    }

    // MARK: - Layout Calculation

    func calculateLayout() -> UltraMinimalLayoutResult? {
        guard let delegate = delegate else { return nil }
        guard delegate.containerWidth > 0 else { return nil }
        guard !delegate.items.isEmpty else { return nil }

        let essentialItemIndex = findMostEssentialItemIndex()

        var itemModes: [Int: ItemDisplayMode] = [:]
        var visibleIndices: [Int] = []
        var overflowIndices: [Int] = []

        for (index, _) in delegate.items.enumerated() {
            if index == essentialItemIndex {
                itemModes[index] = .iconOnly
                visibleIndices.append(index)
            } else {
                itemModes[index] = .hidden
                overflowIndices.append(index)
            }
        }

        let config = delegate.appearanceConfiguration
        let toolbarWidth = config.ultraMinimalItemWidth + config.ultraMinimalToolbarPadding

        let sideButtonMode: SideButtonDisplayMode
        if delegate.currentSideButtonConfig != nil {
            sideButtonMode = .compact(size: compactSideButtonSize, spacing: compactSideButtonSpacing)
        } else {
            sideButtonMode = .none
        }

        return UltraMinimalLayoutResult(
            visibleItemIndex: essentialItemIndex,
            itemDisplayModes: itemModes,
            visibleIndices: visibleIndices,
            overflowIndices: overflowIndices,
            toolbarWidth: toolbarWidth,
            sideButtonMode: sideButtonMode
        )
    }

    // MARK: - Private Methods

    private func applyMode(animated: Bool) {
        guard let delegate = delegate else { return }

        if isEnabled {
            delegate.hideAllAccessoryViews(animated: animated)
            performLayoutUpdate(animated: animated)
        } else {
            delegate.restoreNormalLayout(animated: animated)
            delegate.restoreAccessoryViewsIfNeeded()
        }
    }

    private func performLayoutUpdate(animated: Bool) {
        guard let delegate = delegate else { return }
        guard let layoutResult = calculateLayout() else { return }
        delegate.applyLayoutChanges(layoutResult.toApplicationParams(), animated: animated)
    }

    /// Find the most essential item index
    /// Returns currently selected item first, otherwise finds essential priority item
    private func findMostEssentialItemIndex() -> Int {
        guard let delegate = delegate else { return 0 }

        if delegate.selectedIndex < delegate.items.count {
            return delegate.selectedIndex
        }

        for (index, item) in delegate.items.enumerated() {
            if item.priority == .essential {
                return index
            }
        }

        return 0
    }
}
