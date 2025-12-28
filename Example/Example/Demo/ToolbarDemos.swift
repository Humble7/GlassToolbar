//
//  ToolbarDemos.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit
import SwiftUI
import GlassToolbar

// MARK: - Main Toolbar Demo

/// Main toolbar demo with all features
class ToolbarDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Glass Toolbar"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = "Resize window to see adaptive layout"
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        let dualSliderView = DualSliderAccessoryView()
        dualSliderView.configure(
            icon1: UIImage(systemName: "circle.fill"),
            icon2: UIImage(systemName: "eye"),
            value1: 0.5, value2: 0.8,
            color1: .systemBlue, color2: .systemPurple,
            circleColor: .systemBlue
        )

        let brushListView = HorizontalListAccessoryView()
        brushListView.configure(title: "Brush", items: [
            .init(icon: UIImage(systemName: "pencil.tip"), title: "Fine"),
            .init(icon: UIImage(systemName: "paintbrush"), title: "Medium"),
            .init(icon: UIImage(systemName: "paintbrush.pointed"), title: "Thick")
        ], selectedIndex: 0, configuration: .init(showsSelection: true, showsCount: true, selectionColor: .systemBlue))

        let miniPlayerView = MiniPlayerAccessoryView()
        miniPlayerView.configure(title: "Shape of You", artist: "Ed Sheeran")

        toolbarController.setItems([
            GlassToolbarItem(
                title: "Home",
                icon: UIImage(systemName: "house"),
                selectedIcon: UIImage(systemName: "house.fill"),
                priority: .essential,
                sideButton: .addButton(priority: .essential, action: { [weak self] in
                    self?.showAlert(title: "Add", message: "Add button tapped")
                }),
                accessoryProvider: dualSliderView,
                secondaryAccessoryProvider: brushListView
            ),
            GlassToolbarItem(
                title: "Discover",
                icon: UIImage(systemName: "safari"),
                selectedIcon: UIImage(systemName: "safari.fill"),
                priority: .primary
            ),
            GlassToolbarItem(
                title: "Favorites",
                icon: UIImage(systemName: "heart"),
                selectedIcon: UIImage(systemName: "heart.fill"),
                priority: .primary,
                sideButton: .styled(.danger, icon: UIImage(systemName: "trash"), action: { [weak self] in
                    self?.showAlert(title: "Delete", message: "Delete button tapped")
                })
            ),
            GlassToolbarItem(
                title: "Messages",
                icon: UIImage(systemName: "bell"),
                selectedIcon: UIImage(systemName: "bell.fill"),
                priority: .secondary,
                accessoryProvider: miniPlayerView
            ),
            GlassToolbarItem(
                title: "Settings",
                icon: UIImage(systemName: "gearshape"),
                selectedIcon: UIImage(systemName: "gearshape.fill"),
                priority: .secondary
            )
        ])
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Simple Toolbar Demo

class SimpleToolbarDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        toolbarController.setItems([
            GlassToolbarItem(title: "Home", icon: UIImage(systemName: "house"), selectedIcon: UIImage(systemName: "house.fill")),
            GlassToolbarItem(title: "Search", icon: UIImage(systemName: "magnifyingglass")),
            GlassToolbarItem(title: "Settings", icon: UIImage(systemName: "gearshape"), selectedIcon: UIImage(systemName: "gearshape.fill"))
        ])
    }
}

// MARK: - Ultra Minimal Mode Demo

class UltraMinimalEnabledDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()
    private let titleLabel = UILabel()
    private let modeSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        titleLabel.text = "Ultra Minimal Mode"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let switchStack = UIStackView()
        switchStack.axis = .horizontal
        switchStack.spacing = 12
        switchStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switchStack)

        let switchLabel = UILabel()
        switchLabel.text = "Enable"
        switchLabel.font = .systemFont(ofSize: 17)
        switchStack.addArrangedSubview(switchLabel)

        modeSwitch.isOn = true
        modeSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        switchStack.addArrangedSubview(modeSwitch)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.text = "Shows only 1 item + side button\nAccessory view hidden"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            switchStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: switchStack.bottomAnchor, constant: 20),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func switchChanged() {
        toolbarController.isUltraMinimalMode = modeSwitch.isOn
    }

    private func setupToolbar() {
        let sliderView = DualSliderAccessoryView()
        sliderView.configure(
            icon1: UIImage(systemName: "textformat.size"),
            icon2: UIImage(systemName: "circle.lefthalf.filled"),
            value1: 0.5, value2: 0.8,
            color1: .systemTeal, color2: .systemMint,
            circleColor: .systemCyan
        )

        toolbarController.setItems([
            GlassToolbarItem(
                title: "Brush",
                icon: UIImage(systemName: "paintbrush"),
                selectedIcon: UIImage(systemName: "paintbrush.fill"),
                priority: .essential,
                sideButton: .styled(.glass, icon: UIImage(systemName: "plus"), action: {}),
                accessoryProvider: sliderView
            ),
            GlassToolbarItem(title: "Eraser", icon: UIImage(systemName: "eraser"), priority: .primary),
            GlassToolbarItem(title: "Select", icon: UIImage(systemName: "lasso"), priority: .primary),
            GlassToolbarItem(title: "Layers", icon: UIImage(systemName: "square.3.layers.3d"), priority: .secondary)
        ])

        toolbarController.isUltraMinimalMode = true
    }
}

// MARK: - Custom Layout Demo

class CustomLayoutDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Custom Layout Config"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        var config = ToolbarLayoutConfiguration()
        config.spaceTierThresholds = SpaceTierThresholds(spacious: 600, regular: 480, compact: 380, tight: 300)
        config.itemSpacingFull = 20
        config.itemSpacingCompact = 6
        toolbarController.layoutConfiguration = config

        toolbarController.setItems([
            GlassToolbarItem(title: "Home", icon: UIImage(systemName: "house"), selectedIcon: UIImage(systemName: "house.fill"), priority: .essential),
            GlassToolbarItem(title: "Browse", icon: UIImage(systemName: "square.grid.2x2"), priority: .primary),
            GlassToolbarItem(title: "Create", icon: UIImage(systemName: "plus.circle"), priority: .primary),
            GlassToolbarItem(title: "Profile", icon: UIImage(systemName: "person"), priority: .secondary)
        ])
    }
}

// MARK: - Many Items Demo

class ManyItemsDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "8 Items Compression"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = "Resize to see overflow menu"
        descLabel.font = .systemFont(ofSize: 15)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        toolbarController.setItems([
            GlassToolbarItem(title: "Home", icon: UIImage(systemName: "house"), priority: .essential),
            GlassToolbarItem(title: "Discover", icon: UIImage(systemName: "safari"), priority: .essential),
            GlassToolbarItem(title: "Favorites", icon: UIImage(systemName: "heart"), priority: .primary),
            GlassToolbarItem(title: "Messages", icon: UIImage(systemName: "bell"), priority: .primary),
            GlassToolbarItem(title: "Cart", icon: UIImage(systemName: "cart"), priority: .secondary),
            GlassToolbarItem(title: "Orders", icon: UIImage(systemName: "list.clipboard"), priority: .secondary),
            GlassToolbarItem(title: "Wallet", icon: UIImage(systemName: "wallet.pass"), priority: .secondary),
            GlassToolbarItem(title: "Settings", icon: UIImage(systemName: "gearshape"), priority: .overflow)
        ])

        toolbarController.globalSideButton = .addButton(priority: .essential, action: {})
    }
}

// MARK: - Global Accessory Provider Demo

class GlobalAccessoryDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Global Accessory Provider"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.text = "Home: Item Accessory (Slider)\nOthers: Global Accessory (Player)"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        statusLabel.text = "Current: Home (Item Accessory)"
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .systemIndigo
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        let sliderView = DualSliderAccessoryView()
        sliderView.configure(
            icon1: UIImage(systemName: "sun.max"),
            icon2: UIImage(systemName: "moon.stars"),
            value1: 0.7, value2: 0.5,
            color1: .systemOrange, color2: .systemIndigo,
            circleColor: .systemYellow
        )

        let globalPlayer = MiniPlayerAccessoryView()
        globalPlayer.configure(title: "Blinding Lights", artist: "The Weeknd")

        toolbarController.globalAccessoryProvider = globalPlayer

        toolbarController.setItems([
            GlassToolbarItem(
                title: "Home",
                icon: UIImage(systemName: "house"),
                selectedIcon: UIImage(systemName: "house.fill"),
                priority: .essential,
                accessoryProvider: sliderView
            ),
            GlassToolbarItem(title: "Search", icon: UIImage(systemName: "magnifyingglass"), priority: .primary),
            GlassToolbarItem(title: "Library", icon: UIImage(systemName: "books.vertical"), priority: .primary),
            GlassToolbarItem(title: "Profile", icon: UIImage(systemName: "person.circle"), priority: .secondary)
        ])

        toolbarController.onItemSelected = { [weak self] index in
            let titles = ["Home", "Search", "Library", "Profile"]
            let type = index == 0 ? "Item Accessory" : "Global Accessory"
            self?.statusLabel.text = "Current: \(titles[index]) (\(type))"
        }
    }
}

