//
//  ToolbarItemsManager.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - ToolbarItemsManagerDelegate

@MainActor
protocol ToolbarItemsManagerDelegate: AnyObject {
    var globalAccessoryProvider: GlassAccessoryProvider? { get }
    var globalSideButton: GlassSideButtonConfig? { get }

    func itemsManager(_ manager: ToolbarItemsManager, didChangeSelectedIndex index: Int)
    func itemsManagerDidSetItems(_ manager: ToolbarItemsManager)
    func itemsManager(_ manager: ToolbarItemsManager, didUpdateItemAt index: Int)
}

// MARK: - ToolbarItemsManager

/// Manages toolbar items CRUD, selection state and current item properties
@MainActor
final class ToolbarItemsManager {

    // MARK: - Properties

    weak var delegate: ToolbarItemsManagerDelegate?
    private(set) var items: [GlassToolbarItem] = []
    private(set) var selectedIndex: Int = 0
    var onSelectedIndexChanged: (@MainActor (Int) -> Void)?

    // MARK: - Computed Properties

    var count: Int {
        return items.count
    }

    var isEmpty: Bool {
        return items.isEmpty
    }

    var currentItem: GlassToolbarItem? {
        guard selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    /// Current side button config (item's sideButton takes priority over global)
    var currentSideButtonConfig: GlassSideButtonConfig? {
        if selectedIndex < items.count {
            if let itemSideButton = items[selectedIndex].sideButton {
                return itemSideButton
            }
        }
        return delegate?.globalSideButton
    }

    /// Current primary accessory provider (item's takes priority over global)
    var currentAccessoryProvider: GlassAccessoryProvider? {
        if selectedIndex < items.count {
            if let provider = items[selectedIndex].accessoryProvider {
                return provider
            }
        }
        return delegate?.globalAccessoryProvider
    }

    var currentAccessoryView: UIView? {
        return currentAccessoryProvider?.accessoryView
    }

    var currentSecondaryAccessoryProvider: GlassAccessoryProvider? {
        guard selectedIndex < items.count else { return nil }
        return items[selectedIndex].secondaryAccessoryProvider
    }

    var currentSecondaryAccessoryView: UIView? {
        return currentSecondaryAccessoryProvider?.accessoryView
    }

    // MARK: - Initialization

    init() {}

    deinit {
        MainActor.assumeIsolated {
            cleanup()
        }
    }

    // MARK: - Public Methods

    func setItems(_ newItems: [GlassToolbarItem]) {
        cleanupItemsReferences()
        items = newItems

        if !newItems.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = 0
        }

        delegate?.itemsManagerDidSetItems(self)
    }

    /// Update a single item without cleaning up other items' references
    func updateItem(at index: Int, with newItem: GlassToolbarItem) {
        guard index >= 0 && index < items.count else { return }
        items[index] = newItem
        delegate?.itemsManager(self, didUpdateItemAt: index)
    }

    @discardableResult
    func setSelectedIndex(_ index: Int) -> Bool {
        guard index >= 0 && index < items.count else { return false }
        guard index != selectedIndex else { return true }

        selectedIndex = index
        onSelectedIndexChanged?(index)
        delegate?.itemsManager(self, didChangeSelectedIndex: index)
        return true
    }

    func item(at index: Int) -> GlassToolbarItem? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }

    func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < items.count
    }

    func overflowItems(for indices: [Int]) -> [GlassToolbarItem] {
        return indices.compactMap { item(at: $0) }
    }

    func handleOverflowItemTap(at index: Int) {
        guard let item = item(at: index) else { return }
        item.action?()

        if item.isSelectable {
            setSelectedIndex(index)
        }
    }

    func cleanup() {
        cleanupItemsReferences()
        onSelectedIndexChanged = nil
    }

    // MARK: - Private Methods

    private func cleanupItemsReferences() {
        for i in 0..<items.count {
            items[i].cleanup()
        }
    }
}

// MARK: - Layout Info Generation

extension ToolbarItemsManager {

    func generateLayoutInfos() -> [ToolbarItemLayoutInfo] {
        return items.enumerated().map { index, item in
            item.toLayoutInfo(index: index)
        }
    }

    func generateSideButtonLayoutInfo() -> SideButtonLayoutInfo? {
        return currentSideButtonConfig?.toLayoutInfo()
    }
}
