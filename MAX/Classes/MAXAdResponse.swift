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
    open var response : NSDictionary!
    
    open var winner : NSDictionary!
    
    open var preBidKeywords : String! = ""
    open var autoRefreshInterval: Int?

    open var creative : String!
    open var creativeType : String! = "empty"
    
    public init() {
        self.createdAt = Date()
        self.response = [:]
    }
    
    public init(data: Data) throws {
        self.createdAt = Date()
        self.response = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
        
        self.winner = self.response["winner"] as? NSDictionary ?? [:]
        self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
        self.autoRefreshInterval = self.response["refresh"] as? Int
        self.creative = self.response["creative"] as? String
        self.creativeType = self.winner["creative_type"] as? String ?? "empty"
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
