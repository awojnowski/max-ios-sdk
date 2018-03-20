//
//  MAXBannerControllerMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
import MoPub
@testable import MAX

internal class MAXBannerControllerMock: MAXBannerController {
    
    // snipe requestManager from parent class
    private let requestManager: MAXAdRequestManagerMock

    internal var adShown = false
    
    override internal init(bannerAdView: UIView, requestManager: MAXAdRequestManager, sessionManager: MAXSessionManager) {
        self.requestManager = requestManager as! MAXAdRequestManagerMock
        super.init(bannerAdView: bannerAdView, requestManager: requestManager, sessionManager: sessionManager)
    }
    
    override internal func showAd(maxAdResponse: MAXAdResponse) {
        adShown = true
    }
    
    override public func onRequestSuccess(adResponse: MAXAdResponse?) {
        // bypass main queue used in super class onRequestSuccess
        super.loadResponse(adResponse: adResponse!)
    }
    
    override public func onRequestFailed(error: NSError?) {
        requestManager.refreshTimerStarted = true
        // bypass main queue used in super class onRequestSuccess
        requestManager.startRefreshTimerInternal(delay: 0)
    }
}
