import Foundation
import UIKit

/// The `MAXInterstitialAdapterGenerator` protocol stubs out factory methods for generating
/// interstitial views from a third party. This is the way to register a third party
/// view class that can be used for rendering interstitials.
///
/// Classes that implement the `MAXInterstitialAdapterGenerator` protocol should also register
/// themselves with MAX by calling `MAXConfiguration.shared.registerInterstitialGenerator`
/// with an instance of the class.
public protocol MAXInterstitialAdapterGenerator {

    /// `identifier` should be the same String that the MAX auction server uses to
    /// identify the bidder. See `MAXAdResponse.partnerName`. This String will be used
    /// to retrieve the generator.
    var identifier: String { get }

    /// `getInterstitialAdapter` is what `MAXInterstitialAd` will call to get a `MAXInterstitialAdapter`
    /// instance so that it can render the creative using the third party view.
    func getInterstitialAdapter(fromResponse: MAXAdResponse) -> MAXInterstitialAdapter?
}

/// `MAXInterstitialAdapter` classes wrap interstitial instances from a third party SDK, providing
/// a common interface that `MAXInterstitialAd` can use for loading and showing interstitials using
/// a third party's view layer. Subclasses should override `loadAd` and `showAd`, and set the
/// `interstitialAd` property to ensure `MAXInterstitialAd` can render the ad properly. Instances
/// should also register a `delegate` to receive events from the underlying interstitial.
public class MAXInterstitialAdapter: NSObject {
    var interstitialAd: NSObject?
    weak var delegate: MAXInterstitialAdapterDelegate?

    public func loadAd() {
        MAXLog.error("MAXInterstitialAdapter.loadAd not implemented")
    }

    public func showAd(fromRootViewController rvc: UIViewController?) {
        MAXLog.error("MAXInterstitialAdapter.showAd not implemented")
    }
}

/// `MAXInterstitialAdapterDelegate` will send comon events from the `MAXInterstitialAdapter`'s
/// wrapped `adView` to the delegate, usually a `MAXInterstitialAd` instance. See `MAXInterstitialAd`
/// for examples.
public protocol MAXInterstitialAdapterDelegate: class {
    func interstitialWasClicked(_ interstitial: MAXInterstitialAdapter)
    func interstitialDidClose(_ interstitial: MAXInterstitialAdapter)
    func interstitialWillClose(_ interstitial: MAXInterstitialAdapter)
    func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter)
    func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter)
    func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: MAXClientError)
}
