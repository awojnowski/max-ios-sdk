import Foundation
import MoPub

/// `MAXMoPubBannerCustomEvent` provides a MoPub custom event for banner ads.
/// MoPub will use this class to hand control back to the MAX SDK when MAX has won in the MoPub waterfall.
/// See the documentation on [SSP Integration](http://docs.maxads.io/documentation/integration/ssp_integration/)
/// to ensure you integrate this properly in your waterfall.
@objc(MAXMoPubBannerCustomEvent)
open class MAXMoPubBannerCustomEvent: MPBannerCustomEvent, MPBannerCustomEventDelegate, MAXAdViewDelegate {

    private var adView: MAXAdView?
    private var customEventInstance: MPBannerCustomEvent?

    override open func requestAd(with size: CGSize, customEventInfo info: [AnyHashable: Any]!) {

        self.adView = nil

        guard let adUnitID = info["adunit_id"] as? String else {
            MAXLog.error("AdUnitID not specified in adunit_id customEventInfo block")
            self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }

        guard let adResponse = MAXAds.getPreBid(adUnitID: adUnitID) else {
            MAXLog.error("Pre-bid was not found for adUnitID=\(adUnitID)")
            self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
            return
        }

        MAXLog.debug("Banner for \(adUnitID) found, loading...")

        // Inform MAX system that we won in the waterfall
        adResponse.trackSelected()

        // Handoff control flow back to our own rendering layer. The `loadAd()` call will tell our delegate
        // if the load succeeded or failed and we pass this along accordingly.
        self.adView = MAXAdView(adResponse: adResponse, size: size)
        if let adView = self.adView {
            adView.delegate = self
            adView.loadAd()
        } else {
            MAXLog.error("Unable to create MAXAdView, failing")
            self.delegate.bannerCustomEvent(self, didFailToLoadAdWithError: nil)
        }

    }

    open override func enableAutomaticImpressionAndClickTracking() -> Bool {
        return false
    }

    // MAXAdViewDelegate
    // This is used to handle callbacks from native creative rendering by MAX internally.
    open func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?) {
        MAXLog.debug("adViewDidFailWithError")
        delegate?.bannerCustomEvent(self, didFailToLoadAdWithError: error)
    }
    open func adViewDidLoad(_ adView: MAXAdView) {
        MAXLog.debug("adViewDidLoad")
        delegate?.trackImpression()
        delegate?.bannerCustomEvent(self, didLoadAd: adView)
    }
    open func adViewDidClick(_ adView: MAXAdView) {
        MAXLog.debug("adViewDidClick")
        delegate?.trackClick()
        delegate?.bannerCustomEventWillBeginAction(self)
    }
    open func adViewDidFinishHandlingClick(_ adView: MAXAdView) {
        MAXLog.debug("adViewDidFinishHandlingClick")
        delegate?.bannerCustomEventDidFinishAction(self)
    }
    open func adViewWillLogImpression(_ adView: MAXAdView) {
        MAXLog.debug("adViewWillLogImpression")
    }
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.delegate.viewControllerForPresentingModalView()
    }

    // MPBannerCustomEventDelegate
    // This is used to handle callbacks from another embedded custom event. In these cases,
    // we pass along directly. 

    public func location() -> CLLocation! {
        return self.delegate.location()
    }

    // swiftlint:disable identifier_name
    public func bannerCustomEvent(_ event: MPBannerCustomEvent!, didLoadAd ad: UIView!) {
        self.delegate.bannerCustomEvent(event, didLoadAd: ad)
    }
    // swiftlint:enable identifier_name

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
open class MAXMoPubInterstitialCustomEvent: MPInterstitialCustomEvent, MAXInterstitialAdDelegate, MPInterstitialCustomEventDelegate {

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
        let MAXInterstitial = MAXInterstitialAd(adResponse: adResponse)
        self.MAXInterstitial = MAXInterstitial
        MAXInterstitial.delegate = self
        MAXInterstitial.loadAdWithMRAIDRenderer()
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

    
    //MARK: MAXInterstitialAdDelegate

    open func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd) {
        MAXLog.debug("MAX: interstitialAdDidLoad")
        self.delegate.interstitialCustomEvent(self, didLoadAd: MAXInterstitial)
    }
    
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

    public func interstitial(_ interstitialAd: MAXInterstitialAd, didFailWithError error: MAXClientError) {
        MAXLog.debug("MAX: interstitial:didFailWithError: \(error.message)")
        self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: error.asNSError())
    }

    
    //MARK: MPInterstitialCustomEventDelegate
    
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
