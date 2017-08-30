//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXAdRequestTests: XCTestCase {

    class TestableMAXAdRequest: MAXAdRequest {
        let mockSession = MockURLSession()
        override func getSession() -> URLSession {
            return mockSession
        }
    }

    var adRequest: TestableMAXAdRequest = TestableMAXAdRequest(adUnitID: "1234")

    override func setUp() {
        super.setUp()

        let url = URL(string:"https://ads.maxads.io/ads/req/1234")!
        let responseData = [
            "winner": [
                "prebid_keywords": "a,b,c",
                "creative": "<img src='http://a.com/b.png' />",
                "creative_type": "html"
            ]
        ]
        adRequest.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!,
                withData: try! JSONSerialization.data(withJSONObject: responseData)
        )
    }

    func testSerialization() {
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

    func testRequestAd() {
        let completion = expectation(description:"MAXAdRequest completes normally")

        adRequest.requestAd { (_response, _error) in
            XCTAssertNil(_error)
            XCTAssertNotNil(_response)

            let response = _response!

            XCTAssertEqual(response.creativeType, "html")
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
