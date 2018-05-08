//
//  MAXAdUnitScore.swift
//  MAX
//
//  Created by Bryan Boyko on 2/28/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

internal class MAXAdUnitScore: NSObject {
    
    let adUnitId: String
    
    internal init(adUnitId: String) {
        self.adUnitId = adUnitId
        super.init()
    }
    
    internal var maxSessionDepth = NSNumber()
    internal var sspSessionDepth = NSNumber()
    
    internal var dict: Dictionary<String, Any> {
        let d: Dictionary<String, Any> = [
            "max_score" : maxSessionDepth.intValue,
            "ssp_score" : sspSessionDepth.intValue
        ]
        return d
    }
    
    //MARK: Overrides
    
    internal override var description: String {
        return "adUnitId: \(adUnitId)\n maxSessionDepth: \(maxSessionDepth.intValue)\n sspSessionDepth: \(sspSessionDepth.intValue)"
    }
}
