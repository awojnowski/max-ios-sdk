import Foundation

private var MAXPreBids: MAXConcurrentDictionary<String, MAXCachedAdResponse> = [:]
private var MAXPreBidErrors: MAXConcurrentDictionary<String, NSError> = [:]

internal class MAXCachedAdResponse {
    internal let adResponse: MAXAdResponse?
    internal let createdAt: Date
    internal let defaultTimeoutIntervalSeconds = 60.0*60.0

    internal init(withResponse: MAXAdResponse?) {
        self.adResponse = withResponse
        self.createdAt = Date()

        MAXLogger.debug("Cached a pre-bid for partner \(String(describing: withResponse?.partnerName))")
    }

    internal var timeoutIntervalSeconds: Double {
        if let timeoutInterval = self.adResponse?.expirationIntervalSeconds {
            return timeoutInterval
        } else {
            return defaultTimeoutIntervalSeconds
        }
    }

    internal var isExpired: Bool {
        return abs(self.createdAt.timeIntervalSinceNow) > self.timeoutIntervalSeconds
    }
}


public class MAXAds: NSObject {

    @objc public class func receivedPreBid(adUnitID: String, response: MAXAdResponse?, error: NSError?) {
        MAXLogger.debug("Received pre-bid with MAX ad unit id \(adUnitID)")
        
        guard response?.isReserved == false else {
            MAXLogger.debug("\(String(describing: self)): is not caching ad with id <\(adUnitID)> because it is reserved")
            return
        }

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

    @objc public class func getPreBid(adUnitID: String) -> MAXAdResponse? {
        MAXLogger.debug("Getting pre-bid with MAX ad unit id \(adUnitID)")

        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }

        if let error = MAXPreBidErrors[adUnitID] {
            MAXLogger.error("Pre-bid error was found for adUnitID=\(adUnitID), error=\(error)")
            return nil
        }

        guard let cachedAdResponse = MAXPreBids[adUnitID] else {
            MAXLogger.error("Pre-bid was not found for adUnitID=\(adUnitID)")
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
