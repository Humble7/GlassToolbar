//
//  ToolbarStateCoordinator.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - StateTransition

enum AccessoryStateTransition: Equatable, Sendable {
    case showPrimary
    case hidePrimary
    case showSecondary
    case hideSecondary
    case hideAll
    case none
}

// MARK: - ToolbarStateCoordinatorDelegate

@MainActor
protocol ToolbarStateCoordinatorDelegate: AnyObject {
    var currentSelectedIndex: Int { get }
    var currentPrimaryAccessoryView: UIView? { get }
    var currentPrimaryAccessoryProvider: GlassAccessoryProvider? { get }
    var currentSecondaryAccessoryView: UIView? { get }
    var currentSecondaryAccessoryProvider: GlassAccessoryProvider? { get }

    func stateCoordinator(_ coordinator: ToolbarStateCoordinator, performTransition transition: AccessoryStateTransition, animated: Bool)
}

// MARK: - ToolbarStateCoordinator

/// Manages accessory display state for each item and handles state machine logic
@MainActor
final class ToolbarStateCoordinator {

    // MARK: - Properties

    weak var delegate: ToolbarStateCoordinatorDelegate?
    private var accessoryStates: [Int: AccessoryItemState] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - State Access

    func accessoryState(for index: Int) -> AccessoryItemState {
        return accessoryStates[index] ?? AccessoryItemState()
    }

    func updateAccessoryState(for index: Int, _ update: (inout AccessoryItemState) -> Void) {
        var state = accessoryState(for: index)
        update(&state)
        accessoryStates[index] = state
    }

    var currentDisplayState: AccessoryDisplayState {
        get {
            guard let delegate = delegate else { return .primaryOnly }
            return accessoryState(for: delegate.currentSelectedIndex).displayState
        }
        set {
            guard let delegate = delegate else { return }
            updateAccessoryState(for: delegate.currentSelectedIndex) { $0.displayState = newValue }
        }
    }

    var isPrimaryExpanded: Bool {
        get { currentDisplayState.showsPrimary }
        set {
            if newValue && !currentDisplayState.showsPrimary {
                currentDisplayState = .primaryOnly
            } else if !newValue {
                currentDisplayState = .collapsed
            }
        }
    }

    var isSecondaryExpanded: Bool {
        get { currentDisplayState.showsSecondary }
        set {
            if newValue && currentDisplayState == .primaryOnly {
                currentDisplayState = .primaryAndSecondary
            } else if !newValue && currentDisplayState == .primaryAndSecondary {
                currentDisplayState = .primaryOnly
            }
        }
    }

    var hasSecondaryBeenShown: Bool {
        get {
            guard let delegate = delegate else { return false }
            return accessoryState(for: delegate.currentSelectedIndex).secondaryShownInCycle
        }
        set {
            guard let delegate = delegate else { return }
            updateAccessoryState(for: delegate.currentSelectedIndex) { $0.secondaryShownInCycle = newValue }
        }
    }

    // MARK: - State Transitions

    func handleSameItemTap(animated: Bool = true) {
        guard let delegate = delegate else { return }

        let hasAccessory = delegate.currentPrimaryAccessoryView != nil
        let hasSecondaryAccessory = delegate.currentSecondaryAccessoryView != nil

        guard hasAccessory else { return }

        let previousState = currentDisplayState
        updateAccessoryState(for: delegate.currentSelectedIndex) { state in
            state.handleTap(hasSecondary: hasSecondaryAccessory)
        }
        let newState = currentDisplayState

        let transition = calculateTransition(from: previousState, to: newState)
        delegate.stateCoordinator(self, performTransition: transition, animated: animated)
    }

    private func calculateTransition(from previousState: AccessoryDisplayState, to newState: AccessoryDisplayState) -> AccessoryStateTransition {
        switch (previousState, newState) {
        case (.collapsed, .primaryOnly):
            return .showPrimary

        case (.primaryOnly, .primaryAndSecondary):
            return .showSecondary

        case (.primaryAndSecondary, .primaryOnly):
            return .hideSecondary

        case (.primaryOnly, .collapsed):
            return .hidePrimary

        case (.primaryAndSecondary, .collapsed):
            return .hideAll

        default:
            return .none
        }
    }

    // MARK: - State Management for Item Changes

    func prepareForItemChange(to newIndex: Int, hasAccessory: Bool, hasSecondary: Bool) -> (showPrimary: Bool, showSecondaryWithDelay: Bool) {
        let state = accessoryState(for: newIndex)

        if hasAccessory && state.displayState.showsPrimary {
            let showSecondary = hasSecondary && state.displayState.showsSecondary
            return (showPrimary: true, showSecondaryWithDelay: showSecondary)
        }

        return (showPrimary: false, showSecondaryWithDelay: false)
    }

    // MARK: - Reset

    func resetAllStates() {
        accessoryStates.removeAll()
    }

    func resetState(for index: Int) {
        accessoryStates[index] = nil
    }
}
