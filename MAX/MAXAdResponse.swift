//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation

let MAXAdResponseURLSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "MAXAdResponse"))


open class MAXAdResponse : NSObject {
    private let data : Data
    private let response : NSDictionary
    
    public let preBidKeywords : String
    var autoRefreshInterval: Int?

    let creativeType : String
    var creative : String?
    
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
        
        if let winner = self.response["winner"] as? NSDictionary {
            self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
            self.autoRefreshInterval = self.response["refresh"] as? Int
            self.creative = self.response["creative"] as? String
            self.creativeType = winner["creative_type"] as? String ?? "empty"
        } else {
            self.preBidKeywords = ""
            self.creativeType = "empty"
        }
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
                return (nil, nil)
        }
        
        // pass along to our proxy custom event
        guard let customEventClassName = json?["custom_event_class"] as? String,
            let customEventClass = NSClassFromString(customEventClassName) as? NSObject.Type,
            let customEventInfo = json?["custom_event_info"] as? [AnyHashable : Any] else {
                MAXLog.error("MAX: proxy bid has missing or invalid custom event properties")
                return (nil, nil)
        }
        
        return (customEventClass.init(), customEventInfo)
    }
    
    //
    // Fires an impression tracking event for this AdResponse
    //
    open func trackImpression() {
        self.trackAll(self.response["impression_urls"] as? NSArray)
    }

    //
    // Fires a click tracking event for this AdResponse
    //
    open func trackClick() {
        self.trackAll(self.response["click_urls"] as? NSArray)
    }

    //
    // Fires a selected tracking event for this AdResponse
    // This is used when the AdResponse is selected for display through a
    // containing SSP
    //
    open func trackSelected() {
        self.trackAll(self.response["selected_urls"] as? NSArray)
    }

    //
    // 
    // 
    
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
        MAXAdResponseURLSession.dataTask(with: url).resume()
    }
    
}
