//
//  GlassAccessoryProvider.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - Accessory Provider Protocol

/// Accessory view provider protocol
@MainActor
public protocol GlassAccessoryProvider: AnyObject {

    // MARK: - View

    var accessoryView: UIView { get }

    // MARK: - Size

    var preferredHeight: CGFloat { get }
    var preferredWidth: CGFloat? { get }
    var minimumWidth: CGFloat { get }

    // MARK: - Lifecycle

    func willAppear(animated: Bool)
    func didAppear(animated: Bool)
    func willDisappear(animated: Bool)
    func didDisappear(animated: Bool)

    // MARK: - Memory Management

    func cleanup()
}

// MARK: - Default Implementations

public extension GlassAccessoryProvider {
    var preferredWidth: CGFloat? { nil }
    var minimumWidth: CGFloat { 100 }
    func willAppear(animated: Bool) {}
    func didAppear(animated: Bool) {}
    func willDisappear(animated: Bool) {}
    func didDisappear(animated: Bool) {}
    func cleanup() {}
}

// MARK: - UIView Conformance Helper

/// Wraps any UIView as a simple Accessory Provider
@MainActor
public final class SimpleAccessoryWrapper: GlassAccessoryProvider {

    public let accessoryView: UIView
    public let preferredHeight: CGFloat
    public let preferredWidth: CGFloat?
    public let minimumWidth: CGFloat

    private var cleanupHandler: (@MainActor () -> Void)?

    public init(
        view: UIView,
        preferredHeight: CGFloat = 44,
        preferredWidth: CGFloat? = nil,
        minimumWidth: CGFloat = 100,
        cleanup: (@MainActor () -> Void)? = nil
    ) {
        self.accessoryView = view
        self.preferredHeight = preferredHeight
        self.preferredWidth = preferredWidth
        self.minimumWidth = minimumWidth
        self.cleanupHandler = cleanup
    }

    public func cleanup() {
        cleanupHandler?()
        cleanupHandler = nil
    }
}

// MARK: - Convenience Extension for UIView

public extension UIView {

    @MainActor
    func asAccessoryProvider(
        height: CGFloat = 44,
        width: CGFloat? = nil,
        cleanup: (@MainActor () -> Void)? = nil
    ) -> GlassAccessoryProvider {
        return SimpleAccessoryWrapper(
            view: self,
            preferredHeight: height,
            preferredWidth: width,
            cleanup: cleanup
        )
    }
}

// MARK: - Accessory Provider Container

/// Container for managing multiple providers' lifecycle
@MainActor
public final class AccessoryProviderContainer {

    private var providers: [GlassAccessoryProvider] = []

    public init() {}

    public func add(_ provider: GlassAccessoryProvider) {
        providers.append(provider)
    }

    public func removeAll() {
        providers.forEach { $0.cleanup() }
        providers.removeAll()
    }

    public func notifyWillAppear(animated: Bool) {
        providers.forEach { $0.willAppear(animated: animated) }
    }

    public func notifyDidAppear(animated: Bool) {
        providers.forEach { $0.didAppear(animated: animated) }
    }

    public func notifyWillDisappear(animated: Bool) {
        providers.forEach { $0.willDisappear(animated: animated) }
    }

    public func notifyDidDisappear(animated: Bool) {
        providers.forEach { $0.didDisappear(animated: animated) }
    }

    public func cleanup() {
        providers.forEach { $0.cleanup() }
    }

    deinit {
        MainActor.assumeIsolated {
            cleanup()
        }
    }
}
