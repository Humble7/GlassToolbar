//
//  GlassToolbarController.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - PassthroughView

/// A view that passes through touches to views behind it
/// Only responds to touches that hit its subviews
private class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // Return nil if the hit view is self (not a subview)
        // This allows touches to pass through to views behind
        return hitView === self ? nil : hitView
    }
}

// MARK: - GlassToolbarController

/// Custom Toolbar Controller implementing Liquid Glass style
/// Supports: floating toolbar, side floating button, bottom accessory view
public class GlassToolbarController: UIViewController {

    // MARK: - Public Properties

    /// Currently selected toolbar item index
    public var selectedIndex: Int {
        get { itemsManager.selectedIndex }
        set { itemsManager.setSelectedIndex(newValue) }
    }

    /// Callback when selected item changes
    public var onItemSelected: (@MainActor (Int) -> Void)? {
        get { itemsManager.onSelectedIndexChanged }
        set { itemsManager.onSelectedIndexChanged = newValue }
    }

    /// All toolbar items
    public var items: [GlassToolbarItem] {
        return itemsManager.items
    }

    /// Global Accessory Provider (used when item has no associated accessoryProvider)
    public var globalAccessoryProvider: GlassAccessoryProvider? {
        didSet {
            layoutCoordinator.invalidateCache()
            updateAccessoryViewForCurrentItem()
        }
    }

    /// Global side floating button config (used when item has no associated sideButton)
    public var globalSideButton: GlassSideButtonConfig? {
        didSet {
            layoutCoordinator.invalidateCache()
            updateSideButtonForCurrentItem()
        }
    }

    /// Ultra minimal mode: shows only the most important item and side button, hides accessory view
    public var isUltraMinimalMode: Bool {
        get { ultraMinimalModeHandler.isEnabled }
        set { ultraMinimalModeHandler.setEnabled(newValue, animated: true) }
    }

    /// Toolbar position
    public var toolbarPosition: ToolbarPosition = .bottom {
        didSet { updateToolbarPosition() }
    }

    /// Current primary Accessory Provider
    private var currentAccessoryProvider: GlassAccessoryProvider? {
        return itemsManager.currentAccessoryProvider
    }

    /// Current displayed accessory view (from Provider)
    private var currentAccessoryView: UIView? {
        return itemsManager.currentAccessoryView
    }

    /// Current secondary Accessory Provider
    var currentSecondaryAccessoryProvider: GlassAccessoryProvider? {
        return itemsManager.currentSecondaryAccessoryProvider
    }

    /// Current displayed secondary accessory view
    var currentSecondaryAccessoryView: UIView? {
        return itemsManager.currentSecondaryAccessoryView
    }

    // MARK: - Animation

    private let animator = ToolbarAnimator()

    // MARK: - UI Components

    private let toolbarView = GlassToolbarView()

    // MARK: - Accessory View Manager

    private lazy var accessoryViewManager: AccessoryViewManager = {
        let manager = AccessoryViewManager(animator: animator)
        manager.delegate = self
        return manager
    }()

    // MARK: - Side Button Manager

    private lazy var sideButtonManager: SideButtonManager = {
        let manager = SideButtonManager(animator: animator)
        manager.delegate = self
        return manager
    }()

    // MARK: - State Coordinator

