//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation
import StoreKit

let MAXAdResponseURLSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "MAXAdResponse"))

open class MAXAdResponse {
    open var createdAt : Date!
    open var data : Data!
    open var response : NSDictionary!
    
    private var winner : NSDictionary?
    
    open var preBidKeywords : String! = ""
    
    open var autoRefreshInterval: Int?

    open var creativeType : String! = "empty"
    open var creative : String? = ""
    
    public init() {
        self.createdAt = Date()
        self.data = Data()
        self.response = [:]
    }
    
    public init(data: Data) throws {
        self.createdAt = Date()
        self.data = data
        self.response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
        
        self.winner = self.response["ad_source_response"] as? NSDictionary
        self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
        self.autoRefreshInterval = self.response["refresh"] as? Int
        
        if let winner = self.winner {
            self.creativeType = winner["creative_type"] as? String ?? "empty"
            self.creative = winner["creative"] as? String
        }
    }
    
    // 
    // Refresh operations
    open func shouldAutoRefresh() -> Bool {
        if let autoRefreshInterval = self.autoRefreshInterval {
            return autoRefreshInterval > 0
        } else {
            return false
        }
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
        NSLog("MAXAdResponse.track() => \(url)")
        MAXAdResponseURLSession.dataTask(with: url).resume()
    }
    
}