// MARK: - Dynamic Side Button Demo

class DynamicSideButtonDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()
    private let statusLabel = UILabel()
    private var isPlaying = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Dynamic Side Button"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.text = "Tap side button to toggle\nIcon: play ↔ pause\nColor: blue ↔ green"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        statusLabel.text = "State: Paused"
        statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statusLabel.textColor = .systemBlue
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 30),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        toolbarController.setItems([
            GlassToolbarItem(
                title: "Music",
                icon: UIImage(systemName: "music.note"),
                priority: .essential,
                sideButton: .styled(.primary, icon: UIImage(systemName: "play.fill"), priority: .essential, action: { [weak self] in
                    self?.togglePlayState()
                })
            ),
            GlassToolbarItem(title: "Playlist", icon: UIImage(systemName: "list.bullet"), priority: .primary),
            GlassToolbarItem(title: "Settings", icon: UIImage(systemName: "gearshape"), priority: .secondary)
        ])
    }

    private func togglePlayState() {
        isPlaying.toggle()
        toolbarController.updateSideButtonAppearance(
            icon: UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"),
            backgroundColor: isPlaying ? .systemGreen : .systemBlue,
            animated: true
        )
        statusLabel.text = "State: \(isPlaying ? "Playing" : "Paused")"
        statusLabel.textColor = isPlaying ? .systemGreen : .systemBlue
    }
}

// MARK: - Swipe Gesture Demo

/// Demo showing Side Button swipe gesture support with Color Picker
class SwipeGestureDemoVC: UIViewController, UIColorPickerViewControllerDelegate {

    private let toolbarController = GlassToolbarController()
    private let statusLabel = UILabel()
    private let colorPreviewView = UIView()

    // Current selected color
    private var selectedColor: UIColor = .black

    // Hold references to sync colors with side button
    private var dualSliderView: DualSliderAccessoryView!
    private var brushListView: HorizontalListAccessoryView!

