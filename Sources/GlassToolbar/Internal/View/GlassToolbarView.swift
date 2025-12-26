//
//  GlassToolbarView.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - GlassToolbarViewDelegate

@MainActor
protocol GlassToolbarViewDelegate: AnyObject {
    func toolbarView(_ toolbarView: GlassToolbarView, didSelectItemAt index: Int)
}

// MARK: - GlassToolbarView

/// Liquid glass style toolbar view
class GlassToolbarView: UIView {

    // MARK: - Configuration

    var appearanceConfiguration: ToolbarAppearanceConfiguration = .default {
        didSet { applyConfiguration() }
    }

    // MARK: - Properties

    weak var delegate: GlassToolbarViewDelegate?

    private var items: [GlassToolbarItem] = []
    private var itemViews: [GlassToolbarItemView] = []
    private var selectedIndex: Int = 0

    // MARK: - UI Components

    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let glossLayer = CAGradientLayer()
    private let borderGradientLayer = CAGradientLayer()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = true
        return stack
    }()

    private let selectionIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private var selectionIndicatorCenterX: NSLayoutConstraint?
    private var selectionIndicatorWidth: NSLayoutConstraint?
    private var selectionIndicatorHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        MainActor.assumeIsolated {
            onOverflowTap = nil
        }
    }

    // MARK: - Setup

    private func setupUI() {
        clipsToBounds = false
        isUserInteractionEnabled = true
        layer.masksToBounds = false

        addSubview(blurEffectView)
        blurEffectView.clipsToBounds = true
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.contentView.isUserInteractionEnabled = true

        setupGlossLayer()
        blurEffectView.contentView.layer.addSublayer(glossLayer)
        blurEffectView.contentView.addSubview(selectionIndicator)
        blurEffectView.contentView.addSubview(contentStackView)

        setupConstraints()
        setupBorderGradient()
        applyConfiguration()
    }

    private func setupGlossLayer() {
        glossLayer.locations = [0.0, 0.35, 1.0]
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0)
        glossLayer.endPoint = CGPoint(x: 0.5, y: 1)

        borderGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        borderGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }

    private var contentStackLeadingConstraint: NSLayoutConstraint?
    private var contentStackTrailingConstraint: NSLayoutConstraint?

    private func setupConstraints() {
        let internalPadding = appearanceConfiguration.toolbarInternalPadding

        let stackLeading = contentStackView.leadingAnchor.constraint(
            equalTo: blurEffectView.contentView.leadingAnchor,
            constant: internalPadding
        )
        let stackTrailing = contentStackView.trailingAnchor.constraint(
            equalTo: blurEffectView.contentView.trailingAnchor,
            constant: -internalPadding
        )
        // Lower priority to avoid constraint conflicts during layout transitions
        stackLeading.priority = .defaultHigh
        stackTrailing.priority = .defaultHigh
        contentStackLeadingConstraint = stackLeading
        contentStackTrailingConstraint = stackTrailing

        let heightConstraint = selectionIndicator.heightAnchor.constraint(
            equalToConstant: appearanceConfiguration.selectionIndicatorHeight
        )
        selectionIndicatorHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
            stackLeading,
            stackTrailing,
            contentStackView.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor),

            heightConstraint
        ])

        let centerXConstraint = selectionIndicator.centerXAnchor.constraint(equalTo: leadingAnchor)
        let widthConstraint = selectionIndicator.widthAnchor.constraint(equalToConstant: 50)

        selectionIndicatorCenterX = centerXConstraint
        selectionIndicatorWidth = widthConstraint

        selectionIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        centerXConstraint.isActive = true
        widthConstraint.isActive = true
    }

    private func applyConfiguration() {
        let config = appearanceConfiguration
        let cornerRadius = config.effectiveToolbarCornerRadius

        // Corner radius
        layer.cornerRadius = cornerRadius
        blurEffectView.layer.cornerRadius = cornerRadius
        selectionIndicator.layer.cornerRadius = config.effectiveSelectionIndicatorCornerRadius

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = config.toolbarShadowOffset
        layer.shadowRadius = config.toolbarShadowRadius
        layer.shadowOpacity = config.toolbarShadowOpacity

        // Glass effect colors
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(config.glossTopAlpha).cgColor,
            UIColor.white.withAlphaComponent(config.glossMiddleAlpha).cgColor,
            UIColor.clear.cgColor
        ]
        borderGradientLayer.colors = [
            UIColor.white.withAlphaComponent(config.borderTopAlpha).cgColor,
            UIColor.white.withAlphaComponent(config.borderBottomAlpha).cgColor
        ]
        selectionIndicator.backgroundColor = UIColor.white.withAlphaComponent(config.selectionIndicatorAlpha)

        // Constraints
        contentStackLeadingConstraint?.constant = config.toolbarInternalPadding
        contentStackTrailingConstraint?.constant = -config.toolbarInternalPadding
        selectionIndicatorHeightConstraint?.constant = config.selectionIndicatorHeight
    }

    private func setupBorderGradient() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 1.0
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        borderGradientLayer.mask = shapeLayer
        layer.addSublayer(borderGradientLayer)
    }

    // MARK: - Layout

    private var needsSelectionIndicatorUpdate: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()

        glossLayer.frame = blurEffectView.bounds
        borderGradientLayer.frame = bounds

        if let shapeLayer = borderGradientLayer.mask as? CAShapeLayer {
            let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: layer.cornerRadius)
            shapeLayer.path = path.cgPath
        }

        if needsSelectionIndicatorUpdate {
            needsSelectionIndicatorUpdate = false
            updateSelectionIndicatorPosition(animated: false)
        }
    }

    func setNeedsSelectionIndicatorUpdate() {
        needsSelectionIndicatorUpdate = true
        setNeedsLayout()
    }

    func forceLayoutUpdate() {
        guard bounds.width > 0 else { return }
        contentStackView.setNeedsLayout()
        contentStackView.layoutIfNeeded()
        updateSelectionIndicatorPosition(animated: false)
    }

    // MARK: - Configuration

    func configure(with items: [GlassToolbarItem]) {
        self.items = items

        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        for (index, item) in items.enumerated() {
            let itemView = GlassToolbarItemView()
            itemView.appearanceConfiguration = appearanceConfiguration
            itemView.configure(with: item)
            itemView.tag = index
            itemView.isSelected = index == selectedIndex

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleItemTap(_:)))
            tapGesture.cancelsTouchesInView = false
            itemView.addGestureRecognizer(tapGesture)

            contentStackView.addArrangedSubview(itemView)
            itemViews.append(itemView)
        }

        setNeedsSelectionIndicatorUpdate()
        layoutIfNeeded()
    }

    func selectItem(at index: Int) {
        guard index < itemViews.count else { return }

        selectedIndex = index

        for (i, itemView) in itemViews.enumerated() {
            itemView.isSelected = i == index
        }

        updateSelectionIndicatorPosition(animated: true)
    }

    /// Update a single item view without recreating all views
    func updateItem(at index: Int, with item: GlassToolbarItem) {
        guard index >= 0 && index < itemViews.count else { return }
        items[index] = item
        itemViews[index].configure(with: item)
    }

    func performTapFeedback(at index: Int) {
        animateItemPress(at: index)
    }

    // MARK: - Layout Application

    private var overflowButton: GlassToolbarItemView?
    var onOverflowTap: (@MainActor () -> Void)?
    private var currentVisibleIndices: Set<Int> = []

    var overflowButtonFrame: CGRect? {
        return overflowButton?.frame
    }

    private var currentCompressionLevel: CompressionLevel = .full

    func applyLayout(
        itemDisplayModes: [Int: ItemDisplayMode],
        visibleIndices: [Int],
        spacing: CGFloat,
        showOverflowButton: Bool,
        compressionLevel: CompressionLevel = .full
    ) {
        for itemView in itemViews {
            itemView.removeFromSuperview()
        }
        overflowButton?.removeFromSuperview()

        for (index, itemView) in itemViews.enumerated() {
            if let mode = itemDisplayModes[index] {
                switch mode {
                case .full:
                    itemView.setDisplayMode(.full)
                    itemView.alpha = 1
                    contentStackView.addArrangedSubview(itemView)
                case .compactTitle:
                    itemView.setDisplayMode(.compactTitle)
                    itemView.alpha = 1
                    contentStackView.addArrangedSubview(itemView)
                case .iconOnly:
                    itemView.setDisplayMode(.iconOnly)
                    itemView.alpha = 1
                    contentStackView.addArrangedSubview(itemView)
                case .hidden:
                    itemView.setDisplayMode(.hidden)
                    itemView.alpha = 0
                }
            }
        }

        if showOverflowButton {
            if overflowButton == nil {
                createOverflowButton()
            }
            if let button = overflowButton {
                contentStackView.addArrangedSubview(button)
                button.alpha = 1
            }
        }

        contentStackView.spacing = spacing
        contentStackView.distribution = .fillEqually

        // Update indicator height based on compression level
        updateIndicatorHeight(for: compressionLevel)

        currentVisibleIndices = Set(visibleIndices)
        setNeedsLayout()
    }

    private func updateIndicatorHeight(for compressionLevel: CompressionLevel) {
        guard compressionLevel != currentCompressionLevel else { return }
        currentCompressionLevel = compressionLevel

        let config = appearanceConfiguration
        let targetHeight: CGFloat
        let targetCornerRadius: CGFloat

        switch compressionLevel {
        case .full, .comfortable:
            targetHeight = config.selectionIndicatorHeight
            targetCornerRadius = config.effectiveSelectionIndicatorCornerRadius
        case .compact, .iconOnly, .overflow:
            targetHeight = config.selectionIndicatorHeightCompact
            // Adjust corner radius proportionally
            let ratio = config.selectionIndicatorHeightCompact / config.selectionIndicatorHeight
            targetCornerRadius = config.effectiveSelectionIndicatorCornerRadius * ratio
        }

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.selectionIndicatorHeightConstraint?.constant = targetHeight
            self.selectionIndicator.layer.cornerRadius = targetCornerRadius
            self.layoutIfNeeded()
        }
    }

    private func createOverflowButton() {
        let button = GlassToolbarItemView()
        let overflowItem = GlassToolbarItem(
            title: "",
            icon: UIImage(systemName: "ellipsis"),
            isSelectable: false,
            priority: .essential,
            canHideTitle: true
        )
        button.configure(with: overflowItem)
        button.tag = -1
        button.setDisplayMode(.iconOnly)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOverflowTap(_:)))
        button.addGestureRecognizer(tapGesture)

        overflowButton = button
    }

    @objc private func handleOverflowTap(_ gesture: UITapGestureRecognizer) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        let scale = appearanceConfiguration.tapScaleFactor
        if let button = overflowButton {
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                    button.transform = .identity
                }
            }
        }

        onOverflowTap?()
    }

    // MARK: - Actions

    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let index = view.tag

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        animateItemPress(at: index)

        delegate?.toolbarView(self, didSelectItemAt: index)
    }

    private func animateItemPress(at index: Int) {
        guard index < itemViews.count else { return }
        let itemView = itemViews[index]
        let scale = appearanceConfiguration.tapScaleFactor

        UIView.animate(withDuration: 0.1, animations: {
            itemView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                itemView.transform = .identity
            }
        }
    }

    private func updateSelectionIndicatorPosition(animated: Bool) {
        guard selectedIndex < itemViews.count else { return }
        let selectedView = itemViews[selectedIndex]

        // Check if selected item is in overflow (not visible)
        let isSelectedItemVisible = currentVisibleIndices.contains(selectedIndex)
        if !isSelectedItemVisible {
            let hideUpdate = {
                self.selectionIndicator.alpha = 0
            }
            if animated {
                UIView.animate(withDuration: 0.2, animations: hideUpdate)
            } else {
                hideUpdate()
            }
            return
        }

        guard selectedView.bounds.width > 0 else { return }

        let update = {
            self.selectionIndicator.alpha = 1
            let centerInSelf = selectedView.convert(
                CGPoint(x: selectedView.bounds.midX, y: 0),
                to: self
            )
            self.selectionIndicatorCenterX?.constant = centerInSelf.x
            self.selectionIndicatorWidth?.constant = max(0, selectedView.bounds.width - self.appearanceConfiguration.selectionIndicatorWidthInset)
            self.layoutIfNeeded()
        }

        if animated {
            let config = appearanceConfiguration
            UIView.animate(
                withDuration: config.selectionAnimationDuration,
                delay: 0,
                usingSpringWithDamping: config.selectionSpringDamping,
                initialSpringVelocity: config.springVelocity
            ) {
                update()
            }
        } else {
            update()
        }
    }
}

