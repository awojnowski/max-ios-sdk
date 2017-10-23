import Foundation

private var MAXPreBids: [String: MAXCachedAdResponse] = [:]
private var MAXPreBidErrors: [String: NSError] = [:]

class MAXCachedAdResponse {
    let adResponse: MAXAdResponse?
    let createdAt: Date
    let defaultTimeoutIntervalSeconds = 60.0*60.0

    init(withResponse: MAXAdResponse?) {
        self.adResponse = withResponse
        self.createdAt = Date()
    }
    
    var timeoutIntervalSeconds: Double {
        get {
            if let timeoutInterval = self.adResponse?.expirationIntervalSeconds {
                return timeoutInterval
            } else {
                return defaultTimeoutIntervalSeconds
            }
        }
    }

    var isExpired: Bool {
        get {
            return abs(self.createdAt.timeIntervalSinceNow) > self.timeoutIntervalSeconds
        }
    }
}

public class MAXAds {
    
    public class func receivedPreBid(adUnitID: String, response: MAXAdResponse?, error: NSError?) {
        if let existingResponse = MAXPreBids[adUnitID] {
            if existingResponse.isExpired {
                existingResponse.adResponse?.trackExpired()
            } else {
                existingResponse.adResponse?.trackLoss()
            }
        }
        MAXPreBids[adUnitID] = MAXCachedAdResponse(withResponse: response)
        MAXPreBidErrors[adUnitID] = error
    }
    
    public class func getPreBid(adUnitID: String) -> MAXAdResponse? {
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }
        
        if let error = MAXPreBidErrors[adUnitID] {
            MAXLog.error("Pre-bid error was found for adUnitID=\(adUnitID), error=\(error)")
            return nil
        }
        
        guard let cachedAdResponse = MAXPreBids[adUnitID] else {
            MAXLog.error("Pre-bid was not found for adUnitID=\(adUnitID)")
            return nil
        }
        
        if cachedAdResponse.isExpired {
            cachedAdResponse.adResponse?.trackExpired()
            return nil
        }
        
        return cachedAdResponse.adResponse
    }
}

@available(*, deprecated, message: "MAXPreBid has been renamed to MAXAds")
public class MAXPreBid: MAXAds {}
