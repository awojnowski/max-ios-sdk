//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXAdResponseTests: XCTestCase {

    class CustomEvent: NSObject {}
    class TestableMAXAdResponse: MAXAdResponse {
        let mockSession = MockURLSession()
        override func getSession() -> URLSession {
            return mockSession
        }

        override func getCustomEventClass(name: String) -> NSObject.Type? {
            return CustomEvent.self
        }
    }

    var responseData: Dictionary<String, Any> = [
        "winner": [
            "creative_type": "html",
        ],
        "creative": [
            "html": "<img src='http://a.com/b.png' />"
        ],
        "prebid_keywords": "a,b,c",
        "refresh": 10,
        "impression_urls": [ "https://ads.maxads.io/event/imp/abcd" ],
        "click_urls": [ "https://ads.maxads.io/event/clk/abcd" ],
        "selected_urls": [ "https://ads.maxads.io/event/select/abcd" ],
    ]

    func testCreateAdResponse() {
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! MAXAdResponse(data:jsonData)

        XCTAssertEqual(response.preBidKeywords, "a,b,c")
        XCTAssertEqual(response.autoRefreshInterval, 10)
    }

    func testCreateEmptyResponse() {
        let response: MAXAdResponse = MAXAdResponse()

        XCTAssertEqual(response.preBidKeywords, "")
        XCTAssertEqual(response.creativeType, "empty")
        XCTAssertNil(response.autoRefreshInterval)
    }

    func testShouldAutoRefresh() {
        let response = MAXAdResponse()

        response.autoRefreshInterval = 10
        XCTAssertTrue(response.shouldAutoRefresh())

        response.autoRefreshInterval = 0
        XCTAssertFalse(response.shouldAutoRefresh())

        response.autoRefreshInterval = nil
        XCTAssertFalse(response.shouldAutoRefresh())
    }

    func testNetworkHandlerFromCreative() {
        let responseData: Dictionary<String, Any> = [
            "winner": [
                "creative_type": "network",
            ],
            "creative": "{\"custom_event_class\": \"CustomEvent\",\"custom_event_info\" : {\"test\": \"info\"}}"
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! TestableMAXAdResponse(data:jsonData)

        let handler = response.networkHandlerFromCreative()

        XCTAssertNotNil(handler.0)
        XCTAssertNotNil(handler.1)
    }

    func testTrackImpression() {
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! TestableMAXAdResponse(data:jsonData)
        let url = URL(string:"https://ads.maxads.io/event/imp/abcd")!

        response.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        )

        response.trackImpression()

        XCTAssertEqual(response.mockSession.dataTaskCalls[url.absoluteString], 1)
    }

    func testTrackClick() {
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! TestableMAXAdResponse(data:jsonData)
        let url = URL(string:"https://ads.maxads.io/event/clk/abcd")!

        response.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        )

        response.trackClick()

        XCTAssertEqual(response.mockSession.dataTaskCalls[url.absoluteString], 1)
    }

    func testTrackSelected() {
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! TestableMAXAdResponse(data:jsonData)
        let url = URL(string:"https://ads.maxads.io/event/select/abcd")!

        response.mockSession.onRequest(
                to: url,
                respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        )

        response.trackSelected()

        XCTAssertEqual(response.mockSession.dataTaskCalls[url.absoluteString], 1)
    }
}