    private lazy var stateCoordinator: ToolbarStateCoordinator = {
        let coordinator = ToolbarStateCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    // MARK: - Ultra Minimal Mode Handler

    private lazy var ultraMinimalModeHandler: UltraMinimalModeHandler = {
        let handler = UltraMinimalModeHandler()
        handler.delegate = self
        return handler
    }()

    // MARK: - Overflow Menu Handler

    private lazy var overflowMenuHandler: OverflowMenuHandler = {
        let handler = OverflowMenuHandler()
        handler.delegate = self
        return handler
    }()

    // MARK: - Items Manager

    private lazy var itemsManager: ToolbarItemsManager = {
        let manager = ToolbarItemsManager()
        manager.delegate = self
        return manager
    }()

    // MARK: - Constraints Manager

    private lazy var constraintsManager: ToolbarConstraintsManager = {
        let manager = ToolbarConstraintsManager()
        manager.delegate = self
        return manager
    }()

    // MARK: - Layout System

    /// Layout coordinator (public read-only for cache statistics access)
    public private(set) lazy var layoutCoordinator = ToolbarLayoutCoordinator()

    /// Layout configuration
    public var layoutConfiguration: ToolbarLayoutConfiguration {
        get { layoutCoordinator.configuration }
        set {
            layoutCoordinator.configuration = newValue
            setNeedsLayoutUpdate()
        }
    }

    /// Current layout result
    private var currentLayoutResult: ToolbarLayoutResult?

    /// Current space tier
    public var currentSpaceTier: SpaceTier {
        currentLayoutResult?.spaceTier ?? .regular
    }

    /// Current compression level
    public var currentCompressionLevel: CompressionLevel {
        currentLayoutResult?.compressionLevel ?? .full
    }

    /// Items in overflow menu
    public var overflowItems: [GlassToolbarItem] {
        guard let result = currentLayoutResult else { return [] }
        return result.overflowItemIndices.map { items[$0] }
    }

    /// Last layout width
    private var lastLayoutWidth: CGFloat = 0

    // MARK: - Appearance Configuration

    /// Appearance configuration (via dependency injection)
    public var appearanceConfiguration: ToolbarAppearanceConfiguration {
        didSet {
            if isViewLoaded {
                updateAppearanceFromConfiguration()
            }
        }
    }

    private var toolbarHeight: CGFloat { appearanceConfiguration.toolbarHeight }
    private var toolbarPadding: CGFloat { appearanceConfiguration.toolbarPadding }
    private var floatingButtonSize: CGFloat { appearanceConfiguration.floatingButtonSize }
    private var toolbarToSideButtonSpacing: CGFloat { appearanceConfiguration.toolbarToSideButtonSpacing }
    private var animationDuration: TimeInterval { appearanceConfiguration.animationDuration }
    private var animationTranslationY: CGFloat { appearanceConfiguration.animationTranslationY }
    private var accessoryToToolbarSpacing: CGFloat { appearanceConfiguration.accessoryToToolbarSpacing }
    private var secondaryAccessorySpacing: CGFloat { appearanceConfiguration.secondaryAccessorySpacing }
    private var accessoryContentInsets: UIEdgeInsets { appearanceConfiguration.accessoryContentInsets }
    private var ultraMinimalItemWidth: CGFloat { appearanceConfiguration.ultraMinimalItemWidth }
    private var ultraMinimalToolbarPadding: CGFloat { appearanceConfiguration.ultraMinimalToolbarPadding }
    private var secondaryAccessoryShowDelay: TimeInterval { appearanceConfiguration.secondaryAccessoryShowDelay }

    // MARK: - Lifecycle

    /// Initialize with custom appearance configuration
    public init(configuration: ToolbarAppearanceConfiguration = .default) {
        self.appearanceConfiguration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    /// Storyboard/XIB initialization (uses default config)
    public required init?(coder: NSCoder) {
        self.appearanceConfiguration = .default
        super.init(coder: coder)
    }

    deinit {
        MainActor.assumeIsolated {
            animator.cancelAllAnimations()
            cleanupAllReferences()
        }
    }

    public override func loadView() {
        // Use PassthroughView to allow touches to pass through to views below
        view = PassthroughView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        registerTraitChanges()
        toolbarView.appearanceConfiguration = appearanceConfiguration
    }

    private func registerTraitChanges() {
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: GlassToolbarController, _) in
            self.setNeedsLayoutUpdate()
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolbarView.layer.cornerRadius = appearanceConfiguration.effectiveToolbarCornerRadius
        updateLayoutIfNeeded()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.performLayoutUpdate(for: size.width, animated: true)
        }
    }

    // MARK: - Layout Update

    private func setNeedsLayoutUpdate() {
        lastLayoutWidth = 0
        view.setNeedsLayout()
    }

    private func updateLayoutIfNeeded() {
        let containerWidth = view.bounds.width
        guard layoutCoordinator.shouldRecalculateLayout(newWidth: containerWidth) else {
            return
        }
        performLayoutUpdate(for: containerWidth, animated: false)
    }

