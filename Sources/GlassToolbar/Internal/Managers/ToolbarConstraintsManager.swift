//
//  ToolbarConstraintsManager.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - ToolbarConstraintsManagerDelegate

@MainActor
protocol ToolbarConstraintsManagerDelegate: AnyObject {
    func getContainerView() -> UIView
    func getToolbarView() -> GlassToolbarView
    func getToolbarPadding() -> CGFloat
    func getToolbarHeight() -> CGFloat
    func getToolbarInternalPadding() -> CGFloat
    func calculateInitialToolbarWidth() -> CGFloat
}

// MARK: - ToolbarConstraintsManager

/// Manages toolbar Auto Layout constraints creation and updates
@MainActor
final class ToolbarConstraintsManager {

    // MARK: - Properties

    weak var delegate: ToolbarConstraintsManagerDelegate?

    private var bottomConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    private(set) var currentCenterXOffset: CGFloat = 0

    // MARK: - Computed Properties

    var currentWidth: CGFloat {
        return widthConstraint?.constant ?? 0
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Setup

    /// Setup constraints. Must be called after toolbarView is added to container.
    func setupConstraints() {
        guard let delegate = delegate else { return }

        let containerView = delegate.getContainerView()
        let toolbarView = delegate.getToolbarView()
        let padding = delegate.getToolbarPadding()
        let height = delegate.getToolbarHeight()
        let internalPadding = delegate.getToolbarInternalPadding()
        let calculatedWidth = delegate.calculateInitialToolbarWidth()

        // Minimum width must accommodate internal padding to avoid constraint conflicts
        let minWidth = internalPadding * 2
        let initialWidth = max(minWidth, calculatedWidth)

        toolbarView.translatesAutoresizingMaskIntoConstraints = false

        let bottom = toolbarView.bottomAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.bottomAnchor,
            constant: -padding
        )

        let centerX = toolbarView.centerXAnchor.constraint(
            equalTo: containerView.centerXAnchor,
            constant: 0
        )

        let width = toolbarView.widthAnchor.constraint(equalToConstant: initialWidth)
        let heightConst = toolbarView.heightAnchor.constraint(equalToConstant: height)

        bottomConstraint = bottom
        centerXConstraint = centerX
        widthConstraint = width
        heightConstraint = heightConst

        NSLayoutConstraint.activate([bottom, centerX, width, heightConst])
    }

    // MARK: - Update Methods

    func updateWidth(_ calculatedWidth: CGFloat, sideButtonMode: SideButtonDisplayMode) {
        guard let delegate = delegate else { return }
        let containerView = delegate.getContainerView()
        guard containerView.bounds.width > 0 else { return }

        let padding = delegate.getToolbarPadding()
        let internalPadding = delegate.getToolbarInternalPadding()
        let containerWidth = containerView.bounds.width

        let maxWidth: CGFloat
        switch sideButtonMode {
        case .full(let size, let spacing), .compact(let size, let spacing):
            maxWidth = containerWidth - padding - spacing - size - padding
        case .integrated, .hidden, .none:
            maxWidth = containerWidth - (padding * 2)
        }

        // Minimum width must accommodate internal padding to avoid constraint conflicts
        let minWidth = internalPadding * 2
        let targetWidth = max(minWidth, min(calculatedWidth, maxWidth))
        widthConstraint?.constant = targetWidth

        updateCenterOffset(sideButtonMode: sideButtonMode)
    }

    /// Update toolbar center offset
    /// When side button exists, offset to center the combined toolbar + side button
    func updateCenterOffset(sideButtonMode: SideButtonDisplayMode) {
        let offset: CGFloat
        switch sideButtonMode {
        case .full(let size, let spacing), .compact(let size, let spacing):
            offset = -(spacing + size) / 2
        case .integrated, .hidden, .none:
            offset = 0
        }

        currentCenterXOffset = offset
        centerXConstraint?.constant = offset
    }

    func updateBottomOffset(_ offset: CGFloat) {
        bottomConstraint?.constant = offset
    }

    func updateHeight(_ height: CGFloat) {
        heightConstraint?.constant = height
    }

    var currentBottomOffset: CGFloat {
        return bottomConstraint?.constant ?? 0
    }
}