    // Brush types with icons
    private let brushTypes: [(icon: String, title: String)] = [
        ("pencil.tip", "Monoline"),
        ("swatchpalette.fill", "Textured"),
        ("paintbrush.pointed", "Dynamic"),
        ("paintbrush", "Coloring")
    ]
    private var selectedBrushIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Color Picker Demo"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.text = "Tap side button → Open Color Picker\nSwipe ↑ → Apply color to background"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        // Color preview
        colorPreviewView.backgroundColor = selectedColor
        colorPreviewView.layer.cornerRadius = 40
        colorPreviewView.layer.borderWidth = 3
        colorPreviewView.layer.borderColor = UIColor.separator.cgColor
        colorPreviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorPreviewView)

        statusLabel.text = "Selected: Black"
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),

            colorPreviewView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
            colorPreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorPreviewView.widthAnchor.constraint(equalToConstant: 80),
            colorPreviewView.heightAnchor.constraint(equalToConstant: 80),

            statusLabel.topAnchor.constraint(equalTo: colorPreviewView.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        // Primary accessory: Dual Slider (Size & Opacity)
        dualSliderView = DualSliderAccessoryView()
        dualSliderView.configure(
            value1: 0.5,
            value2: 0.8,
            color1: selectedColor,  // Sync with side button color
            color2: selectedColor,  // Sync with side button color
            circleColor: selectedColor
        )

        // Secondary accessory: Brush List with icons
        brushListView = HorizontalListAccessoryView()
        let brushItems = brushTypes.map { brush in
            HorizontalListAccessoryView.ListItem(
                icon: UIImage(systemName: brush.icon),
                title: brush.title
            )
        }
        brushListView.configure(
            title: "Brush",
            items: brushItems,
            selectedIndex: selectedBrushIndex,
            configuration: .init(showsSelection: true, showsCount: true, selectionColor: .label, borderColor: selectedColor)
        )

        // Handle brush selection
        brushListView.onItemTap = { [weak self] index in
            self?.handleBrushSelection(index)
        }

        // Share accessory: Export format options without selection
        let shareListView = HorizontalListAccessoryView()
        let shareItems: [HorizontalListAccessoryView.ListItem] = [
            .init(icon: UIImage(systemName: "livephoto"), title: "Live Photo"),
            .init(icon: UIImage(systemName: "scribble"), title: "DotShake"),
            .init(icon: UIImage(systemName: "photo.circle"), title: "GIF")
        ]
        shareListView.configure(
            title: "Share",
            items: shareItems,
            configuration: .noSelection
        )

        // Handle share item tap
        shareListView.onItemTap = { [weak self] index in
            let formats = ["Live Photo", "DotShake", "GIF"]
            self?.showAlert(title: "Export", message: "Exporting as \(formats[index])")
        }

        // Color side button with swipe gesture support
        let colorSideButton = GlassSideButtonConfig(
            icon: UIImage(systemName: "paintpalette.fill"),
            backgroundColor: selectedColor,
            tintColor: .white,
            priority: .essential,
            gestures: SideButtonGestureConfig(
                onTap: { [weak self] in
                    self?.showColorPicker()
                },
                onSwipe: { [weak self] direction in
                    self?.handleSwipe(direction)
                },
                enabledDirections: [.up],
                swipeThreshold: 25,
                swipeVelocityThreshold: 150
            )
        )

        // Use first brush as default
        let defaultBrush = brushTypes[selectedBrushIndex]

        toolbarController.setItems([
            GlassToolbarItem(
                title: defaultBrush.title,
                icon: UIImage(systemName: defaultBrush.icon),
                selectedIcon: UIImage(systemName: defaultBrush.icon + ".fill") ?? UIImage(systemName: defaultBrush.icon),
                priority: .essential,
                sideButton: colorSideButton,
                accessoryProvider: dualSliderView,
                secondaryAccessoryProvider: brushListView
            ),
            GlassToolbarItem(
                title: "Undo",
                icon: UIImage(systemName: "arrow.uturn.backward"),
                isSelectable: false,
                priority: .essential,
                action: { [weak self] in
                    self?.showAlert(title: "Undo", message: "Undo action triggered")
                }
            ),
            GlassToolbarItem(
                title: "Redo",
                icon: UIImage(systemName: "arrow.uturn.forward"),
                isSelectable: false,
                priority: .essential,
                action: { [weak self] in
                    self?.showAlert(title: "Redo", message: "Redo action triggered")
                }
            ),
            GlassToolbarItem(
                title: "Share",
                icon: UIImage(systemName: "square.and.arrow.up"),
                priority: .essential,
                sideButton: .styled(
                    .glass,
                    icon: UIImage(systemName: "house"),
                    action: { [weak self] in
                        self?.showAlert(title: "Home", message: "Return to home")
                    }
                ),
                accessoryProvider: shareListView
            )
        ])
    }

    private func handleBrushSelection(_ index: Int) {
        selectedBrushIndex = index
        let brush = brushTypes[index]

        // Update Brush item icon and title
        toolbarController.updateItem(at: 0) { item in
            var updatedItem = item
            updatedItem.icon = UIImage(systemName: brush.icon)
            updatedItem.selectedIcon = UIImage(systemName: brush.icon + ".fill") ?? UIImage(systemName: brush.icon)
            updatedItem.title = brush.title
            return updatedItem
        }

        statusLabel.text = "Brush: \(brush.title)"

        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.updateStatusLabel()
        }
    }

    private func showColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.selectedColor = selectedColor
        colorPicker.supportsAlpha = false
        present(colorPicker, animated: true)
    }

    private func handleSwipe(_ direction: SwipeDirection) {
        switch direction {
        case .up:
            applyColorToBackground()
        default:
            break
        }
    }

    private func applyColorToBackground() {
        // Apply selected color to view background
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = self.selectedColor.withAlphaComponent(1.0)
        }

        // Switch toolbar appearance based on color luminance
        let isLightColor = selectedColor.luminance > 0.5
        UIView.animate(withDuration: 0.3) {
            self.toolbarController.overrideUserInterfaceStyle = isLightColor ? .light : .dark
        }

        statusLabel.text = "Background applied!"

        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.updateStatusLabel()
        }
    }

    private func updateStatusLabel() {
        let colorName = selectedColor.accessibilityName
        statusLabel.text = "Selected: \(colorName)"
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UIColorPickerViewControllerDelegate

    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        guard !continuously else { return }
        updateBrushColor(color)
    }

    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        updateBrushColor(viewController.selectedColor)
    }

    /// Sync color to all related components
    private func updateBrushColor(_ color: UIColor) {
        selectedColor = color
        colorPreviewView.backgroundColor = color
        updateStatusLabel()

        // 1. Update side button config (persisted for item switching)
        toolbarController.updateItem(at: 0) { item in
            var updatedItem = item
            updatedItem.sideButton?.backgroundColor = color
            return updatedItem
        }

        // 2. Update current side button visual immediately
        toolbarController.updateSideButtonAppearance(backgroundColor: color)

        // 3. Update DualSliderAccessoryView colors (circle, sliders)
        dualSliderView.updateBrushColor(color)

        // 4. Update BrushList border color only
        brushListView.updateBorderColor(color)
    }
}

