//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation

public class MAXAdResponse {
    public var createdAt : NSDate!
    private var data : NSData!
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
        }
    }
}
