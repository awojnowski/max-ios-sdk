import Quick
import Nimble
@testable import MAX

class MAXCachedAdResponseSpec: QuickSpec {
    override func spec() {
        let response = MAXAdResponseStub()
        response.expirationIntervalSeconds = 100.0
        let cachedResponse = MAXCachedAdResponse(withResponse: response)

        it("should use the response's expiration interval if it's set") {
            expect(cachedResponse.timeoutIntervalSeconds).to(equal(100.0))
        }

        it("should determine when an ad response has expired") {
            expect(cachedResponse.isExpired).to(beFalse())

            let expiredResponse = MAXAdResponseStub()
            expiredResponse.expirationIntervalSeconds = 0.0
            let expired = MAXCachedAdResponse(withResponse: expiredResponse)
            expect(expired.isExpired).to(beTrue())
        }

        it("should use a default timeout when the ad response is nil") {
            let cachedResponseWithNil = MAXCachedAdResponse(withResponse: nil)
            expect(cachedResponseWithNil.timeoutIntervalSeconds).to(equal(3600.0))
        }
    }
}

class MockMAXAdResponse: MAXAdResponse {
    var trackExpiredCalled = false
    override func trackExpired() {
        self.trackExpiredCalled = true
    }
    
    var _expirationIntervalSeconds: Double = 3600.0
    override var expirationIntervalSeconds: Double {
        get {
            return _expirationIntervalSeconds
        }
        set {
            _expirationIntervalSeconds = newValue
        }
    }
}

class MAXResponseCacheSpec: QuickSpec {
    override func spec() {
        it("should call trackExpired on ads that have expired") {
            let response = MockMAXAdResponse()
            response.expirationIntervalSeconds = 0.0

            MAXAds.receivedPreBid(adUnitID: "abcd", response: response, error: nil)

            let responseReceived = MAXAds.getPreBid(adUnitID: "abcd")
            expect(responseReceived).to(beNil())
            expect(response.trackExpiredCalled).to(beTrue())
        }

        it("should not call trackExpired on ads that have not expired") {
            var response = MockMAXAdResponse()
            response.expirationIntervalSeconds = 100000.0

            MAXAds.receivedPreBid(adUnitID: "abcd", response: response, error: nil)

            response = MAXAds.getPreBid(adUnitID: "abcd") as! MockMAXAdResponse
            expect(response.trackExpiredCalled).to(beFalse())
        }
    }
}
