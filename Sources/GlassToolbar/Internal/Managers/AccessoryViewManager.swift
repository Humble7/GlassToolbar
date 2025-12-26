//
//  AccessoryViewManager.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - AccessoryViewManagerDelegate

@MainActor
protocol AccessoryViewManagerDelegate: AnyObject {
    var containerViewForAccessory: UIView { get }
    var toolbarViewForAccessory: UIView { get }
    var appearanceConfigurationForAccessory: ToolbarAppearanceConfiguration { get }
}

// MARK: - AccessoryViewManager

/// Manages primary and secondary accessory view lifecycle including display, animation and content
@MainActor
final class AccessoryViewManager {

    // MARK: - Properties

    weak var delegate: AccessoryViewManagerDelegate?
    private let animator: ToolbarAnimator

    let primaryContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    let secondaryContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private(set) weak var displayedPrimaryView: UIView?
    private(set) weak var displayedPrimaryProvider: GlassAccessoryProvider?
    private(set) weak var displayedSecondaryView: UIView?
    private(set) weak var displayedSecondaryProvider: GlassAccessoryProvider?
    private var pendingSecondaryShowTask: Task<Void, Never>?

    // MARK: - Constraints

    private var primaryBottomConstraint: NSLayoutConstraint?
    private var primaryWidthConstraint: NSLayoutConstraint?
    private var secondaryBottomConstraint: NSLayoutConstraint?

    // MARK: - Computed Properties

    private var appearanceConfiguration: ToolbarAppearanceConfiguration {
        delegate?.appearanceConfigurationForAccessory ?? .default
    }

    private var animationTranslationY: CGFloat {
        appearanceConfiguration.animationTranslationY
    }

    private var accessoryToToolbarSpacing: CGFloat {
        appearanceConfiguration.accessoryToToolbarSpacing
    }

    private var secondaryAccessorySpacing: CGFloat {
        appearanceConfiguration.secondaryAccessorySpacing
    }

    private var accessoryContentInsets: UIEdgeInsets {
        appearanceConfiguration.accessoryContentInsets
    }

    private var accessoryCornerRadius: CGFloat {
        appearanceConfiguration.accessoryCornerRadius
    }

    private var secondaryAccessoryShowDelay: TimeInterval {
        appearanceConfiguration.secondaryAccessoryShowDelay
    }

    // MARK: - Initialization

    init(animator: ToolbarAnimator) {
        self.animator = animator
    }

    deinit {
        MainActor.assumeIsolated {
            pendingSecondaryShowTask?.cancel()
            cleanup()
        }
    }

    // MARK: - Setup

    func setupContainers() {
        guard let delegate = delegate else { return }

        let containerView = delegate.containerViewForAccessory
        let toolbarView = delegate.toolbarViewForAccessory

        containerView.addSubview(primaryContainerView)
        containerView.addSubview(secondaryContainerView)

        setupPrimaryConstraints(containerView: containerView, toolbarView: toolbarView)
        setupSecondaryConstraints(toolbarView: toolbarView)
    }

