//
//  DemoAccessoryView.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit
import GlassToolbar

// MARK: - MiniPlayerAccessoryView

class MiniPlayerAccessoryView: UIView {

    // MARK: - Properties

    var onTap: (() -> Void)?
    var onPlayPause: ((Bool) -> Void)?
    private var isPlaying: Bool = false

    // MARK: - UI Components

    private let artworkView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemIndigo
        iv.layer.cornerRadius = 5
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false

        let noteIcon = UIImageView(image: UIImage(systemName: "music.note"))
        noteIcon.tintColor = .white.withAlphaComponent(0.8)
        noteIcon.translatesAutoresizingMaskIntoConstraints = false
        iv.addSubview(noteIcon)
        NSLayoutConstraint.activate([
            noteIcon.centerXAnchor.constraint(equalTo: iv.centerXAnchor),
            noteIcon.centerYAnchor.constraint(equalTo: iv.centerYAnchor),
            noteIcon.widthAnchor.constraint(equalToConstant: 16),
            noteIcon.heightAnchor.constraint(equalToConstant: 16)
        ])

        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Now Playing"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.text = "Artist"
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

    deinit {
        onTap = nil
        onPlayPause = nil
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(artworkView)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)

        let buttonStack = UIStackView(arrangedSubviews: [playButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            artworkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            artworkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            artworkView.widthAnchor.constraint(equalToConstant: 36),
            artworkView.heightAnchor.constraint(equalToConstant: 36),

            textStack.leadingAnchor.constraint(equalTo: artworkView.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: -10),

            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            playButton.widthAnchor.constraint(equalToConstant: 24),
            playButton.heightAnchor.constraint(equalToConstant: 24),
            nextButton.widthAnchor.constraint(equalToConstant: 24),
            nextButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        playButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods

    func configure(title: String, artist: String, artwork: UIImage? = nil) {
        titleLabel.text = title
        artistLabel.text = artist
        if let artwork = artwork {
            artworkView.image = artwork
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTap?()
    }

    @objc private func playPauseTapped() {
        isPlaying.toggle()
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        UIView.transition(with: playButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.playButton.setImage(UIImage(systemName: imageName), for: .normal)
        }

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        onPlayPause?(isPlaying)
    }

    @objc private func nextTapped() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
}

// MARK: - QuickActionAccessoryView

class QuickActionAccessoryView: UIView {

    // MARK: - Properties

    var onAction: ((Int) -> Void)?

    deinit {
        onAction = nil
    }

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(actions: [(icon: UIImage?, title: String)]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, action) in actions.enumerated() {
            let button = createActionButton(icon: action.icon, title: action.title, tag: index)
            stackView.addArrangedSubview(button)
        }
    }

    private func createActionButton(icon: UIImage?, title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag

        var config = UIButton.Configuration.plain()
        config.image = icon
        config.title = title
        config.imagePadding = 6
        config.baseForegroundColor = .label
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            return outgoing
        }

        button.configuration = config
        button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func actionTapped(_ sender: UIButton) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        onAction?(sender.tag)
    }
}

// MARK: - StatusAccessoryView

class StatusAccessoryView: UIView {

    // MARK: - UI Components

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGreen
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        addSubview(indicatorView)
        addSubview(iconImageView)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),

            indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 8),
            indicatorView.heightAnchor.constraint(equalToConstant: 8),

            iconImageView.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: 10),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])

        startIndicatorAnimation()
    }

    // MARK: - Public Methods

    func configure(icon: UIImage?, title: String, subtitle: String, statusColor: UIColor = .systemGreen) {
        iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = statusColor
        titleLabel.text = title
        subtitleLabel.text = subtitle
        indicatorView.backgroundColor = statusColor
    }

    private func startIndicatorAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse]) {
            self.indicatorView.alpha = 0.4
        }
    }
}

// MARK: - ProgressAccessoryView

class ProgressAccessoryView: UIView {

    // MARK: - Properties

