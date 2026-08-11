import XCTest

final class OmniPulseUITests: XCTestCase {
    func testUpdateLocationButtonGetsCurrentLocation() {
        let app = XCUIApplication()
        app.launch()

        let updateButton = app.buttons["update-location-button"]
        XCTAssertTrue(updateButton.waitForExistence(timeout: 5))
        updateButton.tap()

        let coordinates = app.staticTexts["location-coordinates"]
        XCTAssertTrue(coordinates.waitForExistence(timeout: 10))
        XCTAssertTrue(coordinates.label.contains("25.686"))
    }
}
