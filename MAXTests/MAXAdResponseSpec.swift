//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

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

class MAXAdResponseSpec: QuickSpec {
    override func spec() {
        describe("MAXAdResponse") {

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

            it("can be created with JSON data") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! MAXAdResponse(data:jsonData)

                expect(response.preBidKeywords).to(equal("a,b,c"))
                expect(response.autoRefreshInterval).to(equal(10))
            }

            it("can be created from an empty response body") {
                let response: MAXAdResponse = MAXAdResponse()

                expect(response.preBidKeywords).to(equal(""))
                expect(response.creativeType).to(equal("empty"))
                expect(response.autoRefreshInterval).to(beNil())
            }

            it("should auto refresh") {
                let response = MAXAdResponse()

                response.autoRefreshInterval = 10
                expect(response.shouldAutoRefresh()).to(beTrue())

                response.autoRefreshInterval = 0
                expect(response.shouldAutoRefresh()).notTo(beTrue())

                response.autoRefreshInterval = nil
                expect(response.shouldAutoRefresh()).notTo(beTrue())
            }

            it("should create a network handler for network creatives") {
                let responseData: Dictionary<String, Any> = [
                    "winner": [
                        "creative_type": "network",
                    ],
                    "creative": "{\"custom_event_class\": \"CustomEvent\",\"custom_event_info\" : {\"test\": \"info\"}}"
                ]
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! TestableMAXAdResponse(data:jsonData)

                let handler = response.networkHandlerFromCreative()

                expect(handler.0).notTo(beNil())
                expect(handler.1).notTo(beNil())
            }

            it("should track impressions") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! TestableMAXAdResponse(data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/imp/abcd")!

                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response.trackImpression()

                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }

            it("should track clicks") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! TestableMAXAdResponse(data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/clk/abcd")!

                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response.trackClick()

                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }

            it("should track select events") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! TestableMAXAdResponse(data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/select/abcd")!

                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response.trackSelected()

                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }
        }
    }
}

