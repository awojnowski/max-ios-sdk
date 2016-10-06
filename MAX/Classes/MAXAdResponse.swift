//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation

public class MAXAdResponse {
    public var response : NSDictionary!
    
    public init(data: NSData) throws {
        self.response = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary
        NSLog("\(self.response)")
    }
}