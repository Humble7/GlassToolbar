//
//  OverflowMenuHandler.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - OverflowMenuItem

@MainActor
struct OverflowMenuItem {
    let title: String
    let image: UIImage?
    let isToolbarItem: Bool
    let itemIndex: Int?
    let handler: @MainActor () -> Void
}

// MARK: - OverflowMenuHandlerDelegate

@MainActor
protocol OverflowMenuHandlerDelegate: AnyObject {
    var items: [GlassToolbarItem] { get }
    func getLayoutResultForOverflow() -> ToolbarLayoutResult?
    func getSideButtonConfigForOverflow() -> GlassSideButtonConfig?
    func getToolbarViewForOverflow() -> GlassToolbarView
    func presentOverflowMenu(_ alertController: UIAlertController)
    func handleOverflowItemTap(at index: Int)
}

// MARK: - OverflowMenuHandler

/// Handles overflow menu construction, ActionSheet display and iPad popover adaptation
@MainActor
final class OverflowMenuHandler {

    // MARK: - Properties

    weak var delegate: OverflowMenuHandlerDelegate?
    var cancelButtonTitle: String = "Cancel"
    var defaultActionTitle: String = "Action"

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func showMenu() {
        guard let delegate = delegate else { return }
        guard let result = delegate.getLayoutResultForOverflow() else { return }

        let menuItems = buildMenuItems(from: result)
        guard !menuItems.isEmpty else { return }

        let alert = createAlertController(with: menuItems)
        configurePopoverIfNeeded(alert, toolbarView: delegate.getToolbarViewForOverflow())
        delegate.presentOverflowMenu(alert)
    }

    func hasOverflowContent() -> Bool {
        guard let delegate = delegate else { return false }
        guard let result = delegate.getLayoutResultForOverflow() else { return false }

        return !result.overflowItemIndices.isEmpty ||
               (result.sideButtonMode == .hidden && delegate.getSideButtonConfigForOverflow() != nil)
    }

    // MARK: - Private Methods

    private func buildMenuItems(from result: ToolbarLayoutResult) -> [OverflowMenuItem] {
        guard let delegate = delegate else { return [] }

        var menuItems: [OverflowMenuItem] = []

        for index in result.overflowItemIndices {
            guard index < delegate.items.count else { continue }
            let item = delegate.items[index]
            let menuItem = OverflowMenuItem(
                title: item.title,
                image: item.icon,
                isToolbarItem: true,
                itemIndex: index
            ) { [weak delegate] in
                delegate?.handleOverflowItemTap(at: index)
            }
            menuItems.append(menuItem)
        }

        if result.sideButtonMode == .hidden, let config = delegate.getSideButtonConfigForOverflow() {
            let title = config.overflowTitle ?? defaultActionTitle
            let menuItem = OverflowMenuItem(
                title: title,
                image: config.icon,
                isToolbarItem: false,
                itemIndex: nil
            ) {
                config.action?()
            }
            menuItems.append(menuItem)
        }

        return menuItems
    }

    private func createAlertController(with menuItems: [OverflowMenuItem]) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for item in menuItems {
            let alertAction = UIAlertAction(title: item.title, style: .default) { _ in
                item.handler()
            }
            if let image = item.image {
                alertAction.setValue(image.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            alert.addAction(alertAction)
        }

        alert.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel))

        return alert
    }

    private func configurePopoverIfNeeded(_ alert: UIAlertController, toolbarView: GlassToolbarView) {
        guard let popover = alert.popoverPresentationController else { return }

        popover.sourceView = toolbarView

        if let overflowFrame = toolbarView.overflowButtonFrame {
            popover.sourceRect = overflowFrame
        } else {
            popover.sourceRect = CGRect(
                x: toolbarView.bounds.maxX - 40,
                y: toolbarView.bounds.midY,
                width: 1,
                height: 1
            )
        }
    }
}
