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

@objc(MAXMoPubStackBannerCustomEvent)
public class MAXMoPubStackBannerCustomEvent : MPBannerCustomEvent, MPPrivateBannerCustomEventDelegate {
    private var config : MPAdConfiguration!
    
    override public func requestAdWithSize(size: CGSize, customEventInfo info: [NSObject : AnyObject]!) {
        guard let adUnitID = info["adunit_id"] as? String,
            let adResponse = MAXPreBids[adUnitID] else {
                NSLog("MAX pre-bid was not found")
                return
        }
        
        // only allow pre-bid to be used once
        MAXPreBids[adUnitID] = nil

        // throw this over to the mopub rendering stack
        
        self.config = MPAdConfiguration(headers: [kAdTypeHeaderKey : kAdTypeMraid,
                                                    kWidthHeaderKey : size.width,
                                                    kHeightHeaderKey : size.height],
                                        data: adResponse.creative?.dataUsingEncoding(NSUTF8StringEncoding))
        switch adResponse.creativeType {
        case "html":
            let event = MPMRAIDBannerCustomEvent()
            event.delegate = self
            event.requestAdWithSize(size, customEventInfo: info)
        default:
            return
            
        }
 
    }
    
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.delegate.viewControllerForPresentingModalView()
    }
    public func location() -> CLLocation! {
        return self.delegate.location()
    }
    public func bannerCustomEventDidFinishAction(event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventDidFinishAction(event)
    }
    public func bannerCustomEventWillBeginAction(event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventWillBeginAction(event)
    }
    public func bannerCustomEventWillLeaveApplication(event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventWillLeaveApplication(event)
    }
    public func bannerCustomEvent(event: MPBannerCustomEvent!, didLoadAd ad: UIView!) {
        self.delegate.bannerCustomEvent(event, didLoadAd: ad)
    }
    public func bannerCustomEvent(event: MPBannerCustomEvent!, didFailToLoadAdWithError error: NSError!) {
        self.delegate.bannerCustomEvent(event, didFailToLoadAdWithError: error)
    }
    public func trackClick() {
        self.delegate.trackClick()
    }
    public func trackImpression() {
        self.delegate.trackImpression()
    }
    
    public func adUnitId() -> String! {
        return "Cool"
    }
    public func configuration() -> MPAdConfiguration! {
        return self.config
    }
    public func bannerDelegate() -> AnyObject! {
        return self.delegate
    }
    
}

@objc(MAXMoPubInterstitialCustomEvent)
public class MAXMoPubInterstitialCustomEvent : MPInterstitialCustomEvent, MAXInterstitialAdDelegate {
    private var MAXInterstitial : MAXInterstitialAd?
    
    override public func requestInterstitialWithCustomEventInfo(info: [NSObject : AnyObject]!) {
        guard let adUnitID = info["adunit_id"] as? String,
            let adResponse = MAXPreBids[adUnitID] else {
                NSLog("MAX interstitial pre-bid was not found")
                self.MAXInterstitial = nil
                self.delegate.interstitialCustomEventDidExpire(self)
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
            NSLog("MAX interstitial ad was not loaded")
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
