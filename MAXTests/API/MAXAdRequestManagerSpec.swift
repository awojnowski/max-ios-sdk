import Quick
import Nimble
import MoPub
@testable import MAX

class MAXAdRequestManagerSpec: QuickSpec {
    override func spec() {
        describe("MAXAdRequestManager") {
            
            let adUnitID = "1234"
            var manager: MAXAdRequestManagerStub?
            
            it("manages basic refreshes") {
                waitUntil { done in
                    manager = MAXAdRequestManagerStub(adUnitID: adUnitID) { (response, error) in
                        done()
                    }
                    
                    let response = MAXAdResponseStub()
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
                    manager = MAXAdRequestManagerStub(adUnitID: adUnitID) { (response, error) in
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
