import Foundation

public class MAXAdResponseParameters {
    public static let winner = "winner"
    public static let creative = "creative"
    public static let preBidKeywords = "prebid_keywords"
    public static let refreshRate = "refresh"
    public static let distanceFilter = "distance_filter"
    public static let disableDebugMode = "disable_debug"

    public static let impressionUrls = "impression_urls"
    public static let clickUrls = "click_urls"
    public static let selectedUrls = "selected_urls"
    public static let handoffUrls = "handoff_urls"
    public static let expireUrls = "expire_urls"
    public static let lossUrls = "loss_urls"
    public static let errorUrl = "error_url"

    public class Winner {
        public static let partnerName = "partner"
        public static let partnerPlacementID = "partner_placement_id"
        public static let usePartnerRendering = "use_partner_rendering"
        public static let creativeType = "creative_type"
    }
}

/// Core API type that will contain the result of a bid request call to the MAX ad server.
public class MAXAdResponse: NSObject {

    private let data: Data
    private let response: NSDictionary

    public override var description: String {
        return String(describing: response)
    }

    public override init() {
        self.data = Data()
        self.response = [:]
    }

    public init(data: Data) throws {
        self.data = data

        // swiftlint:disable force_cast
        self.response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
        // swiftlint:enable force_cast

        // Give the ability to reset the location tracking distance filter from the server
        if let distanceFilter = self.response[MAXAdResponseParameters.distanceFilter] as? Double {
            MAXLog.debug("Setting the distance filter from the server response")
            MAXLocationProvider.shared.setDistanceFilter(distanceFilter)
        }

        if let sessionExpirationInterval = self.response["session_expiration_interval"] as? Double {
            MAXSession.shared.sessionExpirationIntervalSeconds = sessionExpirationInterval
        }

        // Give the ability to disable debug mode from a server response in case a client deploys
        // their app with debug mode enabled
        if let _ = self.response[MAXAdResponseParameters.disableDebugMode] {
            MAXLog.debug("Found force shutting off debug mode parameter from server. MAX will now operate normally.")
            MAXConfiguration.shared.disableDebugMode()
        }

        // Give the ability to reset the error url to something the server provides
        if let errorUrl = self.response[MAXAdResponseParameters.errorUrl] as? String {
            if let url = URL(string: errorUrl) {
                MAXLog.debug("Reset the error reporter url")
                MAXErrorReporter.shared.setUrl(url: url)
            }
        }
    }

    private let defaultExpirationIntervalSeconds: Double = 60.0*60.0

    /// The ad response is only valid for `expirationIntervalSeconds` seconds, by default set to 60 minutes.
    /// After this time period has elapsed, the ad response is no longer considered valid for rendering
    /// and the object's `trackExpired` method will be called if an attempt is made to render this ad.
    public var expirationIntervalSeconds: Double {
        if let expirationInterval = self.response["expiration_interval"] as? Double {
            return expirationInterval
        }

        return self.defaultExpirationIntervalSeconds
    }

    /// `autoRefreshInterval` specifies an amount of time that should elapse after the loading of this
    /// ad, after which a new ad should be loaded from the server.
    public var autoRefreshInterval: Int? {
        if let refresh = self.response[MAXAdResponseParameters.refreshRate] as? Int {
            return refresh
        } else {
            MAXLog.debug("Refresh interval not set in ad response")
            return nil
        }
    }

    /// `preBidKeywords` will contain the set of keywords that will allow this response to be matched with
    /// a line item or campaign in an SSP.
    public var preBidKeywords: String {
        if let _ = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return self.response[MAXAdResponseParameters.preBidKeywords] as? String ?? ""
        }

        return ""
    }

    public var creativeType: String {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.creativeType] as? String ?? "empty"
        }

        return "empty"
    }

    public var creative: String? {
        return self.response[MAXAdResponseParameters.creative] as? String
    }

    public var partnerName: String? {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.partnerName] as? String ?? ""
        }

        return ""
    }

    public var partnerPlacementID: String? {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.partnerPlacementID] as? String
        }

        return nil
    }

    public var usePartnerRendering: Bool {
        if let winner = self.response[MAXAdResponseParameters.winner] as? NSDictionary {
            return winner[MAXAdResponseParameters.Winner.usePartnerRendering] as? Bool ?? false
        }

        return false
    }

    func getSession() -> URLSession {
         return URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "MAXAdResponse"))
    }

    // Refresh operations
    public func shouldAutoRefresh() -> Bool {
        if let autoRefreshInterval = self.autoRefreshInterval {
            return autoRefreshInterval > 0
        } else {
            return false
        }
    }

    /// Fires an impression tracking event for this AdResponse
    public func trackImpression() {
        MAXLog.debug("trackImpression called")
        self.trackAll(self.response[MAXAdResponseParameters.impressionUrls] as? NSArray)
    }

    /// Fires a click tracking event for this AdResponse
    public func trackClick() {
        MAXLog.debug("trackClick called")
        self.trackAll(self.response[MAXAdResponseParameters.clickUrls] as? NSArray)
    }

    /// Fires a selected tracking event for this AdResponse. This is used when the AdResponse is
    /// selected for display through a containing SSP.
    public func trackSelected() {
        MAXLog.debug("trackSelected called")
        self.trackAll(self.response[MAXAdResponseParameters.selectedUrls] as? NSArray)
    }

    /// Fires a handoff event for this AdResponse, which tracks when we've handed off control to the SSP
    /// SDK and the SSP SDK is about to make an ad request to the SSP ad server.
    public func trackHandoff() {
        MAXLog.debug("trackHandoff called")
        self.trackAll(self.response[MAXAdResponseParameters.handoffUrls] as? NSArray)
    }

    /// Fires an expire tracking event for this AdResponse. This should be used when the AdResponse value
    /// has been in the ad cache for longer than the expiry time.
    func trackExpired() {
        MAXLog.debug("trackExpired called")
        self.trackAll(self.response[MAXAdResponseParameters.expireUrls] as? NSArray)
    }

    /// Fires a loss tracking event for this AdResponse. This is called when a new AdResponse for the same
    /// MAX ad unit ID is received.
    func trackLoss() {
        MAXLog.debug("trackLoss called")
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
        MAXLog.debug("MAX: tracking URL fired ==> \(url)")
        getSession().dataTask(with: url).resume()
    }
}
