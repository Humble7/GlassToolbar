import XCTest
@testable import GlassToolbar

final class GlassToolbarTests: XCTestCase {

    func testToolbarItemCreation() {
        let item = GlassToolbarItem(
            title: "Test",
            icon: nil,
            selectedIcon: nil
        )
        XCTAssertEqual(item.title, "Test")
        XCTAssertEqual(item.priority, .primary)
    }

    func testAppearanceConfiguration() {
        let config = ToolbarAppearanceConfiguration.default
        XCTAssertEqual(config.toolbarHeight, 56)
        XCTAssertEqual(config.itemIconSize, 24)
    }
}
