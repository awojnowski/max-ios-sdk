//
//  MAXMoPubCustomEvent.swift
//
//  Copyright © 2016 MoLabs Inc. All rights reserved.
//

import Foundation
import MAX
import MoPub

@objc(MAXMoPubBannerCustomEvent)
public class MAXMoPubBannerCustomEvent : MPBannerCustomEvent, MAXAdViewDelegate  {
    private var adView : MAXAdView?
    
    override public func requestAdWithSize(size: CGSize, customEventInfo info: [NSObject : AnyObject]!) {
        guard let adUnitID = info["adunit_id"] as? String,
            let adResponse = MAXPreBids[adUnitID] else {
                NSLog("MAX banner pre-bid was not found")
                self.adView = nil
                self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
                return
        }
        
        // only allow pre-bid to be used once
        MAXPreBids[adUnitID] = nil
        
        // generate View object from the AdResponse
        self.adView = MAXAdView(adResponse: adResponse, size: size)
        self.adView?.loadAd()
        self.delegate.bannerCustomEvent(self, didLoadAd: self.adView)
        NSLog("MAX banner for \(adUnitID) found and loaded")
    }
    
    public func adViewDidLoad(adView: MAXAdView) {
        NSLog("adViewDidLoad")
        self.delegate.bannerCustomEvent(self, didLoadAd: adView)
    }
    public func adViewDidClick(adView: MAXAdView) {
        NSLog("adViewDidClick")
        self.delegate.bannerCustomEventWillLeaveApplication(self)
    }
    public func adViewWillLogImpression(adView: MAXAdView) {
        NSLog("adViewWillLogImpression")
    }
    public func adViewDidFinishHandlingClick(adView: MAXAdView) {
        NSLog("adViewDidFinishHandlingClick")
        self.delegate.bannerCustomEventDidFinishAction(self)
    }
    public func adViewDidFailWithError(adView: MAXAdView, error: NSError?) {
        NSLog("adViewDidFailWithError")
        self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: error)
    }
    public var viewControllerForPresentingModalView: UIViewController {
        return self.delegate.viewControllerForPresentingModalView()
    }
}

@objc(MAXMoPubInterstitialCustomEvent)
public class MAXMoPubInterstitialCustomEvent : MPInterstitialCustomEvent, MAXInterstitialAdDelegate {
    private var MAXInterstitial : MAXInterstitialAd?
    
    override public func requestInterstitialWithCustomEventInfo(info: [NSObject : AnyObject]!) {
        guard let adUnitID = info["adunit_id"] as? String else {
            NSLog("No Ad Unit ID found in Custom Event parameters")
            return
        }
        guard let adResponse = MAXPreBids[adUnitID] else {
            NSLog("MAX interstitial pre-bid was not found")
            self.MAXInterstitial = nil
            self.delegate.interstitialCustomEvent(self,
                                                  didFailToLoadAdWithError: MAXPreBidErrors[adUnitID] ?? NSError(domain: "sprl.com", code: 0, userInfo: [:]))
            return
        }
        
        // only allow pre-bid to be used once
        MAXPreBids[adUnitID] = nil
        
        // generate interstitial object from the pre-bid,
        // connect delegate and tell MoPub SDK that the interstitial has been loaded
        self.MAXInterstitial = MAXInterstitialAd(adResponse: adResponse)
        self.MAXInterstitial!.delegate = self
        self.delegate.interstitialCustomEvent(self, didLoadAd: self.MAXInterstitial!)
        NSLog("MAX interstitial for \(adUnitID) found and loaded")
    }
    
    override public func showInterstitialFromRootViewController(rootViewController: UIViewController!) {
        guard let interstitial = MAXInterstitial else {
            NSLog("MAX interstitial ad was not loaded when show was called, expiring.")
            self.delegate.interstitialCustomEventDidExpire(self)
            return
        }
        
        NSLog("MAX interstitial ad will be presented");
        self.delegate.interstitialCustomEventWillAppear(self)
        
        interstitial.showAdFromRootViewController(rootViewController)
        
        NSLog("MAX interstitial ad was presented");
        self.delegate.interstitialCustomEventDidAppear(self)
        
    }
    
    // MAXInterstitialAdDelegate
    
    public func interstitialAdDidClick(interstitialAd: MAXInterstitialAd) {
        NSLog("MAX interstitial ad was clicked")
        self.delegate.interstitialCustomEventDidReceiveTapEvent(self)
    }
    
    public func interstitialAdWillClose(interstitialAd: MAXInterstitialAd) {
        NSLog("MAX interstitial ad will close")
        self.delegate.interstitialCustomEventWillDisappear(self)
    }
    
    public func interstitialAdDidClose(interstitialAd: MAXInterstitialAd) {
        NSLog("MAX interstitial ad was closed")
        self.delegate.interstitialCustomEventDidDisappear(self)
    }
}
