//
//  GlassAccessoryComponents.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - GlassBackgroundView

/// Glass background view with blur effect
class GlassBackgroundView: UIView {

    // MARK: - Properties

    var cornerRadius: CGFloat = 26 {
        didSet { updateCornerRadius() }
    }

    // MARK: - UI Components

    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let glossLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0.0, 0.35, 1.0]
        return layer
    }()

    private let borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1
        return layer
    }()

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
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 14
        layer.shadowOpacity = 0.12

        addSubview(blurEffectView)
        blurEffectView.layer.cornerRadius = cornerRadius
        blurEffectView.clipsToBounds = true

        blurEffectView.contentView.layer.addSublayer(glossLayer)
        layer.addSublayer(borderLayer)

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateCornerRadius() {
        blurEffectView.layer.cornerRadius = cornerRadius
        glossLayer.cornerRadius = cornerRadius
        setNeedsLayout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        glossLayer.frame = bounds
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: cornerRadius
        ).cgPath
    }
}

// MARK: - GlassEffectContainer

/// Glass effect container that can hold multiple subviews
class GlassEffectContainer: UIView {

    enum Style {
        case ultraThin
        case thin
        case regular
        case thick
    }

    private let blurView: UIVisualEffectView
    private let glossLayer = CAGradientLayer()
    private let borderLayer = CAShapeLayer()

    var glassCornerRadius: CGFloat = 16 {
        didSet {
            layer.cornerRadius = glassCornerRadius
            updateLayers()
        }
    }

    init(style: Style = .ultraThin) {
        let blurStyle: UIBlurEffect.Style
        switch style {
        case .ultraThin:
            blurStyle = .systemUltraThinMaterial
        case .thin:
            blurStyle = .systemThinMaterial
        case .regular:
            blurStyle = .systemMaterial
        case .thick:
            blurStyle = .systemThickMaterial
        }

        blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))

        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = glassCornerRadius

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        glossLayer.colors = [
            UIColor.white.withAlphaComponent(0.2).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.3, 1.0]
        blurView.contentView.layer.addSublayer(glossLayer)

        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 0.5
        layer.addSublayer(borderLayer)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
    }

    private func updateLayers() {
        glossLayer.cornerRadius = glassCornerRadius
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0.25, dy: 0.25),
            cornerRadius: glassCornerRadius
        ).cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glossLayer.frame = bounds
        borderLayer.frame = bounds
        updateLayers()
    }

    var contentView: UIView {
        return blurView.contentView
    }
}
