//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation

public class MAXAdResponse {
    public var createdAt : NSDate!
    public var data : NSData!
    public var response : NSDictionary!
    
    public init(data: NSData) throws {
        self.createdAt = NSDate()
        self.data = data
        self.response = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary
        NSLog("\(self.response)")
    }
    
    public func preBidKeywords() -> String {
        if let winner = self.response["ad_source_response"] as? NSDictionary {
            return self.response["prebid_keywords"] as? String ?? ""
        } else {
            return ""
        }
    }
}