    var progress: Float = 0 {
        didSet { updateProgress() }
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.trackTintColor = .systemGray5
        view.progressTintColor = .systemBlue
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        addSubview(titleLabel)
        addSubview(progressView)
        addSubview(percentLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 36),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -8),

            percentLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            percentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            percentLabel.widthAnchor.constraint(equalToConstant: 40),

            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    // MARK: - Public Methods

    func configure(title: String, progress: Float, color: UIColor = .systemBlue) {
        titleLabel.text = title
        progressView.progressTintColor = color
        self.progress = progress
    }

    private func updateProgress() {
        progressView.setProgress(progress, animated: true)
        percentLabel.text = "\(Int(progress * 100))%"
    }
}

// MARK: - DualSliderAccessoryView

class DualSliderAccessoryView: UIView {

    // MARK: - Properties

    var onSlider1Changed: ((Float) -> Void)?
    var onSlider2Changed: ((Float) -> Void)?

    deinit {
        onSlider1Changed = nil
        onSlider2Changed = nil
    }

    // MARK: - UI Components

    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var circleWidthConstraint: NSLayoutConstraint?
    private var circleHeightConstraint: NSLayoutConstraint?

    private let minCircleSize: CGFloat = 8
    private let maxCircleSize: CGFloat = 28

    private let slider1Container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let slider2Container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel1: UILabel = {
        let label = UILabel()
        label.text = "Size"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let titleLabel2: UILabel = {
        let label = UILabel()
        label.text = "Alpha"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let slider1: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .systemGray4
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        slider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return slider
    }()

    private let slider2: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.7
        slider.minimumTrackTintColor = .systemOrange
        slider.maximumTrackTintColor = .systemGray4
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
        slider.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return slider
    }()

    private let value1Label: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let value2Label: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
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
        addSubview(circleView)
        addSubview(slider1Container)
        addSubview(slider2Container)

        slider1Container.addSubview(titleLabel1)
        slider1Container.addSubview(slider1)
        slider1Container.addSubview(value1Label)

        slider2Container.addSubview(titleLabel2)
        slider2Container.addSubview(slider2)
        slider2Container.addSubview(value2Label)

        let initialSize = minCircleSize + (maxCircleSize - minCircleSize) * CGFloat(slider1.value)

        let widthConstraint = circleView.widthAnchor.constraint(equalToConstant: initialSize)
        let heightConstraint = circleView.heightAnchor.constraint(equalToConstant: initialSize)
        circleWidthConstraint = widthConstraint
        circleHeightConstraint = heightConstraint

        let value1Width = value1Label.widthAnchor.constraint(equalToConstant: 30)
        let value2Width = value2Label.widthAnchor.constraint(equalToConstant: 30)
        let slider1ContainerHeight = slider1Container.heightAnchor.constraint(equalToConstant: 22)
        let slider2ContainerHeight = slider2Container.heightAnchor.constraint(equalToConstant: 22)

        let slider1Leading = slider1.leadingAnchor.constraint(equalTo: titleLabel1.trailingAnchor, constant: 8)
        let slider1Trailing = slider1.trailingAnchor.constraint(equalTo: value1Label.leadingAnchor, constant: -4)
        let slider2Leading = slider2.leadingAnchor.constraint(equalTo: titleLabel2.trailingAnchor, constant: 8)
        let slider2Trailing = slider2.trailingAnchor.constraint(equalTo: value2Label.leadingAnchor, constant: -4)

