import Foundation

public class MAXAdResponseParameters: NSObject {
    @objc public static let winner = "winner"
    @objc public static let creative = "creative"
    @objc public static let preBidKeywords = "prebid_keywords"
    @objc public static let refreshRate = "refresh"
    @objc public static let distanceFilter = "distance_filter"
    @objc public static let disableDebugMode = "disable_debug"

    @objc public static let impressionUrls = "impression_urls"
    @objc public static let clickUrls = "click_urls"
    @objc public static let selectedUrls = "selected_urls"
    @objc public static let handoffUrls = "handoff_urls"
    @objc public static let expireUrls = "expire_urls"
    @objc public static let lossUrls = "loss_urls"
    @objc public static let errorUrl = "error_url"
    @objc public static let reserved = "reserved"

    public class Winner: NSObject {
        @objc public static let partnerName = "partner"
        @objc public static let partnerPlacementID = "partner_placement_id"
        @objc public static let usePartnerRendering = "use_partner_rendering"
        @objc public static let creativeType = "creative_type"
        @objc public static let auctionPrice = "auction_price"
    }
}

/// Core API type that will contain the result of a bid request call to the MAX ad server.
public class MAXAdResponse: NSObject {

    @objc public let adUnitId: String
    
    private let data: Data
    private let response: NSDictionary

    @objc public override var description: String {
        return String(describing: response)
    }

    @objc public override init() {
        self.adUnitId = ""
        self.data = Data()
        self.response = [:]
    }

    @objc public init(adUnitId: String, data: Data) throws {
        self.adUnitId = adUnitId
        self.data = data

        // swiftlint:disable force_cast
        self.response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
        // swiftlint:enable force_cast

        // Give the ability to reset the location tracking distance filter from the server
        if let distanceFilter = self.response[MAXAdResponseParameters.distanceFilter] as? Double {
            MAXLogger.debug("Setting the distance filter from the server response")
            MAXLocationProvider.shared.setDistanceFilter(distanceFilter)
        }

        if let sessionExpirationInterval = self.response["session_expiration_interval"] as? Double {
            MAXSessionManager.shared.sessionExpirationIntervalSeconds = sessionExpirationInterval
        }

        // Give the ability to reset the error url to something the server provides
        if let errorUrl = self.response[MAXAdResponseParameters.errorUrl] as? String {
            if let url = URL(string: errorUrl) {
                MAXLogger.debug("Reset the error reporter url")
                MAXErrorReporter.shared.setUrl(url: url)
            }
        }
    }

    private let defaultExpirationIntervalSeconds: Double = 60.0*60.0

    /// The ad response is only valid for `expirationIntervalSeconds` seconds, by default set to 60 minutes.
    /// After this time period has elapsed, the ad response is no longer considered valid for rendering
    /// and the object's `trackExpired` method will be called if an attempt is made to render this ad.
    @objc public var expirationIntervalSeconds: Double {
        if let expirationInterval = self.response["expiration_interval"] as? Double {
            return expirationInterval
        }

        return self.defaultExpirationIntervalSeconds
    }

    /// `autoRefreshInterval` specifies an amount of time that should elapse after the loading of this
    /// ad, after which a new ad should be loaded from the server.
    @objc public var autoRefreshInterval: NSNumber? {
        if let refresh = self.response[MAXAdResponseParameters.refreshRate] as? Int {
            return NSNumber(value: refresh)
        } else {
            MAXLogger.debug("Refresh interval not set in ad response")
            return nil
        }
    }

    /// `preBidKeywords` will contain the set of keywords that will allow this response to be matched with
    /// a line item or campaign in an SSP.
    @objc public var preBidKeywords: String {
        if let _ = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return self.response[MAXAdResponseParameters.preBidKeywords] as? String ?? ""
        }

        return ""
    }

    @objc public var creativeType: String {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.creativeType] as? String ?? "empty"
        }

        return "empty"
    }

    @objc public var creative: String? {
        return self.response[MAXAdResponseParameters.creative] as? String
    }

    @objc public var partnerName: String? {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.partnerName] as? String ?? ""
        }

        return ""
    }

    @objc public var partnerPlacementID: String? {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.partnerPlacementID] as? String
        }

        return nil
    }

    @objc public var usePartnerRendering: Bool {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.usePartnerRendering] as? Bool ?? false
        }

        return false
    }
    
    @objc public var winningPrice: Int {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.auctionPrice] as? Int ?? 0
        }
        
        return 0
    }

    public var isReserved: Bool {
        if let reserved = self.response[MAXAdResponseParameters.reserved] as? Bool {
            return reserved
        }
        
        return false
    }

    @objc public func getSession() -> URLSession {
         return URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "MAXAdResponse"))
    }

    // Refresh operations
    @objc public func shouldAutoRefresh() -> Bool {
        if let autoRefreshInterval = self.autoRefreshInterval {
            return autoRefreshInterval.intValue > 0
        } else {
            return false
        }
    }

    /// Fires an impression tracking event for this AdResponse
    @objc public func trackImpression() {
        MAXLogger.debug("trackImpression called")
        self.trackAll(self.response[MAXAdResponseParameters.impressionUrls] as? NSArray)
    }

    /// Fires a click tracking event for this AdResponse
    @objc public func trackClick() {
        MAXLogger.debug("trackClick called")
        self.trackAll(self.response[MAXAdResponseParameters.clickUrls] as? NSArray)
    }

    /// Fires a selected tracking event for this AdResponse. This is used when the AdResponse is
    /// selected for display through a containing SSP.
    @objc public func trackSelected() {
        MAXLogger.debug("trackSelected called")
        self.trackAll(self.response[MAXAdResponseParameters.selectedUrls] as? NSArray)
    }

    /// Fires a handoff event for this AdResponse, which tracks when we've handed off control to the SSP
    /// SDK and the SSP SDK is about to make an ad request to the SSP ad server.
    @objc public func trackHandoff() {
        MAXLogger.debug("trackHandoff called")
        self.trackAll(self.response[MAXAdResponseParameters.handoffUrls] as? NSArray)
    }

    /// Fires an expire tracking event for this AdResponse. This should be used when the AdResponse value
    /// has been in the ad cache for longer than the expiry time.
    @objc public func trackExpired() {
        MAXLogger.debug("trackExpired called")
        self.trackAll(self.response[MAXAdResponseParameters.expireUrls] as? NSArray)
    }

    /// Fires a loss tracking event for this AdResponse. This is called when a new AdResponse for the same
    /// MAX ad unit ID is received.
    @objc public func trackLoss() {
        MAXLogger.debug("trackLoss called")
        self.trackAll(self.response[MAXAdResponseParameters.lossUrls] as? NSArray)
    }

    private func trackAll(_ urls: NSArray?) {
        guard let trackingUrls = urls else {
            return
        }
        for case let t as String in trackingUrls {
            if let url = URL(string: t) {
                self.track(url)
            }
        }
    }

    private func track(_ url: URL) {
        MAXLogger.debug("MAX: tracking URL fired ==> \(url)")
        getSession().dataTask(with: url).resume()
    }
}
