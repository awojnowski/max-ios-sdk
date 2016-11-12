//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation

let MAXAdResponseURLSession = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("MAXAdResponse"))

public class MAXAdResponse {
    public var createdAt : NSDate!
    public var data : NSData!
    public var response : NSDictionary!
    
    private var winner : NSDictionary?
    
    public var preBidKeywords : String!

    public var creativeType : String!
    public var creative : String?
    
    public init() {
        self.createdAt = NSDate()
        self.data = NSData()
        self.response = [:]
    }
    
    public init(data: NSData) throws {
        self.createdAt = NSDate()
        self.data = data
        self.response = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary
        
        self.winner = self.response["ad_source_response"] as? NSDictionary
        self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
        
        if let winner = self.winner {
            self.creativeType = winner["creative_type"] as? String ?? "empty"
            self.creative = winner["creative"] as? String
        } else {
            self.creativeType = "empty"
            self.creative = ""
        }
    }
    
    // 
    // Fires an impression tracking event for this AdResponse
    //
    public func trackImpression() {
        if let trackingUrl = self.response["impression_url"] as? String,
            url = NSURL(string: trackingUrl) {
            self.track(url)
        }
    }

    //
    // Fires a click tracking event for this AdResponse
    //
    public func trackClick() {
        if let trackingUrl = self.response["click_url"] as? String,
            url = NSURL(string: trackingUrl) {
            self.track(url)
        }
        
    }
    
    // 
    // Handles a click out by opening the platform browser and also
    // tracking the click event
    //
    public func handleClick(url: NSURL) {
        self.trackClick()
        
        // TODO: handle StoreKit
        //
        UIApplication.sharedApplication().openURL(url)
    }

    private func track(url: NSURL) {
        NSLog("MAXAdResponse.track() => \(url)")        
        MAXAdResponseURLSession.dataTaskWithURL(url).resume()
    }
    
}