// MARK: - GlassToolbarItemView

/// Single toolbar item view
class GlassToolbarItemView: UIView {

    // MARK: - Properties

    var isSelected: Bool = false {
        didSet { updateAppearance() }
    }

    var appearanceConfiguration: ToolbarAppearanceConfiguration = .default {
        didSet { applyConfiguration() }
    }

    private var item: GlassToolbarItem?

    // MARK: - UI Components

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false
        return stack
    }()

    // MARK: - Constraints

    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        isUserInteractionEnabled = true
        backgroundColor = .clear

        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        addSubview(stackView)

        let iconSize = appearanceConfiguration.itemIconSize
        let widthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: iconSize)
        let heightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: iconSize)
        iconWidthConstraint = widthConstraint
        iconHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            widthConstraint,
            heightConstraint,
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        applyConfiguration()
    }

    private func applyConfiguration() {
        let config = appearanceConfiguration
        iconWidthConstraint?.constant = config.itemIconSize
        iconHeightConstraint?.constant = config.itemIconSize
        titleLabel.font = .systemFont(ofSize: config.itemFontSize, weight: isSelected ? .semibold : .medium)
    }

    // MARK: - Configuration

    func configure(with item: GlassToolbarItem) {
        self.item = item
        iconImageView.image = item.icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = item.title
    }

    // MARK: - Appearance

    private var currentDisplayMode: ItemDisplayMode = .full

    func setDisplayMode(_ mode: ItemDisplayMode) {
        let modeChanged = mode != currentDisplayMode
        currentDisplayMode = mode

        // Cancel any ongoing animations on the label
        titleLabel.layer.removeAllAnimations()

        // Determine target alpha
        let targetAlpha: CGFloat = (mode == .full || mode == .compactTitle) ? 1 : 0

        // Configure label based on mode
        switch mode {
        case .full:
            titleLabel.text = item?.title
            titleLabel.isHidden = false
        case .compactTitle:
            titleLabel.text = item?.compactTitle ?? item?.title
            titleLabel.isHidden = false
        case .iconOnly:
            titleLabel.isHidden = true
        case .hidden:
            break
        }

        // Only animate if mode changed, otherwise just set final value
        if modeChanged {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0
            ) {
                self.titleLabel.alpha = targetAlpha
            }
        } else {
            // Ensure correct state even if mode didn't change
            // (handles interrupted animations)
            titleLabel.alpha = targetAlpha
        }

        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let config = appearanceConfiguration
        switch currentDisplayMode {
        case .full, .compactTitle:
            return config.itemFullSize
        case .iconOnly:
            return config.itemCompactSize
        case .hidden:
            return .zero
        }
    }

    private func updateAppearance() {
        guard let item = item else { return }
        let fontSize = appearanceConfiguration.itemFontSize

        UIView.animate(withDuration: 0.2) {
            if self.isSelected {
                self.iconImageView.image = item.selectedIcon?.withRenderingMode(.alwaysTemplate)
                self.iconImageView.tintColor = .label
                self.titleLabel.textColor = .label
                self.titleLabel.font = .systemFont(ofSize: fontSize, weight: .semibold)
            } else {
                self.iconImageView.image = item.icon?.withRenderingMode(.alwaysTemplate)
                self.iconImageView.tintColor = .secondaryLabel
                self.titleLabel.textColor = .secondaryLabel
                self.titleLabel.font = .systemFont(ofSize: fontSize, weight: .medium)
            }
        }
    }
}
