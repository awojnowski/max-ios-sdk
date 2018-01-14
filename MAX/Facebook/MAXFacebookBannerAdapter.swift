import Foundation
import FBAudienceNetwork

public class FacebookBannerView: MAXAdViewAdapter, FBAdViewDelegate {

    public var fbAdView: FBAdView
    public var bidPayload: String

    override var adView: UIView? {
        get {
            return self.fbAdView
        }
        set {
            if newValue is FBAdView {
                // swiftlint:disable force_cast
                self.fbAdView = newValue as! FBAdView
                // swiftlint:enable force_cast
            } else {
                MAXLog.error("Tried to set FacebookBannerView.fbAdView but got a non-FBAdView type")
            }
        }
    }

    public init(placementID: String, fbAdSize: FBAdSize, rootViewController: UIViewController?, bidPayload: String) {
        self.fbAdView = FBAdView(placementID: placementID, adSize: fbAdSize, rootViewController: rootViewController)
        self.bidPayload = bidPayload
        super.init()
        self.fbAdView.delegate = self
    }

    override public func loadAd() {
        MAXLog.debug("Calling loadAd on Facebook Banner")
        self.fbAdView.loadAd(withBidPayload: self.bidPayload)
    }

    /*
     * FBAdViewDelegate methods
     */
    public func adViewDidClick(_ adView: FBAdView) {
        self.delegate?.adViewWasClicked(self)
        MAXLog.debug("Facebook banner ad was clicked")
    }

    public func adViewDidFinishHandlingClick(_ adView: FBAdView) {
        MAXLog.debug("Facebook banner ad finished handling click")
    }

    public func adViewDidLoad(_ adView: FBAdView) {
        self.delegate?.adViewDidLoad(self)
        MAXLog.debug("Facebook banner ad finished handling click")
    }

    public func adView(_ adView: FBAdView, didFailWithError error: Error) {
        self.delegate?.adView(self, didFailWithError: error)
        MAXLog.debug("Facebook banner ad failed with error: \(error.localizedDescription)")
    }

    public func adViewWillLogImpression(_ adView: FBAdView) {
        self.delegate?.adViewWillLogImpression(self)
        MAXLog.debug("Facebook banner ad will log an impression")
    }
}

public class FacebookBannerGenerator: NSObject, MAXAdViewAdapterGenerator {

    public var identifier: String = facebookIdentifier

    public func getAdViewAdapter(fromResponse response: MAXAdResponse,
                                 withSize size: CGSize,
                                 rootViewController: UIViewController?) -> MAXAdViewAdapter? {
        guard let placementID = response.partnerPlacementID else {
            MAXLog.warn("Tried to load a banner ad for Facebook but couldn't find a placement ID in the response")
            return nil
        }

        guard let bidPayload = response.creative else {
            MAXLog.warn("Tried to load a banner ad for Facebook but couldn't find a bid payload in the response")
            return nil
        }

        var fbAdSize: FBAdSize
        switch (size.width, size.height) {
            case (_, 50.0): fbAdSize = kFBAdSizeHeight50Banner
            case (_, 90.0): fbAdSize = kFBAdSizeHeight90Banner
            case (_, 250.0): fbAdSize = kFBAdSizeHeight250Rectangle

            default: return nil
        }

        let adaptedAdView = FacebookBannerView(
            placementID: placementID,
            fbAdSize: fbAdSize,
            rootViewController: rootViewController,
            bidPayload: bidPayload
        )

        return adaptedAdView
    }
}