    private func performLayoutUpdate(for containerWidth: CGFloat, animated: Bool) {
        guard containerWidth > 0 else { return }

        if ultraMinimalModeHandler.isEnabled {
            ultraMinimalModeHandler.refreshLayoutIfNeeded(animated: animated)
            return
        }

        let itemInfos = items.enumerated().map { index, item in
            item.toLayoutInfo(index: index)
        }

        let sideButtonInfo = currentSideButtonConfig?.toLayoutInfo()

        let result = layoutCoordinator.calculateLayout(
            containerWidth: containerWidth,
            items: itemInfos,
            sideButton: sideButtonInfo,
            hasAccessory: currentAccessoryView != nil
        )

        applyLayoutResult(result, animated: animated)

        currentLayoutResult = result
        lastLayoutWidth = containerWidth
    }

    private func applyLayoutResult(_ result: ToolbarLayoutResult, animated: Bool) {
        performLayoutApplication(result.toApplicationParams(), animated: animated)
    }

    private func performLayoutApplication(_ params: ToolbarLayoutApplication, animated: Bool) {
        let changes = { [self] in
            toolbarView.applyLayout(
                itemDisplayModes: params.itemDisplayModes,
                visibleIndices: params.visibleIndices,
                spacing: params.itemSpacing,
                showOverflowButton: params.showOverflowButton,
                compressionLevel: params.compressionLevel
            )

            updateToolbarWidth(params.toolbarWidth, sideButtonMode: params.sideButtonMode)

            if let accessoryWidth = params.accessoryWidth {
                updateAccessoryWidth(accessoryWidth)
            }

            view.layoutIfNeeded()

            applySideButtonLayout(params.sideButtonMode)

            toolbarView.forceLayoutUpdate()
        }

        if animated {
            animator.animate(
                .toolbarLayout,
                config: .spring(
                    duration: animationDuration,
                    damping: appearanceConfiguration.springDamping,
                    velocity: appearanceConfiguration.springVelocity
                ),
                animations: changes
            )
        } else {
            changes()
        }
    }

    private func applySideButtonLayout(_ mode: SideButtonDisplayMode) {
        sideButtonManager.applyLayoutMode(mode)
    }

    private func updateToolbarWidth(_ calculatedWidth: CGFloat, sideButtonMode: SideButtonDisplayMode) {
        constraintsManager.updateWidth(calculatedWidth, sideButtonMode: sideButtonMode)
    }

    private func updateAccessoryWidth(_ width: CGFloat) {
        accessoryViewManager.updateWidth(width)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.delegate = self
        view.addSubview(toolbarView)
        accessoryViewManager.setupContainers()
    }

    private func setupConstraints() {
        constraintsManager.setupConstraints()
    }

    private func updateAccessoryViewForCurrentItem() {
        loadViewIfNeeded()

        if ultraMinimalModeHandler.isEnabled {
            accessoryViewManager.hidePrimary(animated: false)
            accessoryViewManager.hideSecondary(animated: false)
            return
        }

        let targetAccessory = currentAccessoryView

        accessoryViewManager.dismissSecondary(animated: false)
        accessoryViewManager.cancelAnimations()

        if let accessory = targetAccessory {
            if stateCoordinator.isPrimaryExpanded {
                accessoryViewManager.showPrimary(accessory, provider: currentAccessoryProvider, animated: true)

                if stateCoordinator.isSecondaryExpanded, let secondary = currentSecondaryAccessoryView {
                    accessoryViewManager.showSecondaryWithDelay(secondary, provider: currentSecondaryAccessoryProvider)
                }
            } else {
                accessoryViewManager.hidePrimary(animated: false)
            }
        } else {
            accessoryViewManager.hidePrimary(animated: true)
        }
    }

    // MARK: - Ultra Minimal Mode

    public func setUltraMinimalMode(_ enabled: Bool, animated: Bool) {
        ultraMinimalModeHandler.setEnabled(enabled, animated: animated)
    }

    public func toggleUltraMinimalMode(animated: Bool = true) {
        ultraMinimalModeHandler.toggle(animated: animated)
    }

    // MARK: - Side Button Management

    private func updateSideButtonForCurrentItem() {
        loadViewIfNeeded()
        sideButtonManager.updateConfiguration(currentSideButtonConfig, animated: true)
    }

    private func updateToolbarPosition() {
        // Reserved for different toolbar positions (top, left, etc.)
    }

    // MARK: - Public Methods

    public func setItems(_ toolbarItems: [GlassToolbarItem]) {
        loadViewIfNeeded()
        layoutCoordinator.invalidateCache()
        itemsManager.setItems(toolbarItems)
    }

