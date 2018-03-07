import Quick
import Nimble
@testable import MAX


class MAXAdResponseSpec: QuickSpec {
    override func spec() {
        describe("MAXAdResponse") {

            let responseData: Dictionary<String, Any> = [
                "winner": [
                    "creative_type": "html",
                    "partner": "MAX",
                    "partner_placement_id": "one_great_id",
                    "use_partner_rendering": true,
                    "auction_price": 1234
                ],
                "creative": "<img src='http://a.com/b.png' />",
                "prebid_keywords": "a,b,c",
                "refresh": 10,
                "expiration_interval": 10.0*60.0,
                "impression_urls": [ "https://ads.maxads.io/event/imp/abcd" ],
                "click_urls": [ "https://ads.maxads.io/event/clk/abcd" ],
                "selected_urls": [ "https://ads.maxads.io/event/select/abcd" ],
                "handoff_urls": [ "https://ads.maxads.io/event/handoff/abcd" ],
                "loss_urls": ["https://ads.maxads.io/event/loss/abcd" ],
                "expire_urls": ["https://ads.maxads.io/event/expire/abcd" ]
            ]
            let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
            var response: MAXAdResponseStub?
            
            beforeEach {
                response = try! MAXAdResponseStub(adUnitId: "", data:jsonData)
            }

            it("can be created with JSON data") {
                let r = try! MAXAdResponse(adUnitId: "", data: jsonData)
                expect(r.preBidKeywords).to(equal("a,b,c"))
                expect(r.autoRefreshInterval).to(equal(10))
                expect(r.expirationIntervalSeconds).to(equal(10.0*60.0))
                expect(r.creativeType).to(equal("html"))
                expect(r.creative).to(equal("<img src='http://a.com/b.png' />"))
                expect(r.partnerName).to(equal("MAX"))
                expect(r.partnerPlacementID).to(equal("one_great_id"))
                expect(r.usePartnerRendering).to(beTrue())
                expect(r.winningPrice).to(equal(1234))
            }

            it("can be created from an empty response body") {
                let emptyResponse = MAXAdResponse()
                expect(emptyResponse.preBidKeywords).to(equal(""))
                expect(emptyResponse.creativeType).to(equal("empty"))
                expect(emptyResponse.autoRefreshInterval).to(beNil())
                expect(emptyResponse.winningPrice).to(equal(0))
            }

            it("should auto refresh") {
                response?.autoRefreshInterval = 10
                expect(response?.shouldAutoRefresh()).to(beTrue())

                response?.autoRefreshInterval = 0
                expect(response?.shouldAutoRefresh()).notTo(beTrue())

                response?.autoRefreshInterval = nil
                expect(response?.shouldAutoRefresh()).notTo(beTrue())
            }

            it("should track impressions") {
                let url = URL(string:"https://ads.maxads.io/event/imp/abcd")!

                response?.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response?.trackImpression()
                expect(response?.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }

            it("should track clicks") {
                let url = URL(string:"https://ads.maxads.io/event/clk/abcd")!

                response?.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response?.trackClick()
                expect(response?.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }

            it("should track select events") {
                let url = URL(string:"https://ads.maxads.io/event/select/abcd")!

                response?.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )

                response?.trackSelected()
                expect(response?.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }
            
            it("should track select handoff") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! MAXAdResponseStub(adUnitId: "", data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/handoff/abcd")!
                
                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )
                
                response.trackHandoff()
                
                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }
            
            it("should track loss events") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! MAXAdResponseStub(adUnitId: "", data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/loss/abcd")!
                
                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )
                
                response.trackLoss()
                
                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }
            
            it("should track expire events") {
                let jsonData = try! JSONSerialization.data(withJSONObject: responseData)
                let response = try! MAXAdResponseStub(adUnitId: "", data:jsonData)
                let url = URL(string:"https://ads.maxads.io/event/expire/abcd")!
                
                response.mockSession.onRequest(
                    to: url,
                    respondWith: HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
                )
                
                response.trackExpired()
                
                expect(response.mockSession.dataTaskCalls[url.absoluteString]).to(equal(1))
            }
        }
    }
}

