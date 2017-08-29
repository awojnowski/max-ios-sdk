//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import XCTest
@testable import MAX

class MAXAdRequestTests: XCTestCase {

    func testSerialization() {
        let adRequest = MAXAdRequest(adUnitID: "1234")
        let reqDict = adRequest.dict

        XCTAssertNotNil(reqDict["v"])
        XCTAssertNotNil(reqDict["ifa"])
        XCTAssertNotNil(reqDict["lmt"])
        XCTAssertNotNil(reqDict["vendor_id"])
        XCTAssertNotNil(reqDict["tz"])
        XCTAssertNotNil(reqDict["locale"])
        XCTAssertNotNil(reqDict["orientation"])
        XCTAssertNotNil(reqDict["w"])
        XCTAssertNotNil(reqDict["h"])
        XCTAssertNotNil(reqDict["browser_agent"])
        XCTAssertNotNil(reqDict["model"])
        XCTAssertNotNil(reqDict["connectivity"])
        XCTAssertNotNil(reqDict["carrier"])
        XCTAssertNotNil(reqDict["longitude"])
        XCTAssertNotNil(reqDict["latitude"])
        XCTAssertNotNil(reqDict["session_depth"])
    }
}