    /// Update a single toolbar item at the specified index
    /// - Parameters:
    ///   - index: The index of the item to update
    ///   - transform: A closure that takes the current item and returns the updated item
    public func updateItem(at index: Int, transform: (GlassToolbarItem) -> GlassToolbarItem) {
        guard index >= 0 && index < items.count else { return }
        let updatedItem = transform(items[index])
        layoutCoordinator.invalidateCache()
        itemsManager.updateItem(at: index, with: updatedItem)
    }

    /// Update side button appearance dynamically
    /// - Parameters:
    ///   - icon: New icon (nil to keep current)
    ///   - backgroundColor: New background color (nil to keep current, only works for non-glass buttons)
    ///   - tintColor: New tint color (nil to keep current)
    ///   - animated: Whether to animate the change
    public func updateSideButtonAppearance(
        icon: UIImage? = nil,
        backgroundColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        animated: Bool = true
    ) {
        sideButtonManager.updateAppearance(
            icon: icon,
            backgroundColor: backgroundColor,
            tintColor: tintColor,
            animated: animated
        )
    }

    func handleOverflowItemTap(at index: Int) {
        itemsManager.handleOverflowItemTap(at: index)
    }

    // MARK: - Private Methods

    private func calculateToolbarWidth() -> CGFloat {
        let itemWidth = appearanceConfiguration.itemFullSize.width
        let padding = appearanceConfiguration.toolbarInternalPadding
        let baseWidth = CGFloat(items.count) * itemWidth + padding
        let maxWidth = UIScreen.main.bounds.width - (toolbarPadding * 2)
        return min(baseWidth, maxWidth)
    }

    // MARK: - Configuration Updates

    private func updateAppearanceFromConfiguration() {
        toolbarView.layer.cornerRadius = appearanceConfiguration.effectiveToolbarCornerRadius
        toolbarView.appearanceConfiguration = appearanceConfiguration
        constraintsManager.updateBottomOffset(-toolbarPadding)
        layoutCoordinator.invalidateCache()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Memory Management

    private func cleanupAllReferences() {
        sideButtonManager.cleanup()
        accessoryViewManager.cleanup()
        stateCoordinator.resetAllStates()
        toolbarView.onOverflowTap = nil
        itemsManager.cleanup()
        globalSideButton?.cleanup()
        globalSideButton = nil
        globalAccessoryProvider?.cleanup()
        globalAccessoryProvider = nil
    }
}

// MARK: - ToolbarStateCoordinatorDelegate

extension GlassToolbarController: ToolbarStateCoordinatorDelegate {

    var currentSelectedIndex: Int {
        return selectedIndex
    }

    var currentPrimaryAccessoryView: UIView? {
        return currentAccessoryView
    }

    var currentPrimaryAccessoryProvider: GlassAccessoryProvider? {
        return currentAccessoryProvider
    }

    func stateCoordinator(_ coordinator: ToolbarStateCoordinator, performTransition transition: AccessoryStateTransition, animated: Bool) {
        switch transition {
        case .showPrimary:
            if let accessory = currentAccessoryView {
                accessoryViewManager.showPrimary(accessory, provider: currentAccessoryProvider, animated: animated)
            }

        case .showSecondary:
            if let secondary = currentSecondaryAccessoryView {
                accessoryViewManager.showSecondary(secondary, provider: currentSecondaryAccessoryProvider, animated: animated)
                stateCoordinator.isSecondaryExpanded = true
            }

        case .hideSecondary:
            accessoryViewManager.hideSecondary(animated: animated)
            stateCoordinator.isSecondaryExpanded = false

        case .hidePrimary:
            accessoryViewManager.hidePrimary(animated: animated)

        case .hideAll:
            accessoryViewManager.hideSecondary(animated: animated)
            stateCoordinator.isSecondaryExpanded = false
            accessoryViewManager.hidePrimary(animated: animated)

        case .none:
            break
        }
    }
}

// MARK: - AccessoryViewManagerDelegate

extension GlassToolbarController: AccessoryViewManagerDelegate {

    var containerViewForAccessory: UIView {
        return view
    }

    var toolbarViewForAccessory: UIView {
        return toolbarView
    }

    var appearanceConfigurationForAccessory: ToolbarAppearanceConfiguration {
        return appearanceConfiguration
    }
}

// MARK: - SideButtonManagerDelegate

extension GlassToolbarController: SideButtonManagerDelegate {

