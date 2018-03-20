//
//  MAXAdViewAdapterStub.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

class MAXAdViewAdapterStub: MAXAdViewAdapter {
    var didLoadAd = false
    override func loadAd() {
        self.adView = UIView()
        didLoadAd = true
        self.delegate?.adViewDidLoad(self)
    }
}
