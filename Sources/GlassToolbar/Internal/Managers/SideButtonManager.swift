//
//  SideButtonManager.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - SideButtonManagerDelegate

@MainActor
protocol SideButtonManagerDelegate: AnyObject {
    var toolbarViewForSideButton: UIView { get }
    var containerViewForSideButton: UIView { get }
    var appearanceConfigurationForSideButton: ToolbarAppearanceConfiguration { get }
    func sideButtonManagerRequestsLayoutUpdate(animated: Bool)
}

// MARK: - SideButtonManager

/// Manages side button lifecycle including creation, display, animation and constraints
@MainActor
final class SideButtonManager {

    // MARK: - Properties

    weak var delegate: SideButtonManagerDelegate?
    private let animator: ToolbarAnimator
    private(set) var floatingButton: GlassFloatingButton?
    private var previousHasSideButton: Bool = false
    private var currentConfig: GlassSideButtonConfig?

    // MARK: - Constraints

    private var floatingButtonCenterYConstraint: NSLayoutConstraint?
    private var floatingButtonWidthConstraint: NSLayoutConstraint?
    private var floatingButtonHeightConstraint: NSLayoutConstraint?
    private var floatingButtonLeadingConstraint: NSLayoutConstraint?
    private var floatingButtonTrailingSafetyConstraint: NSLayoutConstraint?

    // MARK: - Computed Properties

    private var appearanceConfiguration: ToolbarAppearanceConfiguration {
        delegate?.appearanceConfigurationForSideButton ?? .default
    }

    private var floatingButtonSize: CGFloat {
        appearanceConfiguration.floatingButtonSize
    }

    private var toolbarToSideButtonSpacing: CGFloat {
        appearanceConfiguration.toolbarToSideButtonSpacing
    }

    private var toolbarPadding: CGFloat {
        appearanceConfiguration.toolbarPadding
    }

    private var sideButtonHiddenTransform: CGAffineTransform {
        let slideDistance = floatingButtonSize + toolbarToSideButtonSpacing
        return CGAffineTransform(translationX: -slideDistance, y: 0)
    }

    // MARK: - Initialization

    init(animator: ToolbarAnimator) {
        self.animator = animator
    }

    deinit {
        MainActor.assumeIsolated {
            cleanup()
        }
    }

    // MARK: - Public Methods

    func updateConfiguration(_ config: GlassSideButtonConfig?, animated: Bool) {
        let currentHasSideButton = config != nil
        let sideButtonPresenceChanged = currentHasSideButton != previousHasSideButton

        currentConfig = config

        animator.interruptAnimation(.floatingButtonShow)
        animator.interruptAnimation(.floatingButtonHide)

        if sideButtonPresenceChanged {
            previousHasSideButton = currentHasSideButton

            if let config = config {
                showSideButton(config: config, animated: animated, triggersLayoutUpdate: true)
            } else {
                hideSideButton(animated: animated, triggersLayoutUpdate: true)
            }
        } else if let config = config {
            showSideButton(config: config, animated: animated, triggersLayoutUpdate: false)
        }
    }

    func initializeWithConfiguration(_ config: GlassSideButtonConfig?) {
        previousHasSideButton = config != nil
        currentConfig = config

        if let config = config {
            showSideButton(config: config, animated: false, triggersLayoutUpdate: false)
        }
    }

    func applyLayoutMode(_ mode: SideButtonDisplayMode) {
        switch mode {
        case .full(let size, let spacing), .compact(let size, let spacing):
            guard let config = currentConfig else {
                hideSideButtonImmediately()
                return
            }
            if floatingButton == nil {
                _ = createSideButton(config: config)
                floatingButton?.transform = .identity
                floatingButton?.alpha = 1
            }
            updateSideButtonSize(size, spacing: spacing)

        case .integrated, .hidden, .none:
            hideSideButtonImmediately()
        }
    }

    func performTapFeedback() {
        guard let button = floatingButton else { return }
        animator.tapFeedback(button, type: .floatingButtonTap)
    }

    /// Update side button appearance dynamically
    func updateAppearance(
        icon: UIImage? = nil,
        backgroundColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        animated: Bool = true
    ) {
        floatingButton?.updateAppearance(
            icon: icon,
            backgroundColor: backgroundColor,
            tintColor: tintColor,
            animated: animated
        )
    }

    func cleanup() {
        floatingButton?.onTap = nil
        floatingButton?.onSwipe = nil
        floatingButton?.removeFromSuperview()
        floatingButton = nil
        currentConfig = nil
    }

    // MARK: - Private Methods - Show/Hide

    private func showSideButton(
        config: GlassSideButtonConfig,
        animated: Bool,
        triggersLayoutUpdate: Bool
    ) {
        animator.interruptAnimation(.floatingButtonHide)

        if triggersLayoutUpdate {
            delegate?.sideButtonManagerRequestsLayoutUpdate(animated: animated)
        }

        if let existingButton = floatingButton {
            replaceSideButton(existingButton, with: config, animated: animated)
        } else {
            let button = createSideButton(config: config)
            if animated {
                animateSideButtonIn(button)
            } else {
                button.transform = .identity
                button.alpha = 1
            }
        }
    }

