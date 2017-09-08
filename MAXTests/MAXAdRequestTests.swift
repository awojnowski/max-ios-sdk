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
    var url = URL(string:"https://ads.maxads.io/ads/req/1234")!
    let responseData = [
        "winner": [
            "prebid_keywords": "a,b,c",
            "creative": "<img src='http://a.com/b.png' />",
            "creative_type": "html"
        ]
    ]

    override func setUp() {
        super.setUp()
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
        XCTAssertNotNil(reqDict["session_depth"])

        XCTAssertNil(reqDict["longitude"])
        XCTAssertNil(reqDict["latitude"])
    }

    func testAdRequestNoLatLongWhenDisabled() {
        adRequest.locationTrackingEnabled = false
        let reqDict = adRequest.dict

        XCTAssertEqual(reqDict["location_tracking"] as! String, "disabled")
    }

//    func testAdRequestLatLongWhenEnabled() {
//        adRequest.locationTrackingEnabled = true
//        let reqDict = adRequest.dict
//
//        XCTAssertNotNil(reqDict["longitude"])
//        XCTAssertNotNil(reqDict["latitude"])
//
//        XCTAssertEqual(reqDict["location_tracking"] as! String, "enabled")
//    }

    func testRequestAdWithValidServerResponse() {
        let completion = expectation(description:"MAXAdRequest completes normally with normal response")

        adRequest.requestAd { (_response, _error) in
            XCTAssertNil(_error)
            XCTAssertNotNil(_response)

            let response = _response!

            XCTAssertEqual(response.creativeType, "html")
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testRequestAdWithEmptyServerResponse() {
        adRequest.mockSession.clearMocks()
        adRequest.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 204, httpVersion: "1.1", headerFields: nil)!,
                withData: try! JSONSerialization.data(withJSONObject: [:])
        )

        let completion = expectation(description:"MAXAdRequest completes normally with empty response")

        adRequest.requestAd { (_response, _error) in
            XCTAssertNil(_error)
            XCTAssertNotNil(_response)

            let response = _response!

            XCTAssertEqual(response.creativeType, "empty")
            XCTAssertEqual(response.preBidKeywords, "")

            completion.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testRequestAdWithErroneousServerResponse() {
        enum TestError: Error { case error }
        adRequest.mockSession.clearMocks()
        adRequest.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 400, httpVersion: "1.1", headerFields: nil)!,
                withError: TestError.error
        )

        let completion = expectation(description:"MAXAdRequest completes normally with empty response")

        adRequest.requestAd { (_response, _error) in
            XCTAssertNotNil(_error)
            XCTAssertNil(_response)
            completion.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
