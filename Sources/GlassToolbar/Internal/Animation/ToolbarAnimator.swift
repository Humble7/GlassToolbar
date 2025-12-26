//
//  ToolbarAnimator.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - Animation Identifier

enum ToolbarAnimationType: String, CaseIterable, Sendable {
    case accessoryShow
    case accessoryHide
    case secondaryAccessoryShow
    case secondaryAccessoryHide
    case floatingButtonShow
    case floatingButtonHide
    case floatingButtonTap
    case toolbarLayout
    case sideButtonTransition
}

// MARK: - Animation Configuration

struct ToolbarAnimationConfig: Sendable {
    let duration: TimeInterval
    let dampingRatio: CGFloat
    let initialVelocity: CGFloat
    let delay: TimeInterval
    let options: UIView.AnimationOptions

    static func spring(
        duration: TimeInterval = 0.45,
        damping: CGFloat = 0.75,
        velocity: CGFloat = 0.8
    ) -> ToolbarAnimationConfig {
        ToolbarAnimationConfig(
            duration: duration,
            dampingRatio: damping,
            initialVelocity: velocity,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        )
    }

    static func easeOut(
        duration: TimeInterval = 0.3,
        damping: CGFloat = 0.9
    ) -> ToolbarAnimationConfig {
        ToolbarAnimationConfig(
            duration: duration,
            dampingRatio: damping,
            initialVelocity: 0.5,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut]
        )
    }

    static func quick(duration: TimeInterval = 0.15) -> ToolbarAnimationConfig {
        ToolbarAnimationConfig(
            duration: duration,
            dampingRatio: 1.0,
            initialVelocity: 0,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut]
        )
    }

    static let tapFeedback = ToolbarAnimationConfig(
        duration: 0.1,
        dampingRatio: 1.0,
        initialVelocity: 0,
        delay: 0,
        options: [.beginFromCurrentState]
    )

    static let bounce = ToolbarAnimationConfig(
        duration: 0.2,
        dampingRatio: 0.5,
        initialVelocity: 0.5,
        delay: 0,
        options: [.beginFromCurrentState]
    )
}

// MARK: - Toolbar Animator

/// Manages all interruptible animations with pause, resume and reverse support
@MainActor
final class ToolbarAnimator {

    // MARK: - Properties

    private var runningAnimators: [ToolbarAnimationType: UIViewPropertyAnimator] = [:]
    private var completionHandlers: [ToolbarAnimationType: [(Bool) -> Void]] = [:]
    var debugLoggingEnabled: Bool = false

    // MARK: - Initialization

    init() {}

    deinit {
        MainActor.assumeIsolated {
            for (type, animator) in runningAnimators {
                if animator.isRunning {
                    animator.stopAnimation(true)
                }
                completionHandlers[type] = nil
            }
            runningAnimators.removeAll()
            completionHandlers.removeAll()
        }
    }

    // MARK: - Animation Execution

