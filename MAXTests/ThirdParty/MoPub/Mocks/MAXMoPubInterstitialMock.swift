//
//  MAXMoPubInterstitialMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/12/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import MoPub

internal class MAXMoPubInterstitialMock: MAXMoPubInterstitial {
    
    override public func onRequestSuccess(adResponse: MAXAdResponse?) {
        // bypass main queue used in super class onRequestSuccess
        super.loadResponse(adResponse: adResponse!)
    }
    
    override public func onRequestFailed(error: NSError?) {
        // bypass main queue used in super class onRequestSuccess
        super.loadVanillaMoPub()
    }
}