    private func hideSideButton(animated: Bool, triggersLayoutUpdate: Bool) {
        animator.interruptAnimation(.floatingButtonShow)

        if triggersLayoutUpdate {
            delegate?.sideButtonManagerRequestsLayoutUpdate(animated: animated)
        }

        guard let button = floatingButton else { return }

        if animated {
            animateSideButtonOut(button) { [weak self] in
                guard let self = self else { return }
                if self.currentConfig == nil {
                    self.removeSideButton(button)
                }
            }
        } else {
            removeSideButton(button)
        }
    }

    private func hideSideButtonImmediately() {
        guard let button = floatingButton else { return }
        removeSideButton(button)
    }

    // MARK: - Private Methods - Button Creation

    @discardableResult
    private func createSideButton(config: GlassSideButtonConfig) -> GlassFloatingButton {
        guard let delegate = delegate else {
            fatalError("SideButtonManager delegate must be set before creating button")
        }

        floatingButton?.removeFromSuperview()
        floatingButton = nil

        let button = GlassFloatingButton(config: config)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Configure tap callback (uses effectiveTapAction for backward compatibility)
        button.onTap = { [weak self] in
            config.effectiveTapAction?()
            self?.performTapFeedback()
        }

        // Configure swipe gesture
        if let gestures = config.gestures {
            button.enabledSwipeDirections = gestures.enabledDirections
            button.swipeThreshold = gestures.swipeThreshold
            button.swipeVelocityThreshold = gestures.swipeVelocityThreshold
            button.onSwipe = gestures.onSwipe
        }

        let containerView = delegate.containerViewForSideButton
        let toolbarView = delegate.toolbarViewForSideButton

        containerView.insertSubview(button, belowSubview: toolbarView)
        floatingButton = button

        setupSideButtonConstraints(button, toolbarView: toolbarView, containerView: containerView)

        UIView.performWithoutAnimation {
            button.transform = self.sideButtonHiddenTransform
            button.alpha = 0
            containerView.layoutIfNeeded()
        }

        return button
    }

    private func setupSideButtonConstraints(
        _ button: GlassFloatingButton,
        toolbarView: UIView,
        containerView: UIView
    ) {
        let leadingConstraint = button.leadingAnchor.constraint(
            equalTo: toolbarView.trailingAnchor,
            constant: toolbarToSideButtonSpacing
        )
        let centerYConstraint = button.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor)
        let widthConstraint = button.widthAnchor.constraint(equalToConstant: floatingButtonSize)
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: floatingButtonSize)

        let trailingSafetyConstraint = button.trailingAnchor.constraint(
            lessThanOrEqualTo: containerView.trailingAnchor,
            constant: -toolbarPadding
        )
        trailingSafetyConstraint.priority = .required - 1

        floatingButtonCenterYConstraint = centerYConstraint
        floatingButtonWidthConstraint = widthConstraint
        floatingButtonHeightConstraint = heightConstraint
        floatingButtonLeadingConstraint = leadingConstraint
        floatingButtonTrailingSafetyConstraint = trailingSafetyConstraint

        NSLayoutConstraint.activate([
            leadingConstraint,
            centerYConstraint,
            widthConstraint,
            heightConstraint,
            trailingSafetyConstraint
        ])
    }

    private func updateSideButtonSize(_ size: CGFloat, spacing: CGFloat) {
        floatingButtonWidthConstraint?.constant = size
        floatingButtonHeightConstraint?.constant = size
        floatingButtonLeadingConstraint?.constant = spacing
        floatingButton?.isHidden = false
        floatingButton?.alpha = 1
    }

    // MARK: - Private Methods - Animations

    private func animateSideButtonIn(_ button: GlassFloatingButton) {
        animator.animate(
            .floatingButtonShow,
            config: .spring(duration: 0.45, damping: 0.7, velocity: 0.8)
        ) {
            button.transform = .identity
            button.alpha = 1
        }
    }

    private func animateSideButtonOut(_ button: GlassFloatingButton, completion: @escaping () -> Void) {
        animator.animate(
            .floatingButtonHide,
            config: .easeOut(duration: 0.35, damping: 0.85)
        ) {
            button.transform = self.sideButtonHiddenTransform
            button.alpha = 0
        } completion: { finished in
            if finished {
                completion()
            }
        }
    }

    private func removeSideButton(_ button: GlassFloatingButton) {
        button.removeFromSuperview()
        if floatingButton === button {
            floatingButton = nil
        }
    }

    private func replaceSideButton(
        _ existingButton: GlassFloatingButton,
        with config: GlassSideButtonConfig,
        animated: Bool
    ) {
        if animated {
            animateSideButtonOut(existingButton) { [weak self] in
                guard let self = self else { return }
                self.removeSideButton(existingButton)
                guard self.currentConfig != nil else { return }

                let newButton = self.createSideButton(config: config)
                self.animateSideButtonIn(newButton)
            }
        } else {
            removeSideButton(existingButton)
            let newButton = createSideButton(config: config)
            newButton.transform = .identity
            newButton.alpha = 1
        }
    }
}
