import Quick
import Nimble
import MoPub
@testable import MAX

class TestableMAXAdRequestManager: MAXAdRequestManager {
    var response: MAXAdResponse? = nil
    var error: NSError? = nil
    var request: MAXAdRequest!
    
    override init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        super.init(adUnitID: adUnitID, completion: completion)
        
        self.request = MAXAdRequest(adUnitID: adUnitID)
    }
    
    override func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        print("TestableMAXAdRequestManager.runPrebid called")
        completion(response, error)
        return request
    }
}

class MAXAdRequestManagerSpec: QuickSpec {
    override func spec() {
        describe("MAXAdRequestManager") {
            
            let adUnitID = "1234"
            var manager: TestableMAXAdRequestManager?
            
            it("manages basic refreshes") {
                waitUntil { done in
                    manager = TestableMAXAdRequestManager(adUnitID: adUnitID) { (response, error) in
                        done()
                    }
                    
                    let response = MAXAdResponse()
                    response.autoRefreshInterval = 2
                    manager?.response = response
                    manager?.errorCount = 1
                    
                    let _ = manager?.refresh()
                }

                expect({
                    if let m = manager {
                        expect(m.errorCount).to(equal(0))
                        return .succeeded
                    } else {
                        return .failed(reason:"Ad request manager was nil")
                    }
                }).to(succeed())
            }
            
            it("handles request errors") {
                waitUntil { done in
                    manager = TestableMAXAdRequestManager(adUnitID: adUnitID) { (response, error) in
                        done()
                    }
                    
                    let error = NSError(domain: "ads.maxads.io", code: 400)
                    manager?.error = error
                    manager?.response = nil
                    
                    let _ = manager?.refresh()
                }
                
                expect({
                    if let m = manager {
                        expect(m.errorCount).to(equal(1))
                        return .succeeded
                    } else {
                        return .failed(reason:"Ad request manager was nil")
                    }
                }).to(succeed())

            }
        }
    }
}
