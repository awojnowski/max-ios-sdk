import Quick
import Nimble
import MoPub
@testable import MAX

// NOTE: The need for this class to test MAXAdRequestManager exponential backoff likely means that exponential backoff logic can be more cleanly implemented. A possible option to make the logic more clean would be to have MAXAdRequestManager call startRefreshTimer when requestAd() has an error. For now leave the responsibility to the delegate to iOS class implementations will more closely mirror Android class implementations.
class MAXAdRequestManagerFailureRefreshListenerMock: MAXAdRequestManagerListenerMock {
    
    internal let manager: MAXAdRequestManagerMock

    internal init(manager: MAXAdRequestManagerMock) {
        self.manager = manager
        super.init()
    }
    
    override public func onRequestSuccess(adResponse: MAXAdResponse?) {
        super.onRequestSuccess(adResponse: adResponse)
        
        // Expnential backoff is currently achieved by listener calling back into manager
        manager.startRefreshTimer(delay: 0)
    }
    
    override public func onRequestFailed(error: NSError?) {
        super.onRequestFailed(error: error)

        // Expnential backoff is currently achieved by listener calling back into manager
        manager.startRefreshTimer(delay: 0)
    }
}

class MAXAdRequestManagerSpec: QuickSpec {
    
    override func spec() {
        describe("MAXAdRequestManager") {

            let adUnitId = "1234"
            let manager = MAXAdRequestManagerMock()
            //TODO - BRYAN: having a minErrorRetrySeconds greater than 1 slows down testing. Make backoff work with values less than 1?
            manager.minErrorRetrySeconds = 1.1
            let listener = MAXAdRequestManagerFailureRefreshListenerMock(manager: manager)
            manager.delegate = listener
            manager.adUnitId = adUnitId

            beforeEach {
                listener.requestSucceeded = false
                listener.requestFailed = false
                manager.refreshTimerStarted = false
                manager.errorCount = 0
            }
            
            it("manages basic ad requests") {
                expect(listener.requestSucceeded).to(beFalse())
                expect(listener.requestFailed).to(beFalse())
                expect(manager.errorCount).to(equal(0))

                let response = MAXAdResponseStub()
                response.autoRefreshInterval = 2
                manager.response = response
                manager.errorCount = 1

                manager.requestAd()

                expect(listener.requestSucceeded).to(beTrue())
                expect(listener.requestFailed).to(beFalse())
                expect(manager.errorCount).to(equal(0))
            }

            it("handles ad request errors") {
                expect(listener.requestSucceeded).to(beFalse())
                expect(listener.requestFailed).to(beFalse())
                expect(manager.errorCount).toEventually(equal(0))

                let error = NSError(domain: "ads.maxads.io", code: 400)
                manager.error = error

                manager.requestAd()

                expect(listener.requestSucceeded).to(beFalse())
                expect(listener.requestFailed).to(beTrue())
                expect(manager.errorCount).to(equal(1))
            }

            it("makes requests with an exponential backoff when repeated calls to startRefreshTimer are made after request failures") {

                expect(listener.requestSucceeded).to(beFalse())
                expect(listener.requestFailed).to(beFalse())
                expect(manager.errorCount).to(equal(0))
                expect(manager.refreshTimerStarted).to(beFalse())
                
                let error = NSError(domain: "ads.maxads.io", code: 400)
                manager.error = error

                manager.requestAd()

                expect(manager.refreshTimerStarted).to(beTrue())
                let backoffTime = manager.minErrorRetrySeconds + pow(manager.minErrorRetrySeconds, 2) + pow(manager.minErrorRetrySeconds, 3)
                expect(manager.errorCount).toEventually(equal(3), timeout: backoffTime)
            }
        }
    }
}
