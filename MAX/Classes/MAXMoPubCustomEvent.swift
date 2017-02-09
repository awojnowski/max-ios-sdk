//
//  MAXMoPubCustomEvent.swift
//

import Foundation
import MAX
import MoPub

@objc(MAXMoPubBannerCustomEvent)
open class MAXMoPubBannerCustomEvent : MPBannerCustomEvent, MAXAdViewDelegate  {
    private var adView : MAXAdView?
    
    override open func requestAd(with size: CGSize, customEventInfo info: [AnyHashable: Any]!) {
        guard let adUnitID = info["adunit_id"] as? String else {
            NSLog("MAX: AdUnitID not specified in adunit_id customEventInfo block: \(info)")
            return
        }
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }

        guard let adResponse = MAXPreBids[adUnitID] else {
            NSLog("MAX: banner pre-bid was not found for adUnitID=\(adUnitID)")
            self.adView = nil
            self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }
        
        // generate View object from the AdResponse
        self.adView = MAXAdView(adResponse: adResponse, size: size)
        self.adView?.loadAd()
        self.delegate.bannerCustomEvent(self, didLoadAd: self.adView)
        NSLog("MAX: banner for \(adUnitID) found and loaded")
    }
    
    open func adViewDidLoad(_ adView: MAXAdView) {
        NSLog("MAX: adViewDidLoad")
        self.delegate.bannerCustomEvent(self, didLoadAd: adView)
    }
    open func adViewDidClick(_ adView: MAXAdView) {
        NSLog("MAX: adViewDidClick")
        self.delegate.bannerCustomEventWillLeaveApplication(self)
    }
    open func adViewWillLogImpression(_ adView: MAXAdView) {
        NSLog("MAX: adViewWillLogImpression")
    }
    open func adViewDidFinishHandlingClick(_ adView: MAXAdView) {
        NSLog("MAX: adViewDidFinishHandlingClick")
        self.delegate.bannerCustomEventDidFinishAction(self)
    }
    open func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?) {
        NSLog("MAX: adViewDidFailWithError")
        self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: error)
    }
    open var viewControllerForPresentingModalView: UIViewController {
        return self.delegate.viewControllerForPresentingModalView()
    }
}

@objc(MAXMoPubInterstitialCustomEvent)
open class MAXMoPubInterstitialCustomEvent : MPInterstitialCustomEvent, MAXInterstitialAdDelegate {
    private var MAXInterstitial : MAXInterstitialAd?
    
    override open func requestInterstitial(withCustomEventInfo info: [AnyHashable: Any]!) {
        NSLog("MAX: MAXMoPubInterstitialCustomEvent.requestInterstitial()")
        guard let adUnitID = info["adunit_id"] as? String else {
            NSLog("MAX: No adunit_id found in customEventInfo \(info)")
            return
        }
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }

        guard let adResponse = MAXPreBids[adUnitID] else {
            NSLog("MAX: interstitial pre-bid was not found for adUnitID=\(adUnitID)")
            self.MAXInterstitial = nil
            self.delegate.interstitialCustomEvent(self,
                                                  didFailToLoadAdWithError: MAXPreBidErrors[adUnitID] ?? NSError(domain: MAXAdRequest.ADS_DOMAIN, code: 0, userInfo: [:]))
            return
        }
        
        // generate interstitial object from the pre-bid,
        // connect delegate and tell MoPub SDK that the interstitial has been loaded
        self.MAXInterstitial = MAXInterstitialAd(adResponse: adResponse)
        self.MAXInterstitial!.delegate = self
        self.delegate.interstitialCustomEvent(self, didLoadAd: self.MAXInterstitial!)
        NSLog("MAX: interstitial for \(adUnitID) found and loaded")
    }
    
    override open func showInterstitial(fromRootViewController rootViewController: UIViewController!) {
        NSLog("MAX: MAXMoPubInterstitialCustomEvent.showInterstitial()")
        guard let interstitial = MAXInterstitial else {
            NSLog("MAX: interstitial ad was not loaded, calling interstitialCustomEventDidExpire")
            self.delegate.interstitialCustomEventDidExpire(self)
            return
        }
        
        NSLog("MAX: interstitialCustomEventWillAppear");
        self.delegate.interstitialCustomEventWillAppear(self)
        
        interstitial.showAdFromRootViewController(rootViewController)
        
        NSLog("MAX: interstitialCustomEventDidAppear");
        self.delegate.interstitialCustomEventDidAppear(self)
        
    }
    
    // MAXInterstitialAdDelegate
    
    open func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        NSLog("MAX: interstitialAdDidClick")
        self.delegate.interstitialCustomEventDidReceiveTap(self)
    }
    
    open func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        NSLog("MAX: interstitialAdWillClose")
        self.delegate.interstitialCustomEventWillDisappear(self)
    }
    
    open func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        NSLog("MAX: interstitialAdDidClose")
        self.delegate.interstitialCustomEventDidDisappear(self)
    }
}
