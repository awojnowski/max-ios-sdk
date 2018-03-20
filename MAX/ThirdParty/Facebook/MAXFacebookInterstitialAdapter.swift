import Foundation
import FBAudienceNetwork

internal class FacebookInterstitialView: MAXInterstitialAdapter, FBInterstitialAdDelegate {

    internal var fbInterstitial: FBInterstitialAd
    internal var bidPayload: String

    override var interstitialAd: NSObject? {
        get {
            return self.fbInterstitial
        }
        set {
            if newValue is FBInterstitialAd {
                // swiftlint:disable force_cast
                self.fbInterstitial = newValue as! FBInterstitialAd
                // swiftlint:enable force_cast
            } else {
                MAXLogger.error("Tried to set FacebookInterstitialView.fbInterstitial but got a non-FBInterstitialAd type")
            }
        }
    }

    internal init(placementID: String, bidPayload: String) {
        self.fbInterstitial = FBInterstitialAd(placementID: placementID)
        self.bidPayload = bidPayload
        super.init()
        self.fbInterstitial.delegate = self
    }

    override internal func loadAd() {
        self.fbInterstitial.load(withBidPayload: bidPayload)
    }

    override internal func showAd(fromRootViewController rvc: UIViewController?) {
        self.fbInterstitial.show(fromRootViewController: rvc)
    }

    /*
     * FBInterstitialAdDelegate methods
     */
    internal func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        MAXLogger.debug("Facebook interstitial ad was clicked")
        self.delegate?.interstitialWasClicked(self)
    }

    internal func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        MAXLogger.debug("Facebook interstitial ad was closed")
        self.delegate?.interstitialDidClose(self)
    }

    internal func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        MAXLogger.debug("Facebook interstitial ad will close")
        self.delegate?.interstitialWillClose(self)
    }

    internal func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        MAXLogger.debug("Facebook interstitial ad was loaded")
        self.delegate?.interstitialDidLoad(self)
    }

    internal func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        MAXLogger.debug("Facebook interstitial ad will log an impression")
        self.delegate?.interstitialWillLogImpression(self)
    }

    internal func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        MAXLogger.debug("Facebook interstitial ad failed: \(error.localizedDescription)")
        self.delegate?.interstitial(self, didFailWithError: MAXClientError(message: error.localizedDescription))
    }
}

internal class FacebookInterstitialGenerator: MAXInterstitialAdapterGenerator {

    internal var identifier: String = facebookIdentifier

    internal func getInterstitialAdapter(fromResponse: MAXAdResponse) -> MAXInterstitialAdapter? {
        guard let placementID = fromResponse.partnerPlacementID else {
            MAXLogger.warn("Tried to load an interstitial ad for Facebook but couldn't find placement ID in the response")
            return nil
        }

        guard let bidPayload = fromResponse.creative else {
            MAXLogger.warn("Tried to load a banner ad for Facebook but couldn't find a bid payload in the response")
            return nil
        }

        let adaptedInterstitial = FacebookInterstitialView(placementID: placementID, bidPayload: bidPayload)
        return adaptedInterstitial
    }
}
