//
//  MAXMoPubCustomEvent.swift
//

import Foundation
import MoPub

@objc(MAXMoPubBannerCustomEvent)
open class MAXMoPubBannerCustomEvent : MPBannerCustomEvent, MPBannerCustomEventDelegate  {

    private var adView : MAXAdView?

    private var customEventInstance : MPBannerCustomEvent?

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

        if adResponse.creativeType == "network" {
            // In this case the creative is a JSON block that we use to generate the
            // proxy custom event and any accompanying info.
            guard let creativeData = adResponse.creative.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: creativeData) as? [String: Any] else {
                    MAXLog.error("MAX: proxy bid had invalid creative JSON")
                    self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
                    return
            }
            
            // pass along to our proxy custom event
            guard let customEventClassName = json?["custom_event_class"] as? String,
                let customEventClass = NSClassFromString(customEventClassName) as? MPBannerCustomEvent.Type,
                let customEventInfo = json?["custom_event_info"] as? [AnyHashable : Any] else {
                    MAXLog.error("MAX: proxy bid has missing or invalid custom event properties")
                    self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
                    return
            }
            self.customEventInstance = customEventClass.init()
            customEventInstance?.delegate = self
            customEventInstance?.requestAd(with: size, customEventInfo: customEventInfo)
            
        } else {
            // For all other creative types, we handoff internally to our own rendering layer.
            // Generate View object from the AdResponse
            self.adView = MAXAdView(adResponse: adResponse, size: size)
            self.adView?.loadAd()
            self.delegate.bannerCustomEvent(self, didLoadAd: self.adView)
            MAXLog.debug("MAX: banner for \(adUnitID) found and loaded")
        }

    }
    
    // MAXAdViewDelegate
    
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
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.delegate.viewControllerForPresentingModalView()
    }
    
    // MPBannerCustomEventDelegate
    
    public func location() -> CLLocation! {
        return self.delegate.location()
    }
    
    public func bannerCustomEvent(_ event: MPBannerCustomEvent!, didLoadAd ad: UIView!) {
        self.delegate.bannerCustomEvent(event, didLoadAd: ad)
    }
    
    public func bannerCustomEvent(_ event: MPBannerCustomEvent!, didFailToLoadAdWithError error: Error!) {
        self.delegate.bannerCustomEvent(event, didFailToLoadAdWithError: error)
    }

    public func bannerCustomEventWillBeginAction(_ event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventWillBeginAction(event)
    }
    
    public func bannerCustomEventDidFinishAction(_ event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventDidFinishAction(event)
    }
    
    public func bannerCustomEventWillLeaveApplication(_ event: MPBannerCustomEvent!) {
        self.delegate.bannerCustomEventWillLeaveApplication(event)
    }
    
    public func trackImpression() {
        self.delegate.trackImpression()
    }
    
    public func trackClick() {
        self.delegate.trackClick()
    }
    
}

@objc(MAXMoPubInterstitialCustomEvent)
open class MAXMoPubInterstitialCustomEvent : MPInterstitialCustomEvent, MAXInterstitialAdDelegate, MPInterstitialCustomEventDelegate {

    private var MAXInterstitial : MAXInterstitialAd?
    
    private var customEventInstance : MPInterstitialCustomEvent?
    
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
        
        if adResponse.creativeType == "network" {
            // In this case the creative is a JSON block that we use to generate the
            // proxy custom event and any accompanying info.
            guard let creativeData = adResponse.creative.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: creativeData) as? [String: Any] else {
                    MAXLog.error("MAX: proxy bid had invalid creative JSON")
                    self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: nil)
                    return
            }
            
            // pass along to our proxy custom event
            guard let customEventClassName = json?["custom_event_class"] as? String,
                let customEventClass = NSClassFromString(customEventClassName) as? MPInterstitialCustomEvent.Type,
                let customEventInfo = json?["custom_event_info"] as? [AnyHashable : Any] else {
                    MAXLog.error("MAX: proxy bid has missing or invalid custom event properties")
                    self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: nil)
                    return
            }
            self.customEventInstance = customEventClass.init()
            customEventInstance?.delegate = self
            customEventInstance?.requestInterstitial(withCustomEventInfo: customEventInfo)
            
        } else {
            // generate interstitial object from the pre-bid,
            // connect delegate and tell MoPub SDK that the interstitial has been loaded
            self.MAXInterstitial = MAXInterstitialAd(adResponse: adResponse)
            self.MAXInterstitial!.delegate = self
            self.delegate.interstitialCustomEvent(self, didLoadAd: self.MAXInterstitial!)
            MAXLog.debug("MAX: interstitial for \(adUnitID) found and loaded")
        }
    }
    
    override open func showInterstitial(fromRootViewController rootViewController: UIViewController!) {
        MAXLog.debug("MAX: MAXMoPubInterstitialCustomEvent.showInterstitial()")
        if let customEventInstance = self.customEventInstance {
            customEventInstance.showInterstitial(fromRootViewController: rootViewController)
        } else {
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
    
    // MPInterstitialCustomEventDelegate
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
    
    public func interstitialCustomEvent(_ customEvent: MPInterstitialCustomEvent!, didLoadAd ad: Any!) {
        self.delegate.interstitialCustomEvent(customEvent, didLoadAd: ad)
    }
    
    public func interstitialCustomEventWillLeaveApplication(_ customEvent: MPInterstitialCustomEvent!) {
        self.delegate.interstitialCustomEventWillLeaveApplication(customEvent)
    }
    
    public func interstitialCustomEvent(_ customEvent: MPInterstitialCustomEvent!, didFailToLoadAdWithError error: Error!) {
        self.delegate.interstitialCustomEvent(customEvent, didFailToLoadAdWithError: error)
    }
}
