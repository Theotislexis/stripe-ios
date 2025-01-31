//
//  PaymentSheet+ShippingTests.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 6/16/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheet_ShippingTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    func testShippingManual() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Continue button should be disabled
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Tapping the address line 1 field should go to autocomplete
        app.textFields["Address line 1"].tap()
        app.buttons["Enter address manually"].tap()
        
        // Tapping the address line 1 field should now just let us enter the field manually
        app.textFields["Address line 1"].tap()
        app.typeText("510 Townsend St")
        app.textFields["Address line 2"].tap()
        app.typeText("Apt 152")
        app.textFields["City"].tap()
        app.typeText("San Francisco")
        app.textFields["State"].tap()
        app.typeText("California")
        // The continue button should still be disabled until we fill in all required fields
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["ZIP"].tap()
        app.typeText("94102")
        app.textFields["Name"].tap()
        app.typeText("Jane Doe")
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        
        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "Jane Doe, 510 Townsend St, Apt 152, San Francisco California 94102, US")
        
        // Opening the shipping address back up...
        shippingButton.tap()
        // ...and editing ZIP to be invalid...
        let zip = app.textFields["ZIP"]
        XCTAssertEqual(zip.value as! String, "94102")
        zip.tap()
        app.typeText(XCUIKeyboardKey.delete.rawValue) // Invalid length
        // ...should disable the continue button
        XCTAssertFalse(continueButton.isEnabled)
        // If we dismiss the sheet while its invalid...
        app.buttons["Close"].tap()
        // The merchant app should get back nil
        XCTAssertEqual(shippingButton.label, "Add")
    }
    
    func testShippingAutoComplete_UnitedStates() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Continue button should be disabled
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Tapping the address line 1 field should go to autocomplete
        app.textFields["Address line 1"].tap()
        
        // Enter partial address and tap first result
        app.textFields["Address"].tap()
        app.typeText("4 Pennsylvania Plaza")
        let searchedCell = app.tables.element(boundBy: 0).cells.containing(NSPredicate(format: "label CONTAINS %@", "4 Pennsylvania Plaza")).element
        let _ = searchedCell.waitForExistence(timeout: 5)
        searchedCell.tap()
        
        // Verify text fields
        let _ = app.textFields["Address line 1"].waitForExistence(timeout: 5)
        XCTAssertEqual(app.textFields["Address line 1"].value as! String, "4 Pennsylvania Plaza")
        XCTAssertEqual(app.textFields["Address line 2"].value as! String, "")
        XCTAssertEqual(app.textFields["City"].value as! String, "New York")
        XCTAssertEqual(app.textFields["State"].value as! String, "NY")
        XCTAssertEqual(app.textFields["ZIP"].value as! String, "10001")
        
        // Type in the name to complete the form
        app.textFields["Name"].tap()
        app.typeText("Jane Doe")
        
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // The merchant app should get back the expected address
        XCTAssertEqual(shippingButton.label, "Jane Doe, 4 Pennsylvania Plaza, New York NY 10001, US")
    }
    
    /// This test ensures we don't show auto complete for an unsupported country
    func testShippingAutoComplete_NewZeland() throws {
        loadPlayground(app, settings: [:])
        let shippingButton = app.buttons["Shipping address"]
        XCTAssertTrue(shippingButton.waitForExistence(timeout: 4.0))
        shippingButton.tap()
        
        // The Continue button should be disabled
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Set country to New Zealand
        app.textFields["Country or region"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "New Zealand")
        app.toolbars.buttons["Done"].tap()
        
        // Tapping the address line 1 field...
        app.textFields["Address line 1"].tap()
        
        // ...should not go to auto complete b/c it's disabled for New Zealand
        XCTAssertFalse(app.buttons["Enter address manually"].waitForExistence(timeout: 3))
    }
}