// MARK: - Compression Debug Demo

class CompressionDebugDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()
    private let tierLabel = UILabel()
    private let compressionLabel = UILabel()
    private let spacingLabel = UILabel()
    private let widthLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDebugInfo()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Compression Debug"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.text = "6 essential + 2 secondary items + side button\nResize to see: spacing, compactTitle, iconOnly, overflow"
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        let debugStack = UIStackView()
        debugStack.axis = .vertical
        debugStack.spacing = 8
        debugStack.alignment = .center
        debugStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugStack)

        for label in [widthLabel, tierLabel, compressionLabel, spacingLabel] {
            label.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
            label.textColor = .systemIndigo
            debugStack.addArrangedSubview(label)
        }

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            debugStack.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 24),
            debugStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        // Use iPad-friendly thresholds
        var config = ToolbarLayoutConfiguration()
        config.spaceTierThresholds = SpaceTierThresholds(
            spacious: 800,  // iPad full screen
            regular: 600,   // iPad 2/3 split
            compact: 450,   // iPad 1/2 split
            tight: 300      // iPhone / small split
        )
        config.itemSpacingFull = 24
        config.itemSpacingComfortable = 16
        config.itemSpacingCompact = 10
        config.itemSpacingMinimal = 4
        toolbarController.layoutConfiguration = config

        // 6 essential + 2 secondary items
        // Essential items trigger iconOnly mode when space is limited
        // Secondary items go to overflow first
        // Items with compactTitle + canHideTitle show short title at .compact compression level
        toolbarController.setItems([
            GlassToolbarItem(title: "Home", icon: UIImage(systemName: "house"), selectedIcon: UIImage(systemName: "house.fill"), priority: .essential),
            GlassToolbarItem(title: "Search", icon: UIImage(systemName: "magnifyingglass"), priority: .essential),
            GlassToolbarItem(title: "Favorites", icon: UIImage(systemName: "heart"), priority: .essential, compactTitle: "Favs"),
            GlassToolbarItem(title: "Messages", icon: UIImage(systemName: "bell"), priority: .essential, compactTitle: "Msgs"),
            GlassToolbarItem(title: "Shopping Cart", icon: UIImage(systemName: "cart"), priority: .essential, compactTitle: "Cart"),
            GlassToolbarItem(title: "Profile", icon: UIImage(systemName: "person"), priority: .essential),
            GlassToolbarItem(title: "Settings", icon: UIImage(systemName: "gearshape"), priority: .secondary, compactTitle: "Set"),  // Can overflow
            GlassToolbarItem(title: "Help Center", icon: UIImage(systemName: "questionmark.circle"), priority: .secondary, compactTitle: "Help")  // Can overflow
        ])

        // Add side button to observe size changes (52pt → 44pt → 40pt)
        toolbarController.globalSideButton = .addButton(priority: .essential, action: {
            print("[Debug] Side button tapped")
        })
    }

    private func updateDebugInfo() {
        let width = view.bounds.width
        let thresholds = toolbarController.layoutConfiguration.spaceTierThresholds
        let tier = thresholds.tier(for: width)

        widthLabel.text = "Width: \(Int(width))pt"
        tierLabel.text = "Space Tier: \(tierName(tier))"

        // Determine expected compression based on tier
        let (compression, spacing) = expectedCompression(for: tier)
        compressionLabel.text = "Compression: \(compression)"
        spacingLabel.text = "Spacing: \(spacing)pt"

        // Color code by tier
        let color: UIColor = switch tier {
        case .spacious: .systemGreen
        case .regular: .systemBlue
        case .compact: .systemOrange
        case .tight: .systemRed
        case .minimal: .systemPurple
        }
        for label in [widthLabel, tierLabel, compressionLabel, spacingLabel] {
            label.textColor = color
        }
    }

    private func tierName(_ tier: SpaceTier) -> String {
        switch tier {
        case .spacious: return "spacious (≥800)"
        case .regular: return "regular (600-799)"
        case .compact: return "compact (450-599)"
        case .tight: return "tight (300-449)"
        case .minimal: return "minimal (<300)"
        }
    }

    private func expectedCompression(for tier: SpaceTier) -> (String, Int) {
        // 6 essential + 2 secondary + side button
        // Side button: 52pt (spacious) → 44pt (compact) → 40pt (tight)
        // compactTitle: shows at .compact level for canHideTitle items
        switch tier {
        case .spacious: return ("full + button 52pt", 24)
        case .regular: return ("overflow 2 + button 52pt", 16)
        case .compact: return ("compactTitle + button 44pt", 10)
        case .tight, .minimal: return ("iconOnly + button 40pt", 4)
        }
    }
}

