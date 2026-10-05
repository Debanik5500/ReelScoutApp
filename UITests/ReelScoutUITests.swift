import XCTest

final class ReelScoutUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let openButton = springboard.buttons["Open"]
        if openButton.waitForExistence(timeout: 3) {
            openButton.tap()
        }
        return app
    }

    func testHomeShowsDiscoveriesAndTabs() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Your collections"].exists)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Collections"].exists)
        XCTAssertTrue(app.tabBars.buttons["Saved"].exists)
        XCTAssertTrue(app.staticTexts["Handmade pasta in Soho"].exists)
    }

    func testTabSwitchingShowsCollectionsAndSaved() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 15))

        app.tabBars.buttons["Collections"].tap()
        XCTAssertTrue(app.navigationBars["Collections"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 5))
    }

    func testTappingReelOpensDiscoveryResult() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 15))

        let reelTitle = app.staticTexts["Handmade pasta in Soho"]
        XCTAssertTrue(reelTitle.exists)
        reelTitle.tap()

        XCTAssertTrue(app.navigationBars["Discovery"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Save"].exists || app.buttons["Share"].exists)
    }

    func testFrameStackScreenshots() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 15))

        app.staticTexts["Handmade pasta in Soho"].tap()
        XCTAssertTrue(app.navigationBars["Discovery"].waitForExistence(timeout: 5))
        sleep(2)
        saveScreenshot("/tmp/rs_discovery.png")

        let stack = app.descendants(matching: .any)["insightFrameStack"].firstMatch
        if stack.waitForExistence(timeout: 5) {
            var attempts = 0
            while !stack.isHittable && attempts < 4 {
                app.swipeUp()
                attempts += 1
                sleep(1)
            }
            if stack.isHittable {
                stack.swipeLeft()
                sleep(1)
                saveScreenshot("/tmp/rs_frame_swiped.png")
                stack.tap()
                sleep(2)
                saveScreenshot("/tmp/rs_frameviewer.png")
                app.swipeLeft()
                sleep(1)
                saveScreenshot("/tmp/rs_frameviewer_2.png")
                let close = app.buttons.firstMatch
                if close.exists { close.tap() }
                sleep(1)
            }
        }
        saveScreenshot("/tmp/rs_discovery_after.png")
    }

    private func saveScreenshot(_ path: String) {
        let shot = XCUIScreen.main.screenshot()
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }

    func testCollectionsTapOpensDetail() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Your discoveries"].waitForExistence(timeout: 15))

        app.tabBars.buttons["Collections"].tap()
        XCTAssertTrue(app.navigationBars["Collections"].waitForExistence(timeout: 5))

        let londonEats = app.staticTexts["London Eats"].firstMatch
        XCTAssertTrue(londonEats.waitForExistence(timeout: 5))
        londonEats.tap()

        XCTAssertTrue(app.navigationBars["London Eats"].waitForExistence(timeout: 5))
    }
}
