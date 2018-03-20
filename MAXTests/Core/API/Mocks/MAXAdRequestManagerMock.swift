import Foundation
@testable import MAX

class MAXAdRequestManagerListenerMock: NSObject, MAXAdRequestManagerDelegate {
    
    internal var requestSucceeded = false
    internal var requestFailed = false
    
    
    //MARK: MAXAdRequestManagerDelegate
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        requestSucceeded = true
        requestFailed = false
    }
    
    public func onRequestFailed(error: NSError?) {
        requestSucceeded = false
        requestFailed = true
    }
}

class MAXAdRequestManagerMock: MAXAdRequestManager {
    
    internal var response: MAXAdResponse? = nil
    internal var error: NSError? = nil
    internal var refreshTimerStarted = false
    
    override internal func requestAdFromAPI(completion: @escaping MAXResponseCompletion) {
        print("MAXAdRequestManagerMock.requestAdFromAPI called")
        completion(response, error)
    }
    
    override internal func startRefreshTimer(delay: Int) {
        refreshTimerStarted = true
        // Use internal method to bypass refresh queue, which adds a delay that slows down and/or causes unit tests to fail
        super.startRefreshTimerInternal(delay: delay)
    }
}