        let slider1ContainerTop = slider1Container.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 4)
        let slider2ContainerTop = slider2Container.topAnchor.constraint(equalTo: slider1Container.bottomAnchor, constant: 2)
        let slider2ContainerBottom = slider2Container.bottomAnchor.constraint(equalTo: bottomAnchor)

        let breakableConstraints = [
            widthConstraint, heightConstraint,
            value1Width, value2Width,
            slider1ContainerHeight, slider2ContainerHeight,
            slider1Leading, slider1Trailing, slider2Leading, slider2Trailing,
            slider1ContainerTop, slider2ContainerTop, slider2ContainerBottom
        ]
        breakableConstraints.forEach { $0.priority = .defaultHigh }

        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: topAnchor),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            widthConstraint,
            heightConstraint,

            slider1ContainerTop,
            slider1Container.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider1Container.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider1ContainerHeight,

            slider2ContainerTop,
            slider2Container.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider2Container.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider2ContainerHeight,
            slider2ContainerBottom,

            titleLabel1.leadingAnchor.constraint(equalTo: slider1Container.leadingAnchor),
            titleLabel1.centerYAnchor.constraint(equalTo: slider1Container.centerYAnchor),

            slider1Leading,
            slider1.centerYAnchor.constraint(equalTo: slider1Container.centerYAnchor),
            slider1Trailing,

            value1Label.trailingAnchor.constraint(equalTo: slider1Container.trailingAnchor),
            value1Label.centerYAnchor.constraint(equalTo: slider1Container.centerYAnchor),
            value1Width,

            titleLabel2.leadingAnchor.constraint(equalTo: slider2Container.leadingAnchor),
            titleLabel2.centerYAnchor.constraint(equalTo: slider2Container.centerYAnchor),

            slider2Leading,
            slider2.centerYAnchor.constraint(equalTo: slider2Container.centerYAnchor),
            slider2Trailing,

            value2Label.trailingAnchor.constraint(equalTo: slider2Container.trailingAnchor),
            value2Label.centerYAnchor.constraint(equalTo: slider2Container.centerYAnchor),
            value2Width
        ])

        slider1.addTarget(self, action: #selector(slider1Changed), for: .valueChanged)
        slider2.addTarget(self, action: #selector(slider2Changed), for: .valueChanged)

        updateValueLabels()
        updateCircleAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.width / 2
    }

    // MARK: - Public Methods

    func configure(
        icon1: UIImage? = nil,
        icon2: UIImage? = nil,
        value1: Float = 0.5,
        value2: Float = 0.7,
        color1: UIColor = .systemBlue,
        color2: UIColor = .systemOrange,
        circleColor: UIColor = .systemRed
    ) {
        // icon1 and icon2 parameters are deprecated, kept for backward compatibility
        slider1.value = value1
        slider2.value = value2
        slider1.minimumTrackTintColor = color1
        slider2.minimumTrackTintColor = color2
        circleView.backgroundColor = circleColor
        updateValueLabels()
        updateCircleAppearance()
    }

    /// Update circle preview color (for syncing with side button color)
    func updateCircleColor(_ color: UIColor) {
        circleView.backgroundColor = color
    }

    /// Update all colors (circle, sliders) to sync with brush color
    func updateBrushColor(_ color: UIColor) {
        circleView.backgroundColor = color
        slider1.minimumTrackTintColor = color
        slider2.minimumTrackTintColor = color
    }

    // MARK: - Actions

    @objc private func slider1Changed() {
        updateValueLabels()
        updateCircleSize()
        onSlider1Changed?(slider1.value)

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred(intensity: 0.3)
    }

    @objc private func slider2Changed() {
        updateValueLabels()
        updateCircleAlpha()
        onSlider2Changed?(slider2.value)

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred(intensity: 0.3)
    }

    private func updateValueLabels() {
        value1Label.text = "\(Int(slider1.value * 100))%"
        value2Label.text = "\(Int(slider2.value * 100))%"
    }

    private func updateCircleAppearance() {
        updateCircleSize()
        updateCircleAlpha()
    }

    private func updateCircleSize() {
        let newSize = minCircleSize + (maxCircleSize - minCircleSize) * CGFloat(slider1.value)

        circleWidthConstraint?.constant = newSize
        circleHeightConstraint?.constant = newSize

        UIView.animate(withDuration: 0.1) {
            self.circleView.layer.cornerRadius = newSize / 2
            self.layoutIfNeeded()
        }
    }

    private func updateCircleAlpha() {
        let newAlpha = 0.2 + 0.8 * CGFloat(slider2.value)

        UIView.animate(withDuration: 0.1) {
            self.circleView.alpha = newAlpha
        }
    }
}

