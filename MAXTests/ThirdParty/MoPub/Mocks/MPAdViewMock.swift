//
//  MPAdViewMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
import MoPub
@testable import MAX

class MPAdViewListenerMock: NSObject, MPAdViewDelegate {
    
    var hadImpression = false
    var hadFailure = false
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return UIApplication.shared.delegate!.window!!.rootViewController
    }
    
    func adViewDidLoadAd(_ view: MPAdView!) {
        self.hadImpression = true
    }
    
    func adViewDidFail(toLoadAd view: MPAdView!) {
        self.hadFailure = true
    }
}

class MPAdViewMock: MPAdView {
    
    public var loadCalled = false
    
    override public var adUnitId: String! {
        get {
            return super.adUnitId ?? "testId"
        }
        set {
            super.adUnitId = newValue
        }
    }
    
    override func loadAd() {
        loadCalled = true
        self.delegate.adViewDidLoadAd?(self)
    }
    
    func failAd() {
        self.delegate.adViewDidFail?(toLoadAd: self)
    }
}
