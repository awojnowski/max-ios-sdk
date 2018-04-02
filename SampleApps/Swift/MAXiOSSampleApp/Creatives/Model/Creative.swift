//
//  Creative.swift
//  MAXiOSSampleApp
//
//  Created by Bryan Boyko on 1/23/18.
//  Copyright © 2018 MAXAds. All rights reserved.
//

import Foundation
import MAX

class Creative {
    var name: String
    var adMarkup: String
    var format: String
    
    init(name: String, adMarkup: String, format: String) {
        self.name = name
        self.adMarkup = adMarkup
        self.format = format
    }
    
    var response: MAXAdResponse {
        get {
            var renderer: String = "html"
            if self.format == "vast" {
                renderer = "vast3"
            }
            
            let fakeResponseData: Dictionary<String, Any> = [
                "winner": ["creative_type": renderer],
                "creative": self.adMarkup
            ]
            
            let data = try! JSONSerialization.data(withJSONObject: fakeResponseData, options: [])
            let response = try! MAXAdResponse(adUnitId: "(ノಠ益ಠ)ノ彡┻━┻", data: data)
            return response
        }
    }
}
