import Foundation

public class MAXAdResponse : NSObject {
    private let data : Data
    private let response : NSDictionary
    
    public let preBidKeywords : String
    var autoRefreshInterval: Int?

    let creativeType : String
    var creative : String?

    /// The ad response is only valid for `timeoutIntervalSeconds` seconds, by default set to 60 minutes.
    /// After this time period has elapsed, the ad response is no longer considered valid for rendering
    /// and the object's `trackExpired` method will be called if an attempt is made to render this ad.
    public var expirationIntervalSeconds: Double = 60.0*60.0
    
    open override var description: String { return String(describing: response) }
    
    public override init() {
        self.data = Data()
        self.response = [:]
        self.preBidKeywords = ""
        self.creativeType = "empty"
    }
    
    public init(data: Data) throws {
        self.data = data
        self.response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary

        if let refresh = self.response["refresh"] as? Int {
            self.autoRefreshInterval = refresh
        } else {
            MAXLog.debug("Refresh interval not set in ad response")
        }

        if let distanceFilter = self.response["distance_filter"] as? Double {
            MAXLocationProvider.shared.setDistanceFilter(distanceFilter)
        }

        // Give the ability to disable debug mode from a server response in case a client deploys
        // their app with debug mode enabled
        if let _ = self.response["disable_debug"] {
            MAXConfiguration.shared.disableDebugMode()
        }
        
        if let winner = self.response["winner"] as? NSDictionary {
            self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
            self.creative = self.response["creative"] as? String
            self.creativeType = winner["creative_type"] as? String ?? "empty"
            
            if let expirationInterval = self.response["expiration_interval"] as? Double {
                self.expirationIntervalSeconds = expirationInterval
            }
            
            if let expirationInterval = winner["expiration_interval"] as? Int {
                self.expirationIntervalSeconds = Double(expirationInterval)
            }
        } else {
            self.preBidKeywords = ""
            self.creativeType = "empty"
        }

        if let errorUrl = self.response["error_url"] as? String {
            if let url = URL(string: errorUrl) {
                MAXErrorReporter.shared.setUrl(url: url)
            }
        }
    }

    func getSession() -> URLSession {
         return URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "MAXAdResponse"))
    }

    func getCustomEventClass(name: String) -> NSObject.Type? {
        return NSClassFromString(name) as? NSObject.Type
    }

    //
    // Refresh operations
    //
    open func shouldAutoRefresh() -> Bool {
        if let autoRefreshInterval = self.autoRefreshInterval {
            return autoRefreshInterval > 0
        } else {
            return false
        }
    }
    
    //
    // Returns a native handler instance for a network handoff creative type
    //
    open func networkHandlerFromCreative() -> (AnyObject?, [AnyHashable : Any]?) {
        guard self.creativeType == "network" else {
            return (nil, nil)
        }
        
        // In this case the creative is a JSON block that we use to generate the
        // proxy custom event and any accompanying info.
        guard let creativeData = self.creative?.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: creativeData) as? [String: Any] else {
                MAXLog.error("MAX: proxy bid had invalid creative JSON")
                MAXErrorReporter.shared.logError(message: "Proxy bid had invalid creative JSON")
                return (nil, nil)
        }

        // pass along to our proxy custom event
        guard let customEventClassName = json?["custom_event_class"] as? String,
            let customEventClass = getCustomEventClass(name: customEventClassName),
            let customEventInfo = json?["custom_event_info"] as? [AnyHashable : Any] else {
                MAXLog.error("MAX: proxy bid has missing or invalid custom event properties")
                MAXErrorReporter.shared.logError(message: "Proxy bid had missing or invalid custom event properties")
                return (nil, nil)
        }
        
        return (customEventClass.init(), customEventInfo)
    }
    
    // Fires an impression tracking event for this AdResponse
    public func trackImpression() {
        self.trackAll(self.response["impression_urls"] as? NSArray)
    }

    // Fires a click tracking event for this AdResponse
    public func trackClick() {
        self.trackAll(self.response["click_urls"] as? NSArray)
    }

    // Fires a selected tracking event for this AdResponse. This is used when the AdResponse is
    // selected for display through a containing SSP.
    public func trackSelected() {
        self.trackAll(self.response["selected_urls"] as? NSArray)
    }

    // Fires an expire tracking event for this AdResponse. This should be used when the AdResponse value
    // has been in the ad cache for longer than the expiry time.
    func trackExpired() {
        self.trackAll(self.response["expire_urls"] as? NSArray)
    }

    // Fires a loss tracking event for this AdResponse. This is called when a new AdResponse for the same
    // MAX ad unit ID is received.
    func trackLoss() {
        self.trackAll(self.response["loss_urls"] as? NSArray)
    }
    
    // Fires a handoff event for this AdResponse, which tracks when we've handed off control to the SSP
    // SDK and the SSP SDK is about to make an ad request to the SSP ad server.
    public func trackHandoff() {
        self.trackAll(self.response["handoff_urls"] as? NSArray)
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