    @discardableResult
    func animate(
        _ type: ToolbarAnimationType,
        config: ToolbarAnimationConfig = .spring(),
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {

        interruptAnimation(type)

        let animator = UIViewPropertyAnimator(
            duration: config.duration,
            dampingRatio: config.dampingRatio,
            animations: animations
        )

        if let completion = completion {
            if completionHandlers[type] == nil {
                completionHandlers[type] = []
            }
            completionHandlers[type]?.append(completion)
        }

        animator.addCompletion { [weak self] position in
            guard let self = self else { return }

            let finished = (position == .end)

            if self.debugLoggingEnabled {
                print("[ToolbarAnimator] \(type.rawValue) completed: \(finished ? "finished" : "interrupted")")
            }

            self.completionHandlers[type]?.forEach { $0(finished) }
            self.completionHandlers[type] = nil
            self.runningAnimators.removeValue(forKey: type)
        }

        runningAnimators[type] = animator

        if self.debugLoggingEnabled {
            print("[ToolbarAnimator] Starting \(type.rawValue)")
        }

        if config.delay > 0 {
            animator.startAnimation(afterDelay: config.delay)
        } else {
            animator.startAnimation()
        }

        return animator
    }

    func animateSequence(
        _ sequence: [(type: ToolbarAnimationType, config: ToolbarAnimationConfig, animations: () -> Void)],
        completion: ((Bool) -> Void)? = nil
    ) {
        guard !sequence.isEmpty else {
            completion?(true)
            return
        }

        var remaining = sequence
        let first = remaining.removeFirst()

        animate(first.type, config: first.config, animations: first.animations) { [weak self] finished in
            guard finished else {
                completion?(false)
                return
            }
            self?.animateSequence(remaining, completion: completion)
        }
    }

    // MARK: - Animation Control

    func interruptAnimation(_ type: ToolbarAnimationType) {
        guard let animator = runningAnimators[type] else { return }

        if animator.isRunning {
            if debugLoggingEnabled {
                print("[ToolbarAnimator] Interrupting \(type.rawValue)")
            }
            animator.stopAnimation(true)
        }

        runningAnimators.removeValue(forKey: type)
        completionHandlers[type] = nil
    }

    func cancelAllAnimations() {
        for (type, animator) in runningAnimators {
            if animator.isRunning {
                animator.stopAnimation(true)
            }
            completionHandlers[type] = nil
        }
        runningAnimators.removeAll()
        completionHandlers.removeAll()
    }

    func pauseAnimation(_ type: ToolbarAnimationType) {
        runningAnimators[type]?.pauseAnimation()
    }

    func resumeAnimation(_ type: ToolbarAnimationType) {
        guard let animator = runningAnimators[type] else { return }
        if animator.state == .active {
            animator.startAnimation()
        }
    }

    func reverseAnimation(_ type: ToolbarAnimationType) {
        runningAnimators[type]?.isReversed.toggle()
    }

    // MARK: - Animation State

    func isAnimating(_ type: ToolbarAnimationType) -> Bool {
        return runningAnimators[type]?.isRunning ?? false
    }

    var hasRunningAnimations: Bool {
        return runningAnimators.values.contains { $0.isRunning }
    }

    func fractionComplete(for type: ToolbarAnimationType) -> CGFloat {
        return runningAnimators[type]?.fractionComplete ?? 0
    }

    // MARK: - Interactive Animations

    func createInteractiveAnimator(
        _ type: ToolbarAnimationType,
        config: ToolbarAnimationConfig = .spring(),
        animations: @escaping () -> Void
    ) -> UIViewPropertyAnimator {

        interruptAnimation(type)

        let animator = UIViewPropertyAnimator(
            duration: config.duration,
            dampingRatio: config.dampingRatio,
            animations: animations
        )

        animator.pauseAnimation()
        runningAnimators[type] = animator

        return animator
    }

    func finishInteractiveAnimation(
        _ type: ToolbarAnimationType,
        at position: UIViewAnimatingPosition,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let animator = runningAnimators[type] else {
            completion?(false)
            return
        }

        if let completion = completion {
            if completionHandlers[type] == nil {
                completionHandlers[type] = []
            }
            completionHandlers[type]?.append(completion)
        }

        animator.continueAnimation(
            withTimingParameters: nil,
            durationFactor: 0
        )
    }
}

// MARK: - Convenience Extensions

extension ToolbarAnimator {

    func showFromBottom(
        _ view: UIView,
        type: ToolbarAnimationType,
        offset: CGFloat = 30,
        completion: ((Bool) -> Void)? = nil
    ) {
        view.transform = CGAffineTransform(translationX: 0, y: offset)
        view.alpha = 0
        view.isHidden = false

        animate(type, config: .spring(), animations: {
            view.transform = .identity
            view.alpha = 1
        }, completion: completion)
    }

    func hideToBottom(
        _ view: UIView,
        type: ToolbarAnimationType,
        offset: CGFloat = 30,
        completion: ((Bool) -> Void)? = nil
    ) {
        animate(type, config: .easeOut(), animations: {
            view.transform = CGAffineTransform(translationX: 0, y: offset)
            view.alpha = 0
        }, completion: { finished in
            if finished {
                view.isHidden = true
                view.transform = .identity
            }
            completion?(finished)
        })
    }

    func tapFeedback(
        _ view: UIView,
        type: ToolbarAnimationType = .floatingButtonTap,
        scale: CGFloat = 0.9,
        completion: ((Bool) -> Void)? = nil
    ) {
        animate(type, config: .tapFeedback, animations: {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { [weak self] _ in
            self?.animate(type, config: .bounce, animations: {
                view.transform = .identity
            }, completion: completion)
        })
    }

    func crossfade(
        from oldView: UIView?,
        to newView: UIView?,
        type: ToolbarAnimationType,
        completion: ((Bool) -> Void)? = nil
    ) {
        newView?.alpha = 0
        newView?.isHidden = false

        animate(type, config: .quick(), animations: {
            oldView?.alpha = 0
            newView?.alpha = 1
        }, completion: { finished in
            if finished {
                oldView?.isHidden = true
            }
            completion?(finished)
        })
    }
}
