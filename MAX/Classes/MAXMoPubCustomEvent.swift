//
//  MAXMoPubCustomEvent.swift
//

import Foundation
import MoPub

@objc(MAXMoPubBannerCustomEvent)
open class MAXMoPubBannerCustomEvent : MPBannerCustomEvent, MAXAdViewDelegate  {
    private var adView : MAXAdView?
    
    override open func requestAd(with size: CGSize, customEventInfo info: [AnyHashable: Any]!) {
        guard let adUnitID = info["adunit_id"] as? String else {
            MAXLog.error("MAX: AdUnitID not specified in adunit_id customEventInfo block: \(info)")
            return
        }
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }

        guard let adResponse = MAXPreBids[adUnitID] else {
            MAXLog.error("MAX: banner pre-bid was not found for adUnitID=\(adUnitID)")
            self.adView = nil
            self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }
        
        // generate View object from the AdResponse
        self.adView = MAXAdView(adResponse: adResponse, size: size)
        self.adView?.loadAd()
        self.delegate.bannerCustomEvent(self, didLoadAd: self.adView)
        MAXLog.debug("MAX: banner for \(adUnitID) found and loaded")
    }
    
    open func adViewDidLoad(_ adView: MAXAdView) {
        MAXLog.debug("MAX: adViewDidLoad")
        self.delegate.bannerCustomEvent(self, didLoadAd: adView)
    }
    open func adViewDidClick(_ adView: MAXAdView) {
        MAXLog.debug("MAX: adViewDidClick")
        self.delegate.bannerCustomEventWillLeaveApplication(self)
    }
    open func adViewWillLogImpression(_ adView: MAXAdView) {
        MAXLog.debug("MAX: adViewWillLogImpression")
    }
    open func adViewDidFinishHandlingClick(_ adView: MAXAdView) {
        MAXLog.debug("MAX: adViewDidFinishHandlingClick")
        self.delegate.bannerCustomEventDidFinishAction(self)
    }
    open func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?) {
        MAXLog.debug("MAX: adViewDidFailWithError")
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
        MAXLog.debug("MAX: MAXMoPubInterstitialCustomEvent.requestInterstitial()")
        guard let adUnitID = info["adunit_id"] as? String else {
            MAXLog.error("MAX: No adunit_id found in customEventInfo \(info)")
            return
        }
        defer {
            // only allow pre-bid to be used once
            MAXPreBids[adUnitID] = nil
            MAXPreBidErrors[adUnitID] = nil
        }

        guard let adResponse = MAXPreBids[adUnitID] else {
            MAXLog.error("MAX: interstitial pre-bid was not found for adUnitID=\(adUnitID)")
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
        MAXLog.debug("MAX: interstitial for \(adUnitID) found and loaded")
    }
    
    override open func showInterstitial(fromRootViewController rootViewController: UIViewController!) {
        MAXLog.debug("MAX: MAXMoPubInterstitialCustomEvent.showInterstitial()")
        guard let interstitial = MAXInterstitial else {
            MAXLog.error("MAX: interstitial ad was not loaded, calling interstitialCustomEventDidExpire")
            self.delegate.interstitialCustomEventDidExpire(self)
            return
        }
        
        MAXLog.debug("MAX: interstitialCustomEventWillAppear");
        self.delegate.interstitialCustomEventWillAppear(self)
        
        interstitial.showAdFromRootViewController(rootViewController)
        
        MAXLog.debug("MAX: interstitialCustomEventDidAppear");
        self.delegate.interstitialCustomEventDidAppear(self)
        
    }
    
    // MAXInterstitialAdDelegate
    
    open func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidClick")
        self.delegate.interstitialCustomEventDidReceiveTap(self)
    }
    
    open func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdWillClose")
        self.delegate.interstitialCustomEventWillDisappear(self)
    }
    
    open func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidClose")
        self.delegate.interstitialCustomEventDidDisappear(self)
    }
}
