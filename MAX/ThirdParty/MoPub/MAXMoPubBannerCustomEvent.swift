
import MoPub

/// `MAXMoPubBannerCustomEvent` provides a MoPub custom event for banner ads.
/// MoPub will use this class to hand control back to the MAX SDK when MAX has won in the MoPub waterfall.
/// See the documentation on [SSP Integration](http://docs.maxads.io/documentation/integration/ssp_integration/)
/// to ensure you integrate this properly in your waterfall.
/// NOTE: MoPub will instantiate this class based on MoPub account line item configurations
@objc(MAXMoPubBannerCustomEvent)
public class MAXMoPubBannerCustomEvent: MPBannerCustomEvent, MPBannerCustomEventDelegate, MAXAdViewDelegate {
    
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

    override open func enableAutomaticImpressionAndClickTracking() -> Bool {
        return false
    }

    //MARK: MAXAdViewDelegate
    // Called after a MAX line item won in the MoPub waterfall
    // This is used to handle callbacks from native creative rendering by MAX internally.
    
    public func adViewDidFailWithError(_ adView: MAXAdView?, error: NSError?) {
        MAXLog.debug("adViewDidFailWithError")
        
        if let d = delegate {
            d.bannerCustomEvent(self, didFailToLoadAdWithError: error)
        }
    }
    
    public func adViewDidLoad(_ adView: MAXAdView?) {
        MAXLog.debug("adViewDidLoad")
        
        if let d = delegate {
            d.trackImpression()
            d.bannerCustomEvent(self, didLoadAd: adView)
        }
    }
    
    public func adViewDidClick(_ adView: MAXAdView?) {
        MAXLog.debug("adViewDidClick")
        delegate?.trackClick()
        delegate?.bannerCustomEventWillBeginAction(self)
    }
    
    public func adViewDidFinishHandlingClick(_ adView: MAXAdView?) {
        MAXLog.debug("adViewDidFinishHandlingClick")
        delegate?.bannerCustomEventDidFinishAction(self)
    }
    
    public func adViewWillLogImpression(_ adView: MAXAdView?) {
        MAXLog.debug("adViewWillLogImpression")
    }
    
    public func viewControllerForMaxPresentingModalView() -> UIViewController? {
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

    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self.delegate.viewControllerForPresentingModalView()
    }
}


