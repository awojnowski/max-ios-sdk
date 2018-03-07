import Foundation
@testable import MAX

class MAXAdRequestManagerStub: MAXAdRequestManager {
    var response: MAXAdResponse? = nil
    var error: NSError? = nil
    var request: MAXAdRequest!
    
    override init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        super.init(adUnitID: adUnitID, completion: completion)
        
        self.request = MAXAdRequest(adUnitID: adUnitID)
    }
    
    override func requestAd(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        print("MAXAdRequestManagerStub.runPrebid called")
        completion(response, error)
        return request
    }
}
