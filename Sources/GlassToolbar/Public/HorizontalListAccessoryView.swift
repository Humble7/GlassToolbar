//
//  HorizontalListAccessoryView.swift
//  GlassToolbar
//
//  Created by ChenZhen on 30/12/25.
//

import UIKit

// MARK: - HorizontalListAccessoryView

/// A horizontal scrollable list accessory view for GlassToolbar.
/// Displays a list of items with icons and titles, supporting selection state.
public class HorizontalListAccessoryView: UIView {

    // MARK: - Types

    /// Represents an item in the horizontal list.
    public struct ListItem {
        public let icon: UIImage?
        public let title: String
        public let tintColor: UIColor

        public init(icon: UIImage?, title: String, tintColor: UIColor = .label) {
            self.icon = icon
            self.title = title
            self.tintColor = tintColor
        }
    }

    // MARK: - Configuration

    /// Configuration options for the horizontal list appearance and behavior.
    public struct Configuration {
        public var showsSelection: Bool
        public var showsCount: Bool
        public var selectionColor: UIColor
        public var borderColor: UIColor?

        public var effectiveBorderColor: UIColor {
            borderColor ?? selectionColor
        }

        public init(
            showsSelection: Bool = true,
            showsCount: Bool = true,
            selectionColor: UIColor = .label,
            borderColor: UIColor? = nil
        ) {
            self.showsSelection = showsSelection
            self.showsCount = showsCount
            self.selectionColor = selectionColor
            self.borderColor = borderColor
        }

        public static let `default` = Configuration()
        public static let noSelection = Configuration(showsSelection: false, showsCount: false)
    }

    // MARK: - Properties

    /// Callback when an item is tapped. The parameter is the index of the tapped item.
    public var onItemTap: ((Int) -> Void)?

    private var items: [ListItem] = []
    private var selectedIndex: Int = 0
    private var configuration: Configuration = .default

    deinit {
        MainActor.assumeIsolated {
            onItemTap = nil
        }
    }

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Brush"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.alignment = .leading
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleStack)
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64),

            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleStack.widthAnchor.constraint(equalToConstant: 40),

            scrollView.leadingAnchor.constraint(equalTo: titleStack.trailingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 56),

            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    // MARK: - Public Methods

    /// Configure the horizontal list with items and options.
    /// - Parameters:
    ///   - title: The title displayed on the left side.
    ///   - items: The list of items to display.
    ///   - selectedIndex: The index of the initially selected item.
    ///   - configuration: Configuration options for appearance and behavior.
    public func configure(
        title: String,
        items: [ListItem],
        selectedIndex: Int = 0,
        configuration: Configuration = .default
    ) {
        self.items = items
        self.selectedIndex = selectedIndex
        self.configuration = configuration
        titleLabel.text = title
        countLabel.text = configuration.showsCount ? "(\(items.count))" : ""

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in items.enumerated() {
            let isSelected = configuration.showsSelection && (index == selectedIndex)
            let itemView = createItemView(item: item, index: index, isSelected: isSelected)
            stackView.addArrangedSubview(itemView)
        }
    }

    /// Update the selection color and refresh the list.
    /// - Parameter color: The new selection color.
    public func updateSelectionColor(_ color: UIColor) {
        configuration.selectionColor = color
        let currentTitle = titleLabel.text ?? ""
        configure(title: currentTitle, items: items, selectedIndex: selectedIndex, configuration: configuration)
    }

    /// Update only the border color and refresh the list.
    /// - Parameter color: The new border color.
    public func updateBorderColor(_ color: UIColor) {
        configuration.borderColor = color
        let currentTitle = titleLabel.text ?? ""
        configure(title: currentTitle, items: items, selectedIndex: selectedIndex, configuration: configuration)
    }

    private func createItemView(item: ListItem, index: Int, isSelected: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.tag = index

        let selectionColor = configuration.selectionColor
        let borderColor = configuration.effectiveBorderColor

        let selectionRing = UIView()
        selectionRing.translatesAutoresizingMaskIntoConstraints = false
        selectionRing.backgroundColor = isSelected ? borderColor.withAlphaComponent(0.15) : .clear
        selectionRing.layer.borderWidth = isSelected ? 2 : 0
        selectionRing.layer.borderColor = isSelected ? borderColor.cgColor : UIColor.clear.cgColor
        selectionRing.layer.cornerRadius = 20

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 9, weight: .medium)
        titleLabel.textColor = isSelected ? selectionColor : .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(selectionRing)
        container.addSubview(titleLabel)

        // Add icon
        if let icon = item.icon {
            let iconView = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
            iconView.tintColor = isSelected ? selectionColor : .secondaryLabel
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(iconView)

            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: selectionRing.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: selectionRing.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22)
            ])
        }

        // Calculate width based on title text, with minimum of 44 for icon
        let titleWidth = item.title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .medium)]).width
        let containerWidth = max(44, titleWidth + 4)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: containerWidth),
            container.heightAnchor.constraint(equalToConstant: 56),

            selectionRing.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            selectionRing.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            selectionRing.widthAnchor.constraint(equalToConstant: 40),
            selectionRing.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: selectionRing.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleItemTap(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let tappedIndex = view.tag

        // Only update selection if showsSelection is enabled
        if configuration.showsSelection && tappedIndex != selectedIndex {
            selectedIndex = tappedIndex

            let currentItems = items
            let currentTitle = titleLabel.text ?? ""
            configure(title: currentTitle, items: currentItems, selectedIndex: tappedIndex, configuration: configuration)
        }

        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        }

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        onItemTap?(tappedIndex)
    }
}

// MARK: - GlassAccessoryProvider

extension HorizontalListAccessoryView: GlassAccessoryProvider {
    public var accessoryView: UIView { self }
    public var preferredHeight: CGFloat { 64 }

    public func cleanup() {
        onItemTap = nil
    }
}
