//
// Created by John Pena on 8/25/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXErrorReporterTest: XCTestCase {

    class MockErrorReporter: MAXErrorReporter {
        var data: Data?
        init() {
            super().init()
        }

        override func record(data: Data) {
            self.data = data
        }
    }

    func testClientProperties() {
        let clientError = MAXClientError(message: "Something went wrong")

        XCTAssertNotNil(clientError.ifa)
        XCTAssertNotNil(clientError.lmt)
        XCTAssertNotNil(clientError.vendorId)
        XCTAssertNotNil(clientError.timeZone)
        XCTAssertNotNil(clientError.locale)
        XCTAssertNotNil(clientError.regionCode)
        XCTAssertNotNil(clientError.orientation)
        XCTAssertNotNil(clientError.deviceWidth)
        XCTAssertNotNil(clientError.deviceHeight)
        XCTAssertNotNil(clientError.browserAgent)
        XCTAssertNotNil(clientError.carrier)
    }

    func testSerializeClientError() {
        let recorder = MockErrorReporter()
        recorder.logError(message: "Something broke")

        guard let data = recorder.data else {
            XCTFail("Recorder didn't generate any data")
        }

        print(data)
    }
}
