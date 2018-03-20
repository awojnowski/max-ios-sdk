//
//  MAXMoPubBannerCustom.swift
//  MAX
//
//  Created by Bryan Boyko on 3/13/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//


import MoPub

/// `MAXMoPubInterstitialCustomEvent` provides a MoPub custom event for interstitials.
/// MoPub will use this class to hand control back to the MAX SDK when MAX has won in the MoPub waterfall.
/// See the documentation on [SSP Integration](http://docs.maxads.io/documentation/integration/ssp_integration/)
/// to ensure you integrate this properly in your waterfall.
/// NOTE: MoPub will instantiate this class based on MoPub account line item configurations

public class MAXMoPubInterstitialCustomEvent: MPInterstitialCustomEvent, MAXInterstitialAdDelegate, MPInterstitialCustomEventDelegate {
    
    private var MAXInterstitial: MAXInterstitialAd?
    private var customEventInstance: MPInterstitialCustomEvent?
    
    override open func requestInterstitial(withCustomEventInfo info: [AnyHashable: Any]!) {
        self.MAXInterstitial = nil
        
        guard let adUnitID = info["adunit_id"] as? String else {
            MAXLog.error("AdUnitID not specified in adunit_id customEventInfo block: \(info)")
            self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }
        
        guard let adResponse = MAXAds.getPreBid(adUnitID: adUnitID) else {
            MAXLog.error("Pre-bid not found for adUnitId: \(adUnitID)")
            self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }
        
        // Inform MAX system that we won in the waterfall
        adResponse.trackSelected()
        
        // generate interstitial object from the pre-bid,
        // connect delegate and tell MoPub SDK that the interstitial has been loaded
        let MAXInterstitial = MAXInterstitialAd(requestManager: MAXAdRequestManager(), sessionManager: MAXSessionManager.shared)
        self.MAXInterstitial = MAXInterstitial
        MAXInterstitial.delegate = self
        MAXInterstitial.load(adUnitId: adUnitID)
        MAXLog.debug("Interstitial for \(adUnitID) found and loaded")
    }
    
    override open func showInterstitial(fromRootViewController rootViewController: UIViewController!) {
        MAXLog.debug("MAXMoPubInterstitialCustomEvent.showInterstitial()")
        if let customEventInstance = self.customEventInstance {
            customEventInstance.showInterstitial(fromRootViewController: rootViewController)
        } else {
            guard let interstitial = MAXInterstitial else {
                MAXLog.error("Interstitial ad was not loaded, calling interstitialCustomEventDidExpire")
                self.delegate.interstitialCustomEventDidExpire(self)
                return
            }
            
            MAXLog.debug("InterstitialCustomEventWillAppear")
            self.delegate.interstitialCustomEventWillAppear(self)
            
            interstitial.showAdFromRootViewController(rootViewController)
            
            MAXLog.debug("InterstitialCustomEventDidAppear")
            self.delegate.interstitialCustomEventDidAppear(self)
        }
    }
    
    // MARK: MAXInterstitialAdDelegate
    
    public func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidLoad")
        self.delegate.interstitialCustomEvent(self, didLoadAd: MAXInterstitial)
    }
    
    public func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidClick")
        self.delegate.interstitialCustomEventDidReceiveTap(self)
    }
    
    public func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdWillClose")
        self.delegate.interstitialCustomEventWillDisappear(self)
    }
    
    public func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidClose")
        self.delegate.interstitialCustomEventDidDisappear(self)
    }
    
    public func interstitial(_ interstitialAd: MAXInterstitialAd?, didFailWithError error: MAXClientError) {
        MAXLog.debug("MAX: interstitial:didFailWithError: \(error.message)")
        self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: error.asNSError())
    }
    
    // MARK: MPInterstitialCustomEventDelegate
    
    @available(iOS 2.0, *)
    public func location() -> CLLocation! {
        return self.delegate.location()
    }
    
    public func trackClick() {
        self.delegate.trackClick()
    }
    
    public func trackImpression() {
        self.delegate.trackImpression()
    }
    
    public func interstitialCustomEventDidAppear(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventDidAppear(customEvent)
    }
    
    public func interstitialCustomEventDidExpire(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventDidExpire(customEvent)
    }
    
    public func interstitialCustomEventWillAppear(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventWillAppear(customEvent)
    }
    
    public func interstitialCustomEventDidDisappear(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventDidDisappear(customEvent)
    }
    
    public func interstitialCustomEventDidReceiveTap(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventDidReceiveTap(customEvent)
    }
    
    public func interstitialCustomEventWillDisappear(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventWillDisappear(customEvent)
    }
    
    // swiftlint:disable identifier_name
    public func interstitialCustomEvent(_ customEvent: MPInterstitialCustomEvent!, didLoadAd ad: Any!) {
        self.delegate.interstitialCustomEvent(customEvent, didLoadAd: ad)
    }
    // swiftlint:enable identifier_name
    
    public func interstitialCustomEventWillLeaveApplication(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventWillLeaveApplication(customEvent)
    }
    
    public func interstitialCustomEvent(_ customEvent: MPInterstitialCustomEvent!, didFailToLoadAdWithError error: Error!) {
        self.delegate.interstitialCustomEvent(customEvent, didFailToLoadAdWithError: error)
    }
}

