//
//  MAXAdUnitScore.swift
//  MAX
//
//  Created by Bryan Boyko on 2/28/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

public class MAXAdUnitScore: NSObject {
    
    let adUnitId: String
    
    public init(adUnitId: String) {
        self.adUnitId = adUnitId
        super.init()
    }
    
    @objc public internal(set) var maxSessionDepth = NSNumber()
    @objc public internal(set) var sspSessionDepth = NSNumber()
    
    @objc public var dict: Dictionary<String, Any> {
        let d: Dictionary<String, Any> = [
            "max_score" : maxSessionDepth.intValue,
            "ssp_score" : sspSessionDepth.intValue
        ]
        return d
    }
    
    //MARK: Overrides
    
    public override var description: String {
        return "adUnitId: \(adUnitId)\n maxSessionDepth: \(maxSessionDepth.intValue)\n sspSessionDepth: \(sspSessionDepth.intValue)"
    }
}
