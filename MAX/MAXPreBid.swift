//
//  MAXPreBid.swift
//  MAX
//
//  Copyright © 2017 MAX. All rights reserved.
//

import Foundation

private var MAXPreBids : [String : MAXAdResponse] = [:]
private var MAXPreBidErrors : [String : NSError] = [:]

public class MAXPreBid {
    
    public class func receivedPreBid(adUnitID: String, response: MAXAdResponse?, error: NSError?) {
        MAXPreBids[adUnitID] = response
        MAXPreBidErrors[adUnitID] = error
    }
    
    public class func getPreBid(adUnitID: String) -> MAXAdResponse? {
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }
        
        if let error = MAXPreBidErrors[adUnitID] {
            MAXLog.error("Pre-bid error was found for adUnitID=\(adUnitID), error=\(error)")
            return nil
        }
        
        guard let adResponse = MAXPreBids[adUnitID] else {
            MAXLog.error("Pre-bid was not found for adUnitID=\(adUnitID)")
            return nil
        }
        
        return adResponse
    }
    
    
}
