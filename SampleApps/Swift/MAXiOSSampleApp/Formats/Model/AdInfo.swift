//
//  AdFormat.swift
//  MAXiOSSampleApp
//
//  Created by Bryan Boyko on 1/23/18.
//  Copyright © 2018 MAXAds. All rights reserved.
//

import UIKit

class AdInfo {
    
    let maxId: String
    let mopubId: String
    let size: CGSize
    
    init(maxId: String, mopubId: String, size: CGSize) {
        self.maxId = maxId
        self.mopubId = mopubId
        self.size = size
    }
}