    private func setupPrimaryConstraints(containerView: UIView, toolbarView: UIView) {
        let bottomConstraint = primaryContainerView.bottomAnchor.constraint(
            equalTo: toolbarView.topAnchor,
            constant: -accessoryToToolbarSpacing
        )
        let widthConstraint = primaryContainerView.widthAnchor.constraint(
            equalTo: toolbarView.widthAnchor
        )

        primaryBottomConstraint = bottomConstraint
        primaryWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            primaryContainerView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
            bottomConstraint,
            widthConstraint
        ])
    }

    private func setupSecondaryConstraints(toolbarView: UIView) {
        let bottomConstraint = secondaryContainerView.bottomAnchor.constraint(
            equalTo: primaryContainerView.topAnchor,
            constant: -secondaryAccessorySpacing
        )

        secondaryBottomConstraint = bottomConstraint

        // Secondary aligns with Primary (not Toolbar) for consistent layout
        NSLayoutConstraint.activate([
            secondaryContainerView.leadingAnchor.constraint(equalTo: primaryContainerView.leadingAnchor),
            secondaryContainerView.widthAnchor.constraint(equalTo: primaryContainerView.widthAnchor),
            bottomConstraint
        ])
    }

    // MARK: - Width Management

    func updateWidth(_ width: CGFloat) {
        let safeWidth = max(0, width)

        if let existingConstraint = primaryWidthConstraint {
            existingConstraint.isActive = false
        }
        let newConstraint = primaryContainerView.widthAnchor.constraint(equalToConstant: safeWidth)
        newConstraint.isActive = true
        primaryWidthConstraint = newConstraint

        // Secondary width automatically follows Primary via constraint
    }

    // MARK: - Primary Accessory Management

    func showPrimary(_ accessory: UIView, provider: GlassAccessoryProvider?, animated: Bool) {
        animator.interruptAnimation(.accessoryHide)

        if displayedPrimaryView === accessory && !primaryContainerView.isHidden && primaryContainerView.alpha == 1 {
            return
        }

        let targetAccessory = accessory
        let targetProvider = provider

        let needsTransition = displayedPrimaryView != nil && displayedPrimaryView !== accessory && !primaryContainerView.isHidden

        if needsTransition && animated {
            displayedPrimaryProvider?.willDisappear(animated: true)

            animator.animate(
                .accessoryHide,
                config: .quick(duration: 0.15)
            ) {
                self.primaryContainerView.transform = CGAffineTransform(translationX: 0, y: self.animationTranslationY)
                self.primaryContainerView.alpha = 0
            } completion: { [weak self] finished in
                guard let self = self, finished else { return }
                self.displayedPrimaryProvider?.didDisappear(animated: true)
                self.setupPrimaryContent(targetAccessory, provider: targetProvider)
                self.performPrimaryShowAnimation(provider: targetProvider)
            }
        } else {
            setupPrimaryContent(accessory, provider: targetProvider)

            if animated {
                if primaryContainerView.isHidden || primaryContainerView.alpha < 1 {
                    primaryContainerView.transform = CGAffineTransform(translationX: 0, y: animationTranslationY)
                    primaryContainerView.alpha = 0
                    primaryContainerView.isHidden = false
                }
                performPrimaryShowAnimation(provider: targetProvider)
            } else {
                primaryContainerView.isHidden = false
                primaryContainerView.transform = .identity
                primaryContainerView.alpha = 1
                targetProvider?.didAppear(animated: false)
            }
        }
    }

    func hidePrimary(animated: Bool, force: Bool = false) {
        animator.interruptAnimation(.accessoryShow)

        guard !primaryContainerView.isHidden else { return }

        displayedPrimaryProvider?.willDisappear(animated: animated)

        if animated {
            animator.animate(
                .accessoryHide,
                config: .easeOut(duration: 0.3, damping: 0.9)
            ) {
                self.primaryContainerView.transform = CGAffineTransform(translationX: 0, y: self.animationTranslationY)
                self.primaryContainerView.alpha = 0
            } completion: { [weak self] finished in
                guard let self = self, finished else { return }
                self.primaryContainerView.isHidden = true
                self.primaryContainerView.transform = .identity
                self.displayedPrimaryProvider?.didDisappear(animated: true)
                self.displayedPrimaryView = nil
                self.displayedPrimaryProvider = nil
            }
        } else {
            primaryContainerView.isHidden = true
            primaryContainerView.transform = .identity
            displayedPrimaryProvider?.didDisappear(animated: false)
            displayedPrimaryView = nil
            displayedPrimaryProvider = nil
        }
    }

    private func performPrimaryShowAnimation(provider: GlassAccessoryProvider? = nil) {
        primaryContainerView.isHidden = false

        provider?.willAppear(animated: true)

        animator.animate(
            .accessoryShow,
            config: .spring(duration: 0.45, damping: 0.75, velocity: 0.8)
        ) {
            self.primaryContainerView.transform = .identity
            self.primaryContainerView.alpha = 1
        } completion: { finished in
            guard finished else { return }
            provider?.didAppear(animated: true)
        }
    }

    private func setupPrimaryContent(_ accessory: UIView, provider: GlassAccessoryProvider? = nil) {
        primaryContainerView.subviews.forEach { $0.removeFromSuperview() }

        let glassBackground = GlassBackgroundView()
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.isUserInteractionEnabled = false
        glassBackground.cornerRadius = accessoryCornerRadius
        primaryContainerView.addSubview(glassBackground)

        accessory.translatesAutoresizingMaskIntoConstraints = false
        primaryContainerView.addSubview(accessory)

        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: primaryContainerView.topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: primaryContainerView.leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: primaryContainerView.trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: primaryContainerView.bottomAnchor),

            accessory.topAnchor.constraint(equalTo: primaryContainerView.topAnchor, constant: accessoryContentInsets.top),
            accessory.leadingAnchor.constraint(equalTo: primaryContainerView.leadingAnchor, constant: accessoryContentInsets.left),
            accessory.trailingAnchor.constraint(equalTo: primaryContainerView.trailingAnchor, constant: -accessoryContentInsets.right),
            accessory.bottomAnchor.constraint(equalTo: primaryContainerView.bottomAnchor, constant: -accessoryContentInsets.bottom)
        ])

        displayedPrimaryView = accessory
        displayedPrimaryProvider = provider

        delegate?.containerViewForAccessory.layoutIfNeeded()
    }

    // MARK: - Secondary Accessory Management

    func showSecondary(_ accessory: UIView, provider: GlassAccessoryProvider?, animated: Bool) {
        animator.interruptAnimation(.secondaryAccessoryHide)

        if displayedSecondaryView === accessory && !secondaryContainerView.isHidden && secondaryContainerView.alpha == 1 {
            return
        }

        setupSecondaryContent(accessory, provider: provider)

        if animated {
            secondaryContainerView.transform = CGAffineTransform(translationX: 0, y: animationTranslationY)
            secondaryContainerView.alpha = 0
            secondaryContainerView.isHidden = false

            provider?.willAppear(animated: true)

            animator.animate(
                .secondaryAccessoryShow,
                config: .spring(duration: 0.45, damping: 0.75, velocity: 0.8)
            ) {
                self.secondaryContainerView.transform = .identity
                self.secondaryContainerView.alpha = 1
            } completion: { finished in
                guard finished else { return }
                provider?.didAppear(animated: true)
            }
        } else {
            secondaryContainerView.isHidden = false
            secondaryContainerView.transform = .identity
            secondaryContainerView.alpha = 1
            provider?.willAppear(animated: false)
            provider?.didAppear(animated: false)
        }
    }

    func hideSecondary(animated: Bool) {
        cancelPendingSecondaryShow()
        animator.interruptAnimation(.secondaryAccessoryShow)

        guard !secondaryContainerView.isHidden else { return }

        displayedSecondaryProvider?.willDisappear(animated: animated)

        if animated {
            animator.animate(
                .secondaryAccessoryHide,
                config: .easeOut(duration: 0.3, damping: 0.9)
            ) {
                self.secondaryContainerView.transform = CGAffineTransform(translationX: 0, y: self.animationTranslationY)
                self.secondaryContainerView.alpha = 0
            } completion: { [weak self] finished in
                guard let self = self, finished else { return }
                self.secondaryContainerView.isHidden = true
                self.secondaryContainerView.transform = .identity
                self.displayedSecondaryProvider?.didDisappear(animated: true)
                self.displayedSecondaryView = nil
                self.displayedSecondaryProvider = nil
            }
        } else {
            secondaryContainerView.isHidden = true
            secondaryContainerView.transform = .identity
            displayedSecondaryProvider?.didDisappear(animated: false)
            displayedSecondaryView = nil
            displayedSecondaryProvider = nil
        }
    }

    func dismissSecondary(animated: Bool) {
        cancelPendingSecondaryShow()
        animator.interruptAnimation(.secondaryAccessoryShow)

        guard !secondaryContainerView.isHidden else { return }

        if animated {
            animator.animate(
                .secondaryAccessoryHide,
                config: .easeOut(duration: 0.2)
            ) {
                self.secondaryContainerView.transform = CGAffineTransform(translationX: 0, y: self.animationTranslationY)
                self.secondaryContainerView.alpha = 0
            } completion: { [weak self] finished in
                guard let self = self, finished else { return }
                self.secondaryContainerView.isHidden = true
                self.secondaryContainerView.transform = .identity
                self.displayedSecondaryView = nil
            }
        } else {
            secondaryContainerView.isHidden = true
            secondaryContainerView.transform = .identity
            displayedSecondaryView = nil
        }
    }

    private func setupSecondaryContent(_ accessory: UIView, provider: GlassAccessoryProvider? = nil) {
        secondaryContainerView.subviews.forEach { $0.removeFromSuperview() }

        let glassBackground = GlassBackgroundView()
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.isUserInteractionEnabled = false
        glassBackground.cornerRadius = accessoryCornerRadius
        secondaryContainerView.addSubview(glassBackground)

        accessory.translatesAutoresizingMaskIntoConstraints = false
        secondaryContainerView.addSubview(accessory)

        NSLayoutConstraint.activate([
            glassBackground.topAnchor.constraint(equalTo: secondaryContainerView.topAnchor),
            glassBackground.leadingAnchor.constraint(equalTo: secondaryContainerView.leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: secondaryContainerView.trailingAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: secondaryContainerView.bottomAnchor),

            accessory.topAnchor.constraint(equalTo: secondaryContainerView.topAnchor, constant: accessoryContentInsets.top),
            accessory.leadingAnchor.constraint(equalTo: secondaryContainerView.leadingAnchor, constant: accessoryContentInsets.left),
            accessory.trailingAnchor.constraint(equalTo: secondaryContainerView.trailingAnchor, constant: -accessoryContentInsets.right),
            accessory.bottomAnchor.constraint(equalTo: secondaryContainerView.bottomAnchor, constant: -accessoryContentInsets.bottom)
        ])

        displayedSecondaryView = accessory
        displayedSecondaryProvider = provider

        delegate?.containerViewForAccessory.layoutIfNeeded()
    }

    // MARK: - Delayed Secondary Show

    func showSecondaryWithDelay(_ accessory: UIView, provider: GlassAccessoryProvider?, delay: TimeInterval? = nil) {
        cancelPendingSecondaryShow()

        let actualDelay = delay ?? secondaryAccessoryShowDelay

        pendingSecondaryShowTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(actualDelay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let self = self else { return }
                    self.showSecondary(accessory, provider: provider, animated: true)
                }
            } catch {
                // Task cancelled
            }
        }
    }

    func cancelPendingSecondaryShow() {
        pendingSecondaryShowTask?.cancel()
        pendingSecondaryShowTask = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        cancelPendingSecondaryShow()

        displayedPrimaryProvider?.cleanup()
        displayedPrimaryProvider = nil
        displayedPrimaryView = nil

        displayedSecondaryProvider?.cleanup()
        displayedSecondaryProvider = nil
        displayedSecondaryView = nil
    }

    func cancelAnimations() {
        primaryContainerView.layer.removeAllAnimations()
        secondaryContainerView.layer.removeAllAnimations()
    }

    // MARK: - State Queries

    var isPrimaryVisible: Bool {
        !primaryContainerView.isHidden && primaryContainerView.alpha > 0
    }

    var isSecondaryVisible: Bool {
        !secondaryContainerView.isHidden && secondaryContainerView.alpha > 0
    }
}
