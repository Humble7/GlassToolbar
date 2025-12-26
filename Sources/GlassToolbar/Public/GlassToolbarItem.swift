//
//  GlassToolbarItem.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

/// Toolbar item configuration
@MainActor
public struct GlassToolbarItem {
    public var title: String
    public var icon: UIImage?
    public var selectedIcon: UIImage?
    public let isSelectable: Bool
    public var sideButton: GlassSideButtonConfig?
    public var action: (@MainActor () -> Void)?

    public let priority: ItemPriority
    public let compactTitle: String?
    public let canHideTitle: Bool

    // MARK: - Accessory Provider

    public var accessoryProvider: GlassAccessoryProvider?
    public var secondaryAccessoryProvider: GlassAccessoryProvider?

    // MARK: - Initialization

    public init(
        title: String,
        icon: UIImage?,
        selectedIcon: UIImage? = nil,
        isSelectable: Bool = true,
        priority: ItemPriority = .primary,
        compactTitle: String? = nil,
        canHideTitle: Bool = true,
        sideButton: GlassSideButtonConfig? = nil,
        accessoryProvider: GlassAccessoryProvider? = nil,
        secondaryAccessoryProvider: GlassAccessoryProvider? = nil,
        action: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.isSelectable = isSelectable
        self.priority = priority
        self.compactTitle = compactTitle
        self.canHideTitle = canHideTitle
        self.sideButton = sideButton
        self.accessoryProvider = accessoryProvider
        self.secondaryAccessoryProvider = secondaryAccessoryProvider
        self.action = action
    }

    func toLayoutInfo(index: Int) -> ToolbarItemLayoutInfo {
        return ToolbarItemLayoutInfo(
            index: index,
            priority: priority,
            canHideTitle: canHideTitle,
            fullWidth: nil,
            compactWidth: nil
        )
    }

    mutating func cleanup() {
        action = nil
        sideButton?.cleanup()
        sideButton = nil

        accessoryProvider?.cleanup()
        accessoryProvider = nil
        secondaryAccessoryProvider?.cleanup()
        secondaryAccessoryProvider = nil
    }
}
