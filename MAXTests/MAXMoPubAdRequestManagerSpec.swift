import Quick
import Nimble
import MoPub
@testable import MAX

class TestableMAXMoPubAdRequestManager: MAXMoPubAdRequestManager {
    var response: MAXAdResponse? = nil
    var error: NSError? = nil
    var request: MAXAdRequest!
    var refreshed = false
    
    override init(maxAdUnitID: String, adView: MPAdView, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        super.init(maxAdUnitID: maxAdUnitID, adView: adView, completion: completion)
        
        self.request = MAXAdRequest(adUnitID: adUnitID)
    }
    
    override func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        print("TestableMAXMoPubAdRequestManager.runPrebid called")
        completion(response, error)
        return request
    }
    
    override func scheduleNewRefresh() {
        self.refreshed = true
    }
}

class TestMPAdView: MPAdView {
    override func loadAd() {
        self.delegate.adViewDidLoadAd?(self)
    }
    
    func failAd() {
        self.delegate.adViewDidFail?(toLoadAd: self)
    }
}

class TestMPAdViewListener: NSObject, MPAdViewDelegate {
    var hadImpression = false
    var hadFailure = false
    func viewControllerForPresentingModalView() -> UIViewController! {
        return UIApplication.shared.delegate!.window!!.rootViewController
    }
    
    func adViewDidLoadAd(_ view: MPAdView!) {
        self.hadImpression = true
    }
    
    func adViewDidFail(toLoadAd view: MPAdView!) {
        self.hadFailure = true
    }
}

class MAXMoPubAdRequestManagerSpec: QuickSpec {
    override func spec() {
        describe("MAXMoPubAdRequestManager") {
            let adUnitID = "1234"
            let mpAd = TestMPAdView()
            let listener = TestMPAdViewListener()
            mpAd.delegate = listener
            
            let manager = TestableMAXMoPubAdRequestManager(maxAdUnitID: adUnitID, adView: mpAd) { (response, error) in
                // no after effects
            }
            
            let response = MAXAdResponse()
            response.autoRefreshInterval = 1
            manager.lastResponse = response
            
            beforeEach {
                listener.hadImpression = false
                listener.hadFailure = false
                manager.refreshed = false
            }
            
            it("calls refresh after an impression") {
                expect(manager.refreshed).to(beFalse())
                expect(listener.hadImpression).to(beFalse())
                expect(listener.hadFailure).to(beFalse())
                
                mpAd.loadAd()

                // the manager should have received a call to refresh after the impression
                expect(manager.refreshed).to(beTrue())
                
                // we should also expect that the listener received an impression and that the event wasn't
                // swallowed by the proxy
                expect(listener.hadImpression).to(beTrue())
                expect(listener.hadFailure).to(beFalse())
            }
            
            it("calls refresh after a failure") {
                expect(manager.refreshed).to(beFalse())
                expect(listener.hadImpression).to(beFalse())
                expect(listener.hadFailure).to(beFalse())
                
                mpAd.failAd()
                
                // the manager should have received a call to refresh after the impression
                expect(manager.refreshed).to(beTrue())
                
                // we should also expect that the listener received an impression and that the event wasn't
                // swallowed by the proxy
                expect(listener.hadImpression).to(beFalse())
                expect(listener.hadFailure).to(beTrue())
            }
        }
    }
}

