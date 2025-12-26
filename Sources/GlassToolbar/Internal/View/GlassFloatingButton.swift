//
//  GlassFloatingButton.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - GlassFloatingButton

/// Glass style floating button, used as side button
@MainActor
class GlassFloatingButton: UIView {

    // MARK: - Gesture Callbacks

    var onTap: (@MainActor () -> Void)?
    var onSwipe: (@MainActor (SwipeDirection) -> Void)?

    // MARK: - Gesture Configuration

    var enabledSwipeDirections: Set<SwipeDirection> = Set(SwipeDirection.allCases)
    var swipeThreshold: CGFloat = 30
    var swipeVelocityThreshold: CGFloat = 200

    // MARK: - Properties

    var appearanceConfiguration: ToolbarAppearanceConfiguration = .default {
        didSet { applyAppearanceConfiguration() }
    }

    private let config: GlassSideButtonConfig

    // MARK: - Gesture State

    private var panStartPoint: CGPoint = .zero
    private var isPanning: Bool = false

    // MARK: - UI Components

    private lazy var blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var colorBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private let glossLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0.0, 0.4, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.0
        return layer
    }()

    // MARK: - Constraints

    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    init(config: GlassSideButtonConfig) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        self.config = GlassSideButtonConfig(icon: nil)
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        MainActor.assumeIsolated {
            onTap = nil
            onSwipe = nil
        }
    }

    // MARK: - Setup

    private func setupUI() {
        isUserInteractionEnabled = true

        let useGlassEffect = config.backgroundColor == .clear

        if useGlassEffect {
            setupGlassBackground()
        } else {
            setupColorBackground()
        }

        iconImageView.image = config.icon?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = config.tintColor
        addSubview(iconImageView)

        layer.masksToBounds = false

        setupConstraints()
        setupGestures()
        applyAppearanceConfiguration()
    }

    private func applyAppearanceConfiguration() {
        let config = appearanceConfiguration

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = config.floatingButtonShadowOffset
        layer.shadowRadius = config.floatingButtonShadowRadius
        layer.shadowOpacity = config.floatingButtonShadowOpacity

        // Glass effect colors
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(config.glossTopAlpha + 0.07).cgColor,
            UIColor.white.withAlphaComponent(config.glossMiddleAlpha + 0.02).cgColor,
            UIColor.clear.cgColor
        ]

        // Icon size
        iconWidthConstraint?.constant = config.floatingButtonIconSize
        iconHeightConstraint?.constant = config.floatingButtonIconSize
    }

    // MARK: - Dynamic Update

    /// Update button appearance dynamically
    /// - Parameters:
    ///   - icon: New icon (nil to keep current)
    ///   - backgroundColor: New background color (nil to keep current, only works for non-glass buttons)
    ///   - tintColor: New tint color (nil to keep current)
    ///   - animated: Whether to animate the change
    func updateAppearance(
        icon: UIImage? = nil,
        backgroundColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        animated: Bool = true
    ) {
        let updates = {
            if let icon = icon {
                self.iconImageView.image = icon.withRenderingMode(.alwaysTemplate)
            }
            if let tintColor = tintColor {
                self.iconImageView.tintColor = tintColor
            }
            if let backgroundColor = backgroundColor, self.config.backgroundColor != .clear {
                self.colorBackgroundView.backgroundColor = backgroundColor
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                updates()
            }
        } else {
            updates()
        }
    }

    private func setupGlassBackground() {
        addSubview(blurEffectView)
        blurEffectView.clipsToBounds = true
        blurEffectView.contentView.layer.addSublayer(glossLayer)

        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        layer.addSublayer(borderLayer)
    }

    private func setupColorBackground() {
        colorBackgroundView.backgroundColor = config.backgroundColor
        addSubview(colorBackgroundView)
        colorBackgroundView.layer.addSublayer(glossLayer)

        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        layer.addSublayer(borderLayer)
    }

    private func setupConstraints() {
        let useGlassEffect = config.backgroundColor == .clear

        if useGlassEffect {
            NSLayoutConstraint.activate([
                blurEffectView.topAnchor.constraint(equalTo: topAnchor),
                blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                colorBackgroundView.topAnchor.constraint(equalTo: topAnchor),
                colorBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
                colorBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
                colorBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        let iconSize = appearanceConfiguration.floatingButtonIconSize
        let widthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: iconSize)
        let heightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: iconSize)
        iconWidthConstraint = widthConstraint
        iconHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthConstraint,
            heightConstraint
        ])
    }

    private func setupGestures() {
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        // Long press for visual feedback
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.delegate = self
        addGestureRecognizer(longPressGesture)

        // Pan gesture for swipe detection
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = bounds.height / 2
        layer.cornerRadius = cornerRadius

        if config.backgroundColor == .clear {
            blurEffectView.layer.cornerRadius = cornerRadius
        } else {
            colorBackgroundView.layer.cornerRadius = cornerRadius
        }

        glossLayer.frame = bounds
        glossLayer.cornerRadius = cornerRadius

        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: cornerRadius
        ).cgPath
    }

    // MARK: - Actions

    @objc private func handleTap() {
        // Don't trigger tap if we just finished a swipe
        guard !isPanning else { return }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        onTap?()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Don't show press feedback during pan
        guard !isPanning else { return }

        switch gesture.state {
        case .began:
            animatePress(pressed: true)
        case .ended, .cancelled:
            animatePress(pressed: false)
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panStartPoint = gesture.location(in: self)
            isPanning = true
            animateSwipeStart()

        case .changed:
            let currentPoint = gesture.location(in: self)
            let translation = CGPoint(
                x: currentPoint.x - panStartPoint.x,
                y: currentPoint.y - panStartPoint.y
            )
            animateSwipeProgress(translation: translation)

        case .ended:
            let velocity = gesture.velocity(in: self)
            let translation = gesture.translation(in: self)

            if let direction = detectSwipeDirection(translation: translation, velocity: velocity) {
                triggerSwipe(direction: direction)
            }

            animateSwipeEnd()
            // Delay resetting isPanning to prevent tap from firing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isPanning = false
            }

        case .cancelled, .failed:
            animateSwipeEnd()
            isPanning = false

        default:
            break
        }
    }

    // MARK: - Swipe Detection

    private func detectSwipeDirection(translation: CGPoint, velocity: CGPoint) -> SwipeDirection? {
        let absX = abs(translation.x)
        let absY = abs(translation.y)
        let absVelocityX = abs(velocity.x)
        let absVelocityY = abs(velocity.y)

        // Check if swipe exceeds threshold (either by distance or velocity)
        let horizontalSwipe = absX > swipeThreshold || absVelocityX > swipeVelocityThreshold
        let verticalSwipe = absY > swipeThreshold || absVelocityY > swipeVelocityThreshold

        guard horizontalSwipe || verticalSwipe else { return nil }

        // Determine primary direction
        let direction: SwipeDirection

        if absX > absY {
            // Horizontal swipe
            direction = translation.x > 0 ? .right : .left
        } else {
            // Vertical swipe
            direction = translation.y > 0 ? .down : .up
        }

        // Check if this direction is enabled
        guard enabledSwipeDirections.contains(direction) else { return nil }

        return direction
    }

    private func triggerSwipe(direction: SwipeDirection) {
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        // Visual feedback for swipe direction
        animateSwipeTrigger(direction: direction)

        // Trigger callback
        onSwipe?(direction)
    }

    // MARK: - Swipe Animations

    private func animateSwipeStart() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    private func animateSwipeProgress(translation: CGPoint) {
        // Limit the visual movement
        let maxOffset: CGFloat = 8
        let clampedX = max(-maxOffset, min(maxOffset, translation.x * 0.3))
        let clampedY = max(-maxOffset, min(maxOffset, translation.y * 0.3))

        UIView.animate(withDuration: 0.05, delay: 0, options: .curveLinear) {
            self.transform = CGAffineTransform(translationX: clampedX, y: clampedY)
                .scaledBy(x: 0.95, y: 0.95)
        }
    }

    private func animateSwipeTrigger(direction: SwipeDirection) {
        // Quick bounce in swipe direction
        let offset: CGFloat = 12
        var translateX: CGFloat = 0
        var translateY: CGFloat = 0

        switch direction {
        case .up: translateY = -offset
        case .down: translateY = offset
        case .left: translateX = -offset
        case .right: translateX = offset
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            self.transform = CGAffineTransform(translationX: translateX, y: translateY)
                .scaledBy(x: 0.92, y: 0.92)
        }
    }

    private func animateSwipeEnd() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }

    private func animatePress(pressed: Bool) {
        // Don't animate press if panning
        guard !isPanning else { return }

        let scale = appearanceConfiguration.pressScaleFactor
        let pressAlpha = appearanceConfiguration.pressAlpha

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
            if pressed {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
                self.alpha = pressAlpha
            } else {
                self.transform = .identity
                self.alpha = 1.0
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension GlassFloatingButton: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow long press to work with other gestures for visual feedback
        if gestureRecognizer is UILongPressGestureRecognizer ||
           otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }

        // Don't allow tap and pan to fire together
        if (gestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) ||
           (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UITapGestureRecognizer) {
            return false
        }

        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Tap should wait for pan to fail (i.e., if swipe detected, don't trigger tap)
        if gestureRecognizer is UITapGestureRecognizer &&
           otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}

// MARK: - GlassFloatingButtonStyle

/// Floating button preset styles
public enum GlassFloatingButtonStyle: Sendable {
    case glass
    case primary
    case secondary
    case success
    case warning
    case danger

    @MainActor
    var config: (background: UIColor, tint: UIColor) {
        switch self {
        case .glass:
            return (.clear, .label)
        case .primary:
            return (.systemBlue, .white)
        case .secondary:
            return (.secondarySystemFill, .label)
        case .success:
            return (.systemGreen, .white)
        case .warning:
            return (.systemOrange, .white)
        case .danger:
            return (.systemRed, .white)
        }
    }
}

// MARK: - Convenience Initializers

extension GlassSideButtonConfig {

    /// Create a styled button with optional gesture support
    public static func styled(
        _ style: GlassFloatingButtonStyle,
        icon: UIImage?,
        priority: SideButtonPriority = .primary,
        overflowTitle: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        gestures: SideButtonGestureConfig? = nil
    ) -> GlassSideButtonConfig {
        let styleConfig = style.config
        return GlassSideButtonConfig(
            icon: icon,
            backgroundColor: styleConfig.background,
            tintColor: styleConfig.tint,
            priority: priority,
            overflowTitle: overflowTitle,
            action: action,
            gestures: gestures
        )
    }

    /// Create a styled button with swipe gesture support
    public static func styled(
        _ style: GlassFloatingButtonStyle,
        icon: UIImage?,
        priority: SideButtonPriority = .primary,
        overflowTitle: String? = nil,
        onTap: (@MainActor () -> Void)? = nil,
        onSwipe: (@MainActor (SwipeDirection) -> Void)? = nil,
        enabledDirections: Set<SwipeDirection> = Set(SwipeDirection.allCases)
    ) -> GlassSideButtonConfig {
        let styleConfig = style.config
        let gestures = SideButtonGestureConfig(
            onTap: onTap,
            onSwipe: onSwipe,
            enabledDirections: enabledDirections
        )
        return GlassSideButtonConfig(
            icon: icon,
            backgroundColor: styleConfig.background,
            tintColor: styleConfig.tint,
            priority: priority,
            overflowTitle: overflowTitle,
            action: nil,
            gestures: gestures
        )
    }

    public static func addButton(
        priority: SideButtonPriority = .essential,
        action: (@MainActor () -> Void)? = nil
    ) -> GlassSideButtonConfig {
        return .styled(.primary, icon: UIImage(systemName: "plus"), priority: priority, overflowTitle: "Add", action: action)
    }

    public static func editButton(
        priority: SideButtonPriority = .primary,
        action: (@MainActor () -> Void)? = nil
    ) -> GlassSideButtonConfig {
        return .styled(.primary, icon: UIImage(systemName: "pencil"), priority: priority, overflowTitle: "Edit", action: action)
    }

    public static func shareButton(
        priority: SideButtonPriority = .secondary,
        action: (@MainActor () -> Void)? = nil
    ) -> GlassSideButtonConfig {
        return .styled(.glass, icon: UIImage(systemName: "square.and.arrow.up"), priority: priority, overflowTitle: "Share", action: action)
    }

    public static func moreButton(
        priority: SideButtonPriority = .secondary,
        action: (@MainActor () -> Void)? = nil
    ) -> GlassSideButtonConfig {
        return .styled(.glass, icon: UIImage(systemName: "ellipsis"), priority: priority, overflowTitle: "More", action: action)
    }
}
