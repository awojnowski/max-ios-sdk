//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

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

class MAXAdRequestSpec: QuickSpec {
    override func spec() {

        describe("MAXAdRequest") {
            var adRequest: TestableMAXAdRequest = TestableMAXAdRequest(adUnitID: "1234")
            var url = URL(string:"https://ads.maxads.io/ads/req/1234")!
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

            it("has its values serialized") {
                let reqDict = adRequest.dict

                expect(reqDict["v"]).notTo(beNil())
                expect(reqDict["sdk_v"]).notTo(beNil())
                expect(reqDict["app_v"]).notTo(beNil())
                expect(reqDict["ifa"]).notTo(beNil())
                expect(reqDict["lmt"]).notTo(beNil())
                expect(reqDict["vendor_id"]).notTo(beNil())
                expect(reqDict["tz"]).notTo(beNil())
                expect(reqDict["locale"]).notTo(beNil())
                expect(reqDict["orientation"]).notTo(beNil())
                expect(reqDict["w"]).notTo(beNil())
                expect(reqDict["h"]).notTo(beNil())
                expect(reqDict["browser_agent"]).notTo(beNil())
                expect(reqDict["model"]).notTo(beNil())
                expect(reqDict["connectivity"]).notTo(beNil())
                expect(reqDict["carrier"]).notTo(beNil())
                expect(reqDict["session_depth"]).notTo(beNil())
                expect(reqDict["location"]).notTo(beNil())
                expect(reqDict["location_tracking"]).notTo(beNil())
            }

            it("contains longitude data when location tracking is on") {

                adRequest.locationTrackingEnabled = true
                let reqDict = adRequest.dict

                expect({
                    if let locationData = reqDict["location"] as? Dictionary<String, Any> {
                        if let longitude = locationData["longitude"] as? Double {
                            expect(longitude).to(equal(11.02))
                            return .succeeded
                        } else {
                            return .failed(reason: "Location dict expected to have longitude but didn't.")
                        }
                    } else {
                        return .failed(reason: "Request dict expected to have location data but didn't.")
                    }
                }).to(succeed())

            }

            it("contains latitude data when location tracking is on") {
                adRequest.locationTrackingEnabled = true
                let reqDict = adRequest.dict

                expect({
                    if let locationData = reqDict["location"] as? Dictionary<String, Any> {
                        if let longitude = locationData["latitude"] as? Double {
                            expect(longitude).to(equal(10.01))
                            return .succeeded
                        } else {
                            return .failed(reason: "Location dict expected to have latitude but didn't.")
                        }
                    } else {
                        return .failed(reason: "Request dict expected to have location data but didn't.")
                    }
                }).to(succeed())

            }
            
            it("contains serialized location tracking availability when location tracking is enabled") {
                adRequest.locationTrackingEnabled = true
                let reqDict = adRequest.dict
                
                expect({
                    if let locationData = reqDict["location"] as? Dictionary<String, Any> {
                        if let hAccuracy = locationData["horizontal_accuracy"] as? Double {
                            expect(hAccuracy).to(equal(3.4))
                            return .succeeded
                        } else {
                            return .failed(reason: "Location dict expected to have horizontal accuracy but didn't.")
                        }
                        
                        if let vAccuracy = locationData["vertical_accuracy"] as? Double {
                            XCTAssertEqual(vAccuracy, 4.5)
                        } else {
                            return .failed(reason: "Accuracy dict expected to have vertical accuracy but didn't.")
                        }
                    } else {
                        return .failed(reason: "Request dict expected to have location accuracy but didn't.")
                    }
                }).to(succeed())
            }
            
            it("contains serialized location tracking timestamps when location tracking is enabled") {
                adRequest.locationTrackingEnabled = true
                let reqDict = adRequest.dict
                
                expect({
                    if let locationData = reqDict["location"] as? Dictionary<String, Any> {
                        if let ts = locationData["timestamp"] as? String {
                            expect(ts).to(equal("pretty recently"))
                            return .succeeded
                        } else {
                            return .failed(reason: "Location dict expected to have timestamp but didn't.")
                        }
                    } else {
                        return .failed(reason:"Request dict expected to have location data but didn't.")
                    }
                }).to(succeed())
            }
            
            it("reports location tracking as disabled if it hasn't been enabled by the SDK user") {
                let reqDict = adRequest.dict
                XCTAssertEqual(reqDict["location_tracking"] as! String, "disabled")
            }

            it("reports the correct version numbers") {
                let reqDict = adRequest.dict

                expect(reqDict["v"] as? String).to(equal("1"))
                expect(reqDict["sdk_v"] as? String).to(equal("0.6.1"))
            }

            it("reports the app version") {
                let reqDict = adRequest.dict
                expect(reqDict["app_v"] as? String).to(equal("UNKNOWN"))
            }
            
            it("should request an ad and complete with a normal response") {
                waitUntil { done in
                    adRequest.requestAd { (_response, _error) in
                        expect(_error).to(beNil())
                        expect(_response).notTo(beNil())
                        
                        let response = _response!
                        
                        expect(response.creativeType).to(equal("html"))
                        done()
                    }
                }
            }
            
            it("should request an ad and be able to receive a blank response") {
                adRequest.mockSession.clearMocks()
                adRequest.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 204, httpVersion: "1.1", headerFields: nil)!,
                    withData: try! JSONSerialization.data(withJSONObject: [:])
                )
                
                waitUntil { done in
                    adRequest.requestAd { (_response, _error) in
                        expect(_error).to(beNil())
                        expect(_response).notTo(beNil())
                        
                        let response = _response!
                        
                        expect(response.creativeType).to(equal("empty"))
                        expect(response.preBidKeywords).to(equal(""))
                        
                        done()
                    }
                }
            }
            
            it("should request an ad and properly respond to errors") {
                enum TestError: Error { case error }
                adRequest.mockSession.clearMocks()
                adRequest.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 400, httpVersion: "1.1", headerFields: nil)!,
                    withError: TestError.error
                )
                
                waitUntil { done in
                    adRequest.requestAd { (_response, _error) in
                        expect(_error).notTo(beNil())
                        expect(_response).to(beNil())
                        done()
                    }
                }
            }
        }
    }
}
