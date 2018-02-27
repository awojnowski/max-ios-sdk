import Foundation
import UIKit

/// The `MAXAdViewAdapterGenerator` protocol stubs out factory methods that should be
/// implemented to generate `MAXAdViewAdapter` instances. This is the way to register
/// a third party view class that can be used for rendering banner ads.
///
/// Classes that implement the `MAXAdViewAdapterGenerator` protocol should also register
/// themselves with MAX by calling `MAXConfiguration.shared.registerAdViewGenerator`
/// with an instance of the class.
@objc public protocol MAXAdViewAdapterGenerator {

    /// `identifier` should be the same String that the MAX auction server uses to
    /// identify the bidder. See `MAXAdResponse.partnerName`. This String will be used
    /// to retrieve the generator.
    @objc var identifier: String { get }

    /// `getAdViewAdapter` is what `MAXAdView` will call to get a `MAXAdViewAdapter`
    /// instance so that it can render the creative using the third party view. This
    /// method should be implemented to use information from the ad response to create
    /// a MAXAdViewAdapter. It should return nil if the underlying ad view could not
    /// be created.
    @objc func getAdViewAdapter(fromResponse: MAXAdResponse,
                          withSize: CGSize,
                          rootViewController: UIViewController?) -> MAXAdViewAdapter?
}

/// `MAXAdapterAdView` classes wrap UIView instances from a third party SDK, providing a
/// common interface that MAXAdView can use for rendering ads using a third party's view
/// layer. Subclasses should override the `loadAd` method and set the `adView` property
/// to ensure the MAXAdView can render the ad properly. Instances shold also register
/// a `delegate` to receive events from the underlying `adView`.
public class MAXAdViewAdapter: NSObject {
    @objc var adView: UIView?
    @objc weak var delegate: MAXAdViewAdapterDelegate?

    @objc public func loadAd() {
        MAXLog.error("MAXAdapterAdView.loadAd not implemented")
    }
}

/// `MAXAdViewAdapterDelegate` will send common events from the `MAXAdViewAdapter`'s
/// wrapped `adView` to the delegate, usually a `MAXAdView` instance. See `MAXAdView`
/// for examples.
@objc public protocol MAXAdViewAdapterDelegate: class {
    @objc func adViewWasClicked(_ adView: MAXAdViewAdapter)
    @objc func adViewDidLoad(_ adView: MAXAdViewAdapter)
    @objc func adView(_ adView: MAXAdViewAdapter, didFailWithError error: Error)
    @objc func adViewWillLogImpression(_ adView: MAXAdViewAdapter)
}