// MARK: - AccessoryWidthDemoVC

/// Demo to show Accessory View width capping behavior on iPad with many items
class AccessoryWidthDemoVC: UIViewController {

    private let toolbarController = GlassToolbarController()
    private let toolbarWidthLabel = UILabel()
    private let accessoryWidthLabel = UILabel()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDebugInfo()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Accessory Width Demo"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center
        descLabel.text = "12 essential items → wide toolbar on iPad\nAccessory capped at 400pt max"
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        let debugStack = UIStackView()
        debugStack.axis = .vertical
        debugStack.spacing = 8
        debugStack.alignment = .center
        debugStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugStack)

        for label in [toolbarWidthLabel, accessoryWidthLabel, statusLabel] {
            label.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
            label.textColor = .systemIndigo
            debugStack.addArrangedSubview(label)
        }

        addChild(toolbarController)
        view.addSubview(toolbarController.view)
        toolbarController.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            debugStack.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 24),
            debugStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toolbarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupToolbar() {
        // 12 essential items to create a very wide toolbar on iPad
        let icons = [
            ("house", "Home"), ("magnifyingglass", "Search"), ("heart", "Favorites"),
            ("bell", "Alerts"), ("cart", "Cart"), ("person", "Profile"),
            ("gearshape", "Settings"), ("bookmark", "Saved"), ("clock", "History"),
            ("star", "Starred"), ("folder", "Files"), ("doc", "Docs")
        ]

        let items = icons.map { icon, title in
            GlassToolbarItem(
                title: title,
                icon: UIImage(systemName: icon),
                priority: .essential  // All essential = all visible
            )
        }

        toolbarController.setItems(items)

        // Add accessory to demonstrate width capping
        let sliderView = DualSliderAccessoryView()
        sliderView.configure(
            icon1: UIImage(systemName: "circle.fill"),
            icon2: UIImage(systemName: "eye"),
            value1: 0.5,
            value2: 0.8,
            color1: .systemBlue,
            color2: .systemPurple,
            circleColor: .systemBlue
        )
        toolbarController.globalAccessoryProvider = sliderView

        // Add side button
        toolbarController.globalSideButton = .addButton(priority: .essential)
    }

    private func updateDebugInfo() {
        let containerWidth = view.bounds.width

        // Calculate expected toolbar width (rough estimate)
        let itemCount = 12
        let itemWidth: CGFloat = 64  // approximate
        let spacing: CGFloat = 16
        let padding: CGFloat = 24
        let estimatedToolbarWidth = CGFloat(itemCount) * itemWidth + CGFloat(itemCount - 1) * spacing + padding

        // Accessory width is clamped
        let accessoryMax: CGFloat = 400
        let accessoryMin: CGFloat = 200
        let accessoryWidth = max(accessoryMin, min(estimatedToolbarWidth, accessoryMax))

        toolbarWidthLabel.text = "Container: \(Int(containerWidth))pt"
        accessoryWidthLabel.text = "Accessory: \(Int(accessoryWidth))pt (max: \(Int(accessoryMax))pt)"

        if estimatedToolbarWidth > accessoryMax {
            statusLabel.text = "✓ Accessory width capped"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Accessory follows Toolbar"
            statusLabel.textColor = .systemBlue
        }
    }
}