    var toolbarViewForSideButton: UIView {
        return toolbarView
    }

    var containerViewForSideButton: UIView {
        return view
    }

    var appearanceConfigurationForSideButton: ToolbarAppearanceConfiguration {
        return appearanceConfiguration
    }

    func sideButtonManagerRequestsLayoutUpdate(animated: Bool) {
        performLayoutUpdate(for: view.bounds.width, animated: animated)
    }
}

// MARK: - GlassToolbarViewDelegate

extension GlassToolbarController: GlassToolbarViewDelegate {
    func toolbarView(_ toolbarView: GlassToolbarView, didSelectItemAt index: Int) {
        guard index < items.count else { return }
        let item = items[index]

        item.action?()

        if !item.isSelectable {
            toolbarView.performTapFeedback(at: index)
        } else if index == selectedIndex {
            stateCoordinator.handleSameItemTap(animated: true)
        } else {
            accessoryViewManager.dismissSecondary(animated: true)
            selectedIndex = index
        }
    }
}

// MARK: - UltraMinimalModeHandlerDelegate

extension GlassToolbarController: UltraMinimalModeHandlerDelegate {

    var currentSideButtonConfig: GlassSideButtonConfig? {
        return itemsManager.currentSideButtonConfig
    }

    var containerWidth: CGFloat {
        return view.bounds.width
    }

    func hideAllAccessoryViews(animated: Bool) {
        accessoryViewManager.hidePrimary(animated: animated)
        accessoryViewManager.hideSecondary(animated: animated)
    }

    func restoreAccessoryViewsIfNeeded() {
        if stateCoordinator.isPrimaryExpanded {
            updateAccessoryViewForCurrentItem()
        }
    }

    func restoreNormalLayout(animated: Bool) {
        performLayoutUpdate(for: view.bounds.width, animated: animated)
    }

    func applyLayoutChanges(_ params: ToolbarLayoutApplication, animated: Bool) {
        performLayoutApplication(params, animated: animated)
    }
}

// MARK: - OverflowMenuHandlerDelegate

extension GlassToolbarController: OverflowMenuHandlerDelegate {

    func getLayoutResultForOverflow() -> ToolbarLayoutResult? {
        return currentLayoutResult
    }

    func getSideButtonConfigForOverflow() -> GlassSideButtonConfig? {
        return currentSideButtonConfig
    }

    func getToolbarViewForOverflow() -> GlassToolbarView {
        return toolbarView
    }

    func presentOverflowMenu(_ alertController: UIAlertController) {
        present(alertController, animated: true)
    }
}

// MARK: - ToolbarItemsManagerDelegate

extension GlassToolbarController: ToolbarItemsManagerDelegate {

    func itemsManager(_ manager: ToolbarItemsManager, didChangeSelectedIndex index: Int) {
        toolbarView.selectItem(at: index)
        updateSideButtonForCurrentItem()
        updateAccessoryViewForCurrentItem()
    }

    func itemsManagerDidSetItems(_ manager: ToolbarItemsManager) {
        toolbarView.configure(with: manager.items)

        toolbarView.onOverflowTap = { [weak self] in
            self?.overflowMenuHandler.showMenu()
        }

        sideButtonManager.initializeWithConfiguration(manager.currentSideButtonConfig)
        updateAccessoryViewForCurrentItem()
        setNeedsLayoutUpdate()
        view.layoutIfNeeded()
    }

    func itemsManager(_ manager: ToolbarItemsManager, didUpdateItemAt index: Int) {
        guard let item = manager.item(at: index) else { return }
        toolbarView.updateItem(at: index, with: item)
    }
}

// MARK: - ToolbarConstraintsManagerDelegate

extension GlassToolbarController: ToolbarConstraintsManagerDelegate {

    func getContainerView() -> UIView {
        return view
    }

    func getToolbarView() -> GlassToolbarView {
        return toolbarView
    }

    func getToolbarPadding() -> CGFloat {
        return toolbarPadding
    }

    func getToolbarHeight() -> CGFloat {
        return toolbarHeight
    }

    func getToolbarInternalPadding() -> CGFloat {
        return appearanceConfiguration.toolbarInternalPadding
    }

    func calculateInitialToolbarWidth() -> CGFloat {
        return calculateToolbarWidth()
    }
}
