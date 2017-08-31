//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXAdResponseTests: XCTestCase {

    var responseData: Dictionary<String, Any> = [
        "winner": [
            "creative_type": "html",
        ],
        "creative": [
            "html": "<img src='http://a.com/b.png' />"
        ],
        "prebid_keywords": "a,b,c",
        "refresh": 10,
        "impression_urls": [
            "https://ads.maxads.io/event/imp",
            "https://ads.ssp.com/track/imp"
        ],
        "click_urls": [ "https://ads.maxads.io/event/clk" ],
        "selected_urls": [ "https://ads.maxads.io/event/select" ],
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
        var responseData: Dictionary<String, Any> = [
            "winner": [
                "creative_type": "network",
            ],
            "creative": [
                "custom_event_class": "NetworkEventClass"
            ]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
        let response = try! MAXAdResponse(data:jsonData)

        let handler = response.networkHandlerFromCreative()

        XCTAssertNotNil(handler.0)
        XCTAssertNotNil(handler.1)
    }

    func testTrackImpression() {

    }

    func testTrackClick() {

    }

    func testTrackSelected() {

    }
}
