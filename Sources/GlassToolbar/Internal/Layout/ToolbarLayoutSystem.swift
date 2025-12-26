//
//  ToolbarLayoutSystem.swift
//  GlassToolBar
//
//  Created by ChenZhen on 26/12/25.
//


import UIKit

// MARK: - Space Tier

/// Space tier - based on actual available width
public enum SpaceTier: Int, Comparable, CaseIterable, Sendable {
    case minimal = 0      // < 280pt - extreme cases
    case tight = 1        // 280-359pt - iPhone SE, very small split view
    case compact = 2      // 360-419pt - standard iPhone
    case regular = 3      // 420-519pt - iPad 1/2 split view
    case spacious = 4     // >= 520pt - iPad full screen

    public static func < (lhs: SpaceTier, rhs: SpaceTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Space tier threshold configuration
public struct SpaceTierThresholds: Sendable {
    public var spacious: CGFloat = 520
    public var regular: CGFloat = 420
    public var compact: CGFloat = 360
    public var tight: CGFloat = 280

    public init(
        spacious: CGFloat = 520,
        regular: CGFloat = 420,
        compact: CGFloat = 360,
        tight: CGFloat = 280
    ) {
        self.spacious = spacious
        self.regular = regular
        self.compact = compact
        self.tight = tight
    }

    public static let `default` = SpaceTierThresholds()

    public func tier(for width: CGFloat) -> SpaceTier {
        if width >= spacious { return .spacious }
        if width >= regular { return .regular }
        if width >= compact { return .compact }
        if width >= tight { return .tight }
        return .minimal
    }
}

// MARK: - Compression Level

/// Compression level - determines how toolbar items are displayed
public enum CompressionLevel: Int, Comparable, CaseIterable, Sendable {
    case full = 0           // Full display + title
    case comfortable = 1    // Full display, standard spacing
    case compact = 2        // Compact spacing
    case iconOnly = 3       // Icon only
    case overflow = 4       // Some items in overflow

    public static func < (lhs: CompressionLevel, rhs: CompressionLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Item Priority

/// Item priority - determines compression order
public enum ItemPriority: Int, Comparable, Sendable {
    case essential = 0      // Always visible, never hidden
    case primary = 1        // Shown preferentially, can compress when space is extremely limited
    case secondary = 2      // Hidden first / moved to overflow when space is limited
    case overflow = 3       // Default in overflow menu

    public static func < (lhs: ItemPriority, rhs: ItemPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Side Button Priority

/// Side button priority
public enum SideButtonPriority: Int, Comparable, Sendable {
    case essential = 0      // Always visible, cannot be hidden
    case primary = 1        // Shown preferentially, can merge/move in extreme cases
    case secondary = 2      // Can be hidden when space is limited

    public static func < (lhs: SideButtonPriority, rhs: SideButtonPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Item Display Mode

/// Item display mode
public enum ItemDisplayMode: Equatable, Sendable {
    case full               // Icon + title
    case compactTitle       // Icon + short title
    case iconOnly           // Icon only
    case hidden             // Hidden (in overflow)
}

// MARK: - Side Button Display Mode

/// Side button display mode
public enum SideButtonDisplayMode: Equatable, Sendable {
    case full(size: CGFloat, spacing: CGFloat)    // Full display
    case compact(size: CGFloat, spacing: CGFloat) // Compact display
    case integrated         // Merged into toolbar
    case hidden             // Hidden (due to space constraints, in overflow)
    case none               // No side button configured
}

// MARK: - Layout Application

/// Layout application parameters - unified interface for ToolbarLayoutResult and UltraMinimalLayoutResult
public struct ToolbarLayoutApplication: Sendable {
    /// Item display modes
    public let itemDisplayModes: [Int: ItemDisplayMode]
    /// Visible item indices
    public let visibleIndices: [Int]
    /// Item spacing
    public let itemSpacing: CGFloat
    /// Whether to show overflow button
    public let showOverflowButton: Bool
    /// Toolbar width
    public let toolbarWidth: CGFloat
    /// Side button display mode
    public let sideButtonMode: SideButtonDisplayMode
    /// Accessory width (nil means no update, used for ultra minimal mode)
    public let accessoryWidth: CGFloat?
    /// Compression level for indicator height
    public let compressionLevel: CompressionLevel

    public init(
        itemDisplayModes: [Int: ItemDisplayMode],
        visibleIndices: [Int],
        itemSpacing: CGFloat,
        showOverflowButton: Bool,
        toolbarWidth: CGFloat,
        sideButtonMode: SideButtonDisplayMode,
        accessoryWidth: CGFloat?,
        compressionLevel: CompressionLevel = .full
    ) {
        self.itemDisplayModes = itemDisplayModes
        self.visibleIndices = visibleIndices
        self.itemSpacing = itemSpacing
        self.showOverflowButton = showOverflowButton
        self.toolbarWidth = toolbarWidth
        self.sideButtonMode = sideButtonMode
        self.accessoryWidth = accessoryWidth
        self.compressionLevel = compressionLevel
    }
}

// MARK: - Layout Result

/// Layout calculation result
public struct ToolbarLayoutResult: Sendable {
    public let spaceTier: SpaceTier
    public let compressionLevel: CompressionLevel
    public let itemSpacing: CGFloat
    public let itemDisplayModes: [Int: ItemDisplayMode]
    public let visibleItemIndices: [Int]
    public let overflowItemIndices: [Int]
    public let sideButtonMode: SideButtonDisplayMode
    public let toolbarWidth: CGFloat
    public let accessoryWidth: CGFloat

    /// Whether overflow button is needed
    public var needsOverflowButton: Bool {
        !overflowItemIndices.isEmpty || sideButtonMode == .hidden
    }

    /// Convert to layout application parameters
    public func toApplicationParams() -> ToolbarLayoutApplication {
        ToolbarLayoutApplication(
            itemDisplayModes: itemDisplayModes,
            visibleIndices: visibleItemIndices,
            itemSpacing: itemSpacing,
            showOverflowButton: needsOverflowButton,
            toolbarWidth: toolbarWidth,
            sideButtonMode: sideButtonMode,
            accessoryWidth: accessoryWidth,
            compressionLevel: compressionLevel
        )
    }
}

// MARK: - Layout Configuration

/// Layout configuration
public struct ToolbarLayoutConfiguration: Sendable {
    // Space tier thresholds
    public var spaceTierThresholds: SpaceTierThresholds = .default

    // Spacing configuration
    public var itemSpacingFull: CGFloat = 16
    public var itemSpacingComfortable: CGFloat = 12
    public var itemSpacingCompact: CGFloat = 8
    public var itemSpacingMinimal: CGFloat = 4

    // Side button configuration
    public var sideButtonSizeFull: CGFloat = 52
    public var sideButtonSizeCompact: CGFloat = 44
    public var sideButtonSizeMinimal: CGFloat = 40
    public var sideButtonSpacingFull: CGFloat = 16
    public var sideButtonSpacingCompact: CGFloat = 16
    public var sideButtonSpacingTight: CGFloat = 16
    public var sideButtonSpacingMinimal: CGFloat = 8

    // Toolbar configuration
    public var toolbarPadding: CGFloat = 16
    public var toolbarHeight: CGFloat = 56
    public var itemMinWidth: CGFloat = 44
    public var itemFullWidth: CGFloat = 64

    // Accessory configuration
    public var accessoryMaxWidth: CGFloat = 400
    public var accessoryMinWidth: CGFloat = 200

    // Toolbar internal configuration
    public var toolbarInternalPadding: CGFloat = 24

    // Whether to enable overflow
    public var enableOverflow: Bool = true

    // Animation configuration
    public var animationDuration: TimeInterval = 0.3

    public init() {}

    public static let `default` = ToolbarLayoutConfiguration()
}

// MARK: - Layout Cache Key

/// Layout cache key - uniquely identifies layout calculation inputs
private struct LayoutCacheKey: Hashable {
    /// Container width (quantized to 10pt precision for better cache hit rate)
    let quantizedWidth: Int
    /// Number of items
    let itemCount: Int
    /// Whether side button exists
    let hasSideButton: Bool
    /// Whether accessory exists
    let hasAccessory: Bool
    /// Hash of item priorities (to detect item configuration changes)
    let itemsHash: Int

    init(
        containerWidth: CGFloat,
        items: [ToolbarItemLayoutInfo],
        sideButton: SideButtonLayoutInfo?,
        hasAccessory: Bool
    ) {
        // Quantize width to 10pt precision to reduce cache fragmentation
        self.quantizedWidth = Int(containerWidth / 10) * 10
        self.itemCount = items.count
        self.hasSideButton = sideButton != nil
        self.hasAccessory = hasAccessory
        // Calculate hash of item configuration
        var hasher = Hasher()
        for item in items {
            hasher.combine(item.index)
            hasher.combine(item.priority)
            hasher.combine(item.canHideTitle)
        }
        self.itemsHash = hasher.finalize()
    }
}

// MARK: - Layout Cache Entry

/// Layout cache entry
private struct LayoutCacheEntry {
    let result: ToolbarLayoutResult
    let timestamp: Date
    let exactWidth: CGFloat  // Store exact width for validation
}

// MARK: - Toolbar Layout Coordinator

/// Toolbar layout coordinator - unified calculation of Toolbar, Side Button, and Accessory layout
/// Marked @MainActor to ensure all layout calculations run on main thread, avoiding race conditions
@MainActor
public class ToolbarLayoutCoordinator {

    // MARK: - Properties

    public var configuration: ToolbarLayoutConfiguration {
        didSet {
            // Clear cache when configuration changes
            invalidateCache()
        }
    }

    // MARK: - Cache Properties

    /// Layout cache (key: cache key, value: cache entry)
    private var layoutCache: [LayoutCacheKey: LayoutCacheEntry] = [:]

    /// Maximum cache entries
    private let maxCacheEntries: Int = 10

    /// Cache expiration interval (seconds)
    private let cacheExpirationInterval: TimeInterval = 60

    /// Cache statistics
    private(set) var cacheHits: Int = 0
    private(set) var cacheMisses: Int = 0

    /// Last layout result (for quick access)
    private var lastContainerWidth: CGFloat = 0
    private var lastLayoutResult: ToolbarLayoutResult?

    // MARK: - Initialization

    public init(configuration: ToolbarLayoutConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Cache Management

    /// Clear layout cache
    public func invalidateCache() {
        layoutCache.removeAll()
        lastLayoutResult = nil
        lastContainerWidth = 0
    }

    /// Clean expired cache entries
    private func cleanExpiredCacheEntries() {
        let now = Date()
        layoutCache = layoutCache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < cacheExpirationInterval
        }
    }

    /// Evict oldest entries if cache is too large
    private func evictOldestEntriesIfNeeded() {
        guard layoutCache.count > maxCacheEntries else { return }

        // Sort by timestamp and remove oldest entries
        let sortedEntries = layoutCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(layoutCache.count - maxCacheEntries)
        for (key, _) in entriesToRemove {
            layoutCache.removeValue(forKey: key)
        }
    }

    /// Try to get cached layout result
    private func getCachedLayout(for key: LayoutCacheKey, exactWidth: CGFloat) -> ToolbarLayoutResult? {
        guard let entry = layoutCache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(entry.timestamp) > cacheExpirationInterval {
            layoutCache.removeValue(forKey: key)
            return nil
        }

        // Validate exact width difference doesn't exceed quantization precision
        if abs(entry.exactWidth - exactWidth) > 10 {
            return nil
        }

        return entry.result
    }

    /// Store layout result in cache
    private func cacheLayout(_ result: ToolbarLayoutResult, for key: LayoutCacheKey, exactWidth: CGFloat) {
        // Clean expired entries first
        cleanExpiredCacheEntries()

        // Store new entry
        layoutCache[key] = LayoutCacheEntry(
            result: result,
            timestamp: Date(),
            exactWidth: exactWidth
        )

        // Evict old entries if cache is too large
        evictOldestEntriesIfNeeded()
    }

    // MARK: - Public Methods

    /// Calculate layout (with caching)
    public func calculateLayout(
        containerWidth: CGFloat,
        items: [ToolbarItemLayoutInfo],
        sideButton: SideButtonLayoutInfo?,
        hasAccessory: Bool
    ) -> ToolbarLayoutResult {

        // 0. Try to get from cache
        let cacheKey = LayoutCacheKey(
            containerWidth: containerWidth,
            items: items,
            sideButton: sideButton,
            hasAccessory: hasAccessory
        )

        if let cachedResult = getCachedLayout(for: cacheKey, exactWidth: containerWidth) {
            cacheHits += 1
            lastContainerWidth = containerWidth
            lastLayoutResult = cachedResult
            return cachedResult
        }

        cacheMisses += 1

        // 1. Calculate space tier
        let spaceTier = configuration.spaceTierThresholds.tier(for: containerWidth)

        // 2. Calculate side button layout
        var sideButtonMode = calculateSideButtonMode(
            spaceTier: spaceTier,
            sideButton: sideButton,
            containerWidth: containerWidth
        )

        // 3. Calculate toolbar available width (ensure non-negative)
        var sideButtonSpace = sideButtonSpaceRequired(mode: sideButtonMode)
        var toolbarAvailableWidth = max(0, containerWidth - configuration.toolbarPadding * 2 - sideButtonSpace)

        // 4. Calculate items layout
        var (compressionLevel, itemModes, visibleIndices, overflowIndices, itemSpacing) = calculateItemsLayout(
            availableWidth: toolbarAvailableWidth,
            items: items,
            spaceTier: spaceTier
        )

        // 5. Calculate actual toolbar width
        var toolbarWidth = calculateToolbarWidth(
            items: items,
            itemModes: itemModes,
            visibleIndices: visibleIndices,
            itemSpacing: itemSpacing,
            compressionLevel: compressionLevel,
            hasOverflow: !overflowIndices.isEmpty || sideButtonMode == .hidden
        )

        // 6. Overall width validation - ensure toolbar + side button doesn't exceed screen
        let totalWidth = toolbarWidth + sideButtonSpace
        let maxAllowedWidth = containerWidth - configuration.toolbarPadding * 2

        if totalWidth > maxAllowedWidth && sideButtonSpace > 0 {
            // Overall width exceeds, need to adjust

            // First try to shrink toolbar width
            let newToolbarWidth = maxAllowedWidth - sideButtonSpace
            if newToolbarWidth >= configuration.itemMinWidth * 2 {
                // Can fit by shrinking toolbar
                toolbarWidth = newToolbarWidth
            } else {
                // Still not enough space, hide side button
                sideButtonMode = .hidden
                sideButtonSpace = 0

                // Recalculate toolbar layout (now have more space)
                toolbarAvailableWidth = max(0, containerWidth - configuration.toolbarPadding * 2)

                let newLayout = calculateItemsLayout(
                    availableWidth: toolbarAvailableWidth,
                    items: items,
                    spaceTier: spaceTier
                )
                compressionLevel = newLayout.0
                itemModes = newLayout.1
                visibleIndices = newLayout.2
                overflowIndices = newLayout.3
                itemSpacing = newLayout.4

                // Recalculate toolbar width (side button now in overflow)
                toolbarWidth = calculateToolbarWidth(
                    items: items,
                    itemModes: itemModes,
                    visibleIndices: visibleIndices,
                    itemSpacing: itemSpacing,
                    compressionLevel: compressionLevel,
                    hasOverflow: true  // side button hidden, need overflow
                )
            }
        }

        // 7. Calculate accessory width
        let accessoryWidth = calculateAccessoryWidth(
            containerWidth: containerWidth,
            toolbarWidth: toolbarWidth,
            sideButtonMode: sideButtonMode,
            spaceTier: spaceTier
        )

        let result = ToolbarLayoutResult(
            spaceTier: spaceTier,
            compressionLevel: compressionLevel,
            itemSpacing: itemSpacing,
            itemDisplayModes: itemModes,
            visibleItemIndices: visibleIndices,
            overflowItemIndices: overflowIndices,
            sideButtonMode: sideButtonMode,
            toolbarWidth: toolbarWidth,
            accessoryWidth: accessoryWidth
        )

        // Store in cache
        cacheLayout(result, for: cacheKey, exactWidth: containerWidth)

        lastContainerWidth = containerWidth
        lastLayoutResult = result

        return result
    }

    /// Check if layout recalculation is needed
    public func shouldRecalculateLayout(newWidth: CGFloat, threshold: CGFloat = 10) -> Bool {
        guard let lastResult = lastLayoutResult else { return true }

        // Width change exceeds threshold
        if abs(newWidth - lastContainerWidth) > threshold {
            return true
        }

        // Check if space tier changed
        let newTier = configuration.spaceTierThresholds.tier(for: newWidth)
        if newTier != lastResult.spaceTier {
            return true
        }

        return false
    }

    // MARK: - Private Methods

    private func calculateSideButtonMode(
        spaceTier: SpaceTier,
        sideButton: SideButtonLayoutInfo?,
        containerWidth: CGFloat
    ) -> SideButtonDisplayMode {

        guard let sideButton = sideButton else {
            return .none  // No side button configured
        }

        switch spaceTier {
        case .spacious, .regular:
            return .full(
                size: configuration.sideButtonSizeFull,
                spacing: configuration.sideButtonSpacingFull
            )

        case .compact:
            return .full(
                size: configuration.sideButtonSizeFull,
                spacing: configuration.sideButtonSpacingCompact
            )

        case .tight:
            return .compact(
                size: configuration.sideButtonSizeCompact,
                spacing: configuration.sideButtonSpacingTight
            )

        case .minimal:
            switch sideButton.priority {
            case .essential:
                // Essential always visible, even when very compact
                return .compact(
                    size: configuration.sideButtonSizeMinimal,
                    spacing: configuration.sideButtonSpacingMinimal
                )
            case .primary:
                // Primary merged into toolbar
                return .integrated
            case .secondary:
                // Secondary hidden
                return .hidden
            }
        }
    }

    private func sideButtonSpaceRequired(mode: SideButtonDisplayMode) -> CGFloat {
        switch mode {
        case .full(let size, let spacing):
            return size + spacing
        case .compact(let size, let spacing):
            return size + spacing
        case .integrated, .hidden, .none:
            return 0
        }
    }

    private func calculateItemsLayout(
        availableWidth: CGFloat,
        items: [ToolbarItemLayoutInfo],
        spaceTier: SpaceTier
    ) -> (CompressionLevel, [Int: ItemDisplayMode], [Int], [Int], CGFloat) {

        // Indices sorted by priority
        let sortedIndices = items.indices.sorted { items[$0].priority < items[$1].priority }

        // Try different compression levels
        for level in CompressionLevel.allCases {
            let result = tryLayout(
                availableWidth: availableWidth,
                items: items,
                sortedIndices: sortedIndices,
                compressionLevel: level,
                spaceTier: spaceTier
            )

            if let result = result {
                return result
            }
        }

        // If all levels don't fit, return most aggressive compression
        return makeMinimalLayout(items: items, sortedIndices: sortedIndices, spaceTier: spaceTier)
    }

    private func tryLayout(
        availableWidth: CGFloat,
        items: [ToolbarItemLayoutInfo],
        sortedIndices: [Int],
        compressionLevel: CompressionLevel,
        spaceTier: SpaceTier
    ) -> (CompressionLevel, [Int: ItemDisplayMode], [Int], [Int], CGFloat)? {

        let spacing = itemSpacing(for: compressionLevel, spaceTier: spaceTier)
        var itemModes: [Int: ItemDisplayMode] = [:]
        var visibleIndices: [Int] = []
        var overflowIndices: [Int] = []
        var totalWidth: CGFloat = 0

        for index in 0..<items.count {
            let item = items[index]
            let mode = itemDisplayMode(for: item, compressionLevel: compressionLevel)

            // Overflow priority items go directly to overflow
            if item.priority == .overflow && configuration.enableOverflow {
                itemModes[index] = .hidden
                overflowIndices.append(index)
                continue
            }

            let itemWidth = itemWidth(for: item, mode: mode)
            let spacingNeeded = visibleIndices.isEmpty ? 0 : spacing

            if totalWidth + itemWidth + spacingNeeded <= availableWidth {
                itemModes[index] = mode
                visibleIndices.append(index)
                totalWidth += itemWidth + spacingNeeded
            } else if configuration.enableOverflow && item.priority > .essential {
                // Not enough space, go to overflow (except essential)
                itemModes[index] = .hidden
                overflowIndices.append(index)
            } else {
                // Cannot fit essential item, this compression level fails
                return nil
            }
        }

        // Check if need space for overflow button
        if !overflowIndices.isEmpty {
            let overflowButtonWidth = configuration.itemMinWidth
            if totalWidth + spacing + overflowButtonWidth > availableWidth {
                // Need to remove more items to make room for overflow button
                while !visibleIndices.isEmpty {
                    let lastIndex = visibleIndices.last!
                    let item = items[lastIndex]

                    if item.priority == .essential {
                        // Cannot remove essential
                        return nil
                    }

                    let removedWidth = itemWidth(for: item, mode: itemModes[lastIndex] ?? .iconOnly)
                    totalWidth -= removedWidth + (visibleIndices.count > 1 ? spacing : 0)

                    visibleIndices.removeLast()
                    overflowIndices.insert(lastIndex, at: 0)
                    itemModes[lastIndex] = .hidden

                    if totalWidth + spacing + overflowButtonWidth <= availableWidth {
                        break
                    }
                }
            }
        }

        return (compressionLevel, itemModes, visibleIndices, overflowIndices, spacing)
    }

    private func makeMinimalLayout(
        items: [ToolbarItemLayoutInfo],
        sortedIndices: [Int],
        spaceTier: SpaceTier
    ) -> (CompressionLevel, [Int: ItemDisplayMode], [Int], [Int], CGFloat) {

        var itemModes: [Int: ItemDisplayMode] = [:]
        var visibleIndices: [Int] = []
        var overflowIndices: [Int] = []

        for index in 0..<items.count {
            let item = items[index]
            if item.priority == .essential {
                itemModes[index] = .iconOnly
                visibleIndices.append(index)
            } else {
                itemModes[index] = .hidden
                overflowIndices.append(index)
            }
        }

        return (.overflow, itemModes, visibleIndices, overflowIndices, configuration.itemSpacingMinimal)
    }

    private func itemSpacing(for level: CompressionLevel, spaceTier: SpaceTier) -> CGFloat {
        // Get spacing based on compression level
        let compressionSpacing: CGFloat = switch level {
        case .full:
            configuration.itemSpacingFull
        case .comfortable:
            configuration.itemSpacingComfortable
        case .compact:
            configuration.itemSpacingCompact
        case .iconOnly, .overflow:
            configuration.itemSpacingMinimal
        }

        // Get spacing based on space tier
        let tierSpacing: CGFloat = switch spaceTier {
        case .spacious:
            configuration.itemSpacingFull
        case .regular:
            configuration.itemSpacingComfortable
        case .compact:
            configuration.itemSpacingCompact
        case .tight, .minimal:
            configuration.itemSpacingMinimal
        }

        // Use the smaller of the two (more constrained wins)
        return min(compressionSpacing, tierSpacing)
    }

    private func itemDisplayMode(for item: ToolbarItemLayoutInfo, compressionLevel: CompressionLevel) -> ItemDisplayMode {
        switch compressionLevel {
        case .full:
            return .full
        case .comfortable:
            return .full
        case .compact:
            return item.canHideTitle ? .compactTitle : .full
        case .iconOnly:
            return .iconOnly
        case .overflow:
            return .iconOnly
        }
    }

    private func itemWidth(for item: ToolbarItemLayoutInfo, mode: ItemDisplayMode) -> CGFloat {
        switch mode {
        case .full:
            return item.fullWidth ?? configuration.itemFullWidth
        case .compactTitle:
            return item.compactWidth ?? configuration.itemMinWidth + 8
        case .iconOnly:
            return configuration.itemMinWidth
        case .hidden:
            return 0
        }
    }

    private func calculateToolbarWidth(
        items: [ToolbarItemLayoutInfo],
        itemModes: [Int: ItemDisplayMode],
        visibleIndices: [Int],
        itemSpacing: CGFloat,
        compressionLevel: CompressionLevel,
        hasOverflow: Bool
    ) -> CGFloat {

        var width: CGFloat = 0

        for (i, index) in visibleIndices.enumerated() {
            let mode = itemModes[index] ?? .iconOnly
            width += itemWidth(for: items[index], mode: mode)
            if i < visibleIndices.count - 1 {
                width += itemSpacing
            }
        }

        // Add overflow button width
        if hasOverflow && configuration.enableOverflow {
            width += itemSpacing + configuration.itemMinWidth
        }

        // Add internal padding
        width += configuration.toolbarInternalPadding

        return width
    }

    private func calculateAccessoryWidth(
        containerWidth: CGFloat,
        toolbarWidth: CGFloat,
        sideButtonMode: SideButtonDisplayMode,
        spaceTier: SpaceTier
    ) -> CGFloat {
        // Base width follows toolbar width
        var width = toolbarWidth

        // Apply space tier specific rules
        switch spaceTier {
        case .spacious:
            // Large screens: cap at maxWidth to avoid overly wide accessory
            width = min(width, configuration.accessoryMaxWidth)
        case .regular, .compact:
            // Medium screens: follow toolbar width with max limit
            width = min(width, configuration.accessoryMaxWidth)
        case .tight:
            // Small screens: ensure minimum usable width
            width = max(width, configuration.accessoryMinWidth)
        case .minimal:
            // Ultra minimal: use minimum width or hide
            width = configuration.accessoryMinWidth
        }

        // Final clamp to ensure within bounds
        return max(configuration.accessoryMinWidth, min(width, configuration.accessoryMaxWidth))
    }
}

// MARK: - Layout Info Structs

/// Item layout info (for calculations)
public struct ToolbarItemLayoutInfo: Sendable {
    public let index: Int
    public let priority: ItemPriority
    public let canHideTitle: Bool
    public let fullWidth: CGFloat?
    public let compactWidth: CGFloat?

    public init(
        index: Int,
        priority: ItemPriority = .primary,
        canHideTitle: Bool = true,
        fullWidth: CGFloat? = nil,
        compactWidth: CGFloat? = nil
    ) {
        self.index = index
        self.priority = priority
        self.canHideTitle = canHideTitle
        self.fullWidth = fullWidth
        self.compactWidth = compactWidth
    }
}

/// Side button layout info
public struct SideButtonLayoutInfo: Sendable {
    public let priority: SideButtonPriority
    public let overflowTitle: String?

    public init(priority: SideButtonPriority = .primary, overflowTitle: String? = nil) {
        self.priority = priority
        self.overflowTitle = overflowTitle
    }
}