// MARK: - FavoritesListAccessoryView

class FavoritesListAccessoryView: UIView {

    // MARK: - Types

    struct FavoriteItem {
        let icon: UIImage?
        let title: String
        let color: UIColor
    }

    // MARK: - Properties

    var onItemTap: ((Int) -> Void)?
    private var items: [FavoriteItem] = []

    deinit {
        onItemTap = nil
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
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Favorites"
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
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.alignment = .leading
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleStack)
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60),

            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleStack.widthAnchor.constraint(equalToConstant: 40),

            scrollView.leadingAnchor.constraint(equalTo: titleStack.trailingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(title: String, items: [FavoriteItem]) {
        self.items = items
        titleLabel.text = title
        countLabel.text = "(\(items.count))"

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, item) in items.enumerated() {
            let itemView = createFavoriteItemView(item: item, index: index)
            stackView.addArrangedSubview(itemView)
        }
    }

    private func createFavoriteItemView(item: FavoriteItem, index: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconBackground = UIView()
        iconBackground.backgroundColor = item.color.withAlphaComponent(0.15)
        iconBackground.layer.cornerRadius = 10
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconBackground)

        let iconView = UIImageView(image: item.icon?.withRenderingMode(.alwaysTemplate))
        iconView.tintColor = item.color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 52),

            iconBackground.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            iconBackground.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 36),
            iconBackground.heightAnchor.constraint(equalToConstant: 36),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -2)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = index
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func itemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }

        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        }

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        onItemTap?(view.tag)
    }
}

// MARK: - HorizontalListAccessoryView

class HorizontalListAccessoryView: UIView {

    // MARK: - Types

    struct ListItem {
        let icon: UIImage?
        let title: String
        let tintColor: UIColor

        init(icon: UIImage?, title: String, tintColor: UIColor = .label) {
            self.icon = icon
            self.title = title
            self.tintColor = tintColor
        }
    }

    // MARK: - Configuration

    struct Configuration {
        var showsSelection: Bool = true
        var showsCount: Bool = true
        var selectionColor: UIColor = .label
        var borderColor: UIColor?  // nil = use selectionColor

        var effectiveBorderColor: UIColor {
            borderColor ?? selectionColor
        }

        static let `default` = Configuration()
        static let noSelection = Configuration(showsSelection: false, showsCount: false)
    }

    // MARK: - Properties

    var onItemTap: ((Int) -> Void)?
    private var items: [ListItem] = []
    private var selectedIndex: Int = 0
    private var configuration: Configuration = .default

    deinit {
        onItemTap = nil
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

    func configure(
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

    /// Update the selection color and refresh the list
    func updateSelectionColor(_ color: UIColor) {
        configuration.selectionColor = color
        let currentTitle = titleLabel.text ?? ""
        configure(title: currentTitle, items: items, selectedIndex: selectedIndex, configuration: configuration)
    }

    /// Update only the border color and refresh the list
    func updateBorderColor(_ color: UIColor) {
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

// MARK: - Protocol Conformance

extension MiniPlayerAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 44 }

    func cleanup() {
        onTap = nil
        onPlayPause = nil
    }
}

extension QuickActionAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 44 }

    func cleanup() {
        onAction = nil
    }
}

extension StatusAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 36 }
}

extension ProgressAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 36 }
}

extension DualSliderAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 80 }

    func cleanup() {
        onSlider1Changed = nil
        onSlider2Changed = nil
    }
}

extension FavoritesListAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 60 }

    func cleanup() {
        onItemTap = nil
    }
}

extension HorizontalListAccessoryView: GlassAccessoryProvider {
    var accessoryView: UIView { self }
    var preferredHeight: CGFloat { 64 }

    func cleanup() {
        onItemTap = nil
    }
}
