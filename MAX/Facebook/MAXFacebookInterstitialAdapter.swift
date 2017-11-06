import Foundation
import FBAudienceNetwork

public class FacebookInterstitialView: MAXInterstitialAdapter, FBInterstitialAdDelegate {
    
    public var fbInterstitial: FBInterstitialAd
    public var bidPayload: String
    
    override var interstitialAd: NSObject? {
        get {
            return self.fbInterstitial
        }
        set {
            if newValue is FBInterstitialAd {
                self.fbInterstitial = newValue as! FBInterstitialAd
            } else {
                MAXLog.error("Tried to set FacebookInterstitialView.fbInterstitial but got a non-FBInterstitialAd type")
            }
        }
    }
    
    public init(placementID: String, bidPayload: String) {
        self.fbInterstitial = FBInterstitialAd(placementID: placementID)
        self.bidPayload = bidPayload
        super.init()
        self.fbInterstitial.delegate = self
    }
    
    override public func loadAd() {
        self.fbInterstitial.load(withBidPayload: bidPayload)
    }
    
    override public func showAd(fromRootViewController rvc: UIViewController?) {
        self.fbInterstitial.show(fromRootViewController: rvc)
    }
    
    /*
     * FBInterstitialAdDelegate methods
     */
    public func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        MAXLog.debug("Facebook interstitial ad was clicked")
        self.delegate?.interstitialWasClicked(self)
    }
    
    public func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        MAXLog.debug("Facebook interstitial ad was closed")
        self.delegate?.interstitialDidClose(self)
    }
    
    public func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        MAXLog.debug("Facebook interstitial ad will close")
        self.delegate?.interstitialWillClose(self)
    }
    
    public func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        MAXLog.debug("Facebook interstitial ad was loaded")
        self.delegate?.interstitialDidLoad(self)
    }
    
    public func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        MAXLog.debug("Facebook interstitial ad will log an impression")
        self.delegate?.interstitialWillLogImpression(self)
    }
    
    public func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        MAXLog.debug("Facebook interstitial ad failed: \(error.localizedDescription)")
        self.delegate?.interstitial(self, didFailWithError: error)
    }
}

public class FacebookInterstitialGenerator: NSObject, MAXInterstitialAdapterGenerator {
    
    public var identifier: String = facebookIdentifier
    
    public func getInterstitialAdapter(fromResponse: MAXAdResponse) -> MAXInterstitialAdapter? {
        guard let placementID = fromResponse.partnerPlacementID else {
            MAXLog.warn("Tried to load an interstitial ad for Facebook but couldn't find a placement ID in the response")
            return nil
        }
        
        guard let bidPayload = fromResponse.creative else {
            MAXLog.warn("Tried to load a banner ad for Facebook but couldn't find a bid payload (creative) in the response")
            return nil
        }
        
        let adaptedInterstitial = FacebookInterstitialView(placementID: placementID, bidPayload: bidPayload)
        return adaptedInterstitial
    }
}
