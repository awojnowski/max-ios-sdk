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

        var locationTrackingEnabled = false

        override var latitude: Double? {
            if self.locationTrackingEnabled {
                return 10.01
            }
            return nil
        }
        override var longitude: Double? {
            if self.locationTrackingEnabled {
                return 11.02
            }
            return nil
        }

        override var locationHorizontalAccuracy: Double? {
            if self.locationTrackingEnabled {
                return 3.4
            }
            return nil
        }

        override var locationVerticalAccuracy: Double? {
            if self.locationTrackingEnabled {
                return 4.5
            }
            return nil
        }

        override var locationTrackingTimestamp: String? {
            if self.locationTrackingEnabled {
                return "pretty recently"
            }
            return nil
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
        XCTAssertNotNil(reqDict["sdk_v"])
        XCTAssertNotNil(reqDict["app_v"])
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
        XCTAssertNotNil(reqDict["location"])
        XCTAssertNotNil(reqDict["location_tracking"])
    }
    
    func testSerializationWithLocationTrackingHasLongitude() {
        adRequest.locationTrackingEnabled = true
        let reqDict = adRequest.dict

        if let locationData = reqDict["location"] as? Dictionary<String, Any> {
            if let longitude = locationData["longitude"] as? Double {
                XCTAssertEqual(longitude, 11.02)
            } else {
                XCTFail("Location dict expected to have longitude but didn't.")
            }
        } else {
            XCTFail("Request dict expected to have location data but didn't.")
        }
    }

    func testVersionNumbers() {
        let reqDict = adRequest.dict

        XCTAssertEqual(reqDict["v"] as! String, "1")
        XCTAssertEqual(reqDict["sdk_v"] as! String, "0.6.0")
    }

    func testAppVersionNumber() {
        let reqDict = adRequest.dict
        XCTAssertEqual(reqDict["app_v"] as! String, "UNKNOWN")
    }

    func testSerializationWithLocationTrackingHasLatitude() {
        adRequest.locationTrackingEnabled = true
        let reqDict = adRequest.dict

        if let locationData = reqDict["location"] as? Dictionary<String, Any> {
            if let longitude = locationData["latitude"] as? Double {
                XCTAssertEqual(longitude, 10.01)
            } else {
                XCTFail("Location dict expected to have latitude but didn't.")
            }
        } else {
            XCTFail("Request dict expected to have location data but didn't.")
        }
    }

    func testSerializationWithLocationTrackingHasLocationAccuracy() {
        adRequest.locationTrackingEnabled = true
        let reqDict = adRequest.dict

        if let locationData = reqDict["location"] as? Dictionary<String, Any> {
            if let hAccuracy = locationData["horizontal_accuracy"] as? Double {
                XCTAssertEqual(hAccuracy, 3.4)
            } else {
                XCTFail("Location dict expected to have horizontal accuracy but didn't.")
            }

            if let vAccuracy = locationData["vertical_accuracy"] as? Double {
                XCTAssertEqual(vAccuracy, 4.5)
            } else {
                XCTFail("Accuracy dict expected to have vertical accuracy but didn't.")
            }
        } else {
            XCTFail("Request dict expected to have location accuracy but didn't.")
        }
    }

    func testSerializationWithLocationTrackingHasTimestamp() {
        adRequest.locationTrackingEnabled = true
        let reqDict = adRequest.dict

        if let locationData = reqDict["location"] as? Dictionary<String, Any> {
            if let ts = locationData["timestamp"] as? String {
                XCTAssertEqual(ts, "pretty recently")
            } else {
                XCTFail("Location dict expected to have timestamp but didn't.")
            }
        } else {
            XCTFail("Request dict expected to have location data but didn't.")
        }
    }

    func testAdRequestNoLatLongWhenDisabled() {
        let reqDict = adRequest.dict
        XCTAssertEqual(reqDict["location_tracking"] as! String, "disabled")
    }

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