// MARK: - SwiftUI Preview Wrappers

private struct ToolbarDemoPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ToolbarDemoVC { ToolbarDemoVC() }
    func updateUIViewController(_ vc: ToolbarDemoVC, context: Context) {}
}

private struct SimpleToolbarPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SimpleToolbarDemoVC { SimpleToolbarDemoVC() }
    func updateUIViewController(_ vc: SimpleToolbarDemoVC, context: Context) {}
}

private struct UltraMinimalPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UltraMinimalEnabledDemoVC { UltraMinimalEnabledDemoVC() }
    func updateUIViewController(_ vc: UltraMinimalEnabledDemoVC, context: Context) {}
}

private struct CustomLayoutPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CustomLayoutDemoVC { CustomLayoutDemoVC() }
    func updateUIViewController(_ vc: CustomLayoutDemoVC, context: Context) {}
}

private struct ManyItemsPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ManyItemsDemoVC { ManyItemsDemoVC() }
    func updateUIViewController(_ vc: ManyItemsDemoVC, context: Context) {}
}

private struct GlobalAccessoryPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GlobalAccessoryDemoVC { GlobalAccessoryDemoVC() }
    func updateUIViewController(_ vc: GlobalAccessoryDemoVC, context: Context) {}
}

private struct DynamicSideButtonPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DynamicSideButtonDemoVC { DynamicSideButtonDemoVC() }
    func updateUIViewController(_ vc: DynamicSideButtonDemoVC, context: Context) {}
}

private struct SwipeGesturePreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeGestureDemoVC { SwipeGestureDemoVC() }
    func updateUIViewController(_ vc: SwipeGestureDemoVC, context: Context) {}
}

private struct CompressionDebugPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CompressionDebugDemoVC { CompressionDebugDemoVC() }
    func updateUIViewController(_ vc: CompressionDebugDemoVC, context: Context) {}
}

private struct AccessoryWidthPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AccessoryWidthDemoVC { AccessoryWidthDemoVC() }
    func updateUIViewController(_ vc: AccessoryWidthDemoVC, context: Context) {}
}

// MARK: - SwiftUI Previews

#Preview("Toolbar Demo") {
    ToolbarDemoPreview().ignoresSafeArea()
}

#Preview("Toolbar Demo - Dark") {
    ToolbarDemoPreview().ignoresSafeArea().preferredColorScheme(.dark)
}

#Preview("Simple Toolbar") {
    SimpleToolbarPreview().ignoresSafeArea()
}

#Preview("Ultra Minimal Mode") {
    UltraMinimalPreview().ignoresSafeArea()
}

#Preview("Custom Layout") {
    CustomLayoutPreview().ignoresSafeArea()
}

#Preview("8 Items Compression") {
    ManyItemsPreview().ignoresSafeArea()
}

#Preview("Global Accessory Provider") {
    GlobalAccessoryPreview().ignoresSafeArea()
}

#Preview("Dynamic Side Button") {
    DynamicSideButtonPreview().ignoresSafeArea()
}

#Preview("Swipe Gesture") {
    SwipeGesturePreview().ignoresSafeArea()
}

#Preview("Compression Debug") {
    CompressionDebugPreview().ignoresSafeArea()
}

#Preview("Accessory Width (iPad)") {
    AccessoryWidthPreview().ignoresSafeArea()
}

// MARK: - UIColor Extension

extension UIColor {
    /// Calculate the luminance of the color (0 = dark, 1 = light)
    var luminance: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0.5
        }

        // Standard luminance formula
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
}
