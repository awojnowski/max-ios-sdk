import Foundation
import MoPub

@objc(MAXMoPubAdRequestManager)
public class MAXMoPubAdRequestManager: MAXAdRequestManager, MPAdViewDelegate {

    /// MAXMoPubAdRequestManager will manage the refresh interval of this MPAdView
    /// and listens to ad display events to trigger refreshes.
    public var adView: MPAdView

    /// The refresh manager only cares about listening to ad display events.
    /// `MAXMoPubAdRequestManager` proxies the view presentation events
    /// to whatever delegate the user had previously set. 
    weak public var bannerProxyDelegate: MPAdViewDelegate!

    /// Initializes a `MAXMoPubAdRequestManager` with a MAX ad unit ID and a MoPub banner ad view.
    /// A completion callback should be provided, which fires after the
    public init(maxAdUnitID: String, adView: MPAdView, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self.adView = adView
        super.init(adUnitID: maxAdUnitID, completion: completion)

        self.bannerProxyDelegate = self.adView.delegate
        self.adView.delegate = self
        self.adView.stopAutomaticallyRefreshingContents()
    }

    /// MAXMoPubAdRequestManager's refresh differs from the parent class in that it won't
    /// immediately start a new refresh interval on an ad response -- it will wait until the
    /// managed `adView` triggers an impression or impression failure. This more closely mimics
    /// MoPub's own refresh logic.
    ///
    /// The request manager will also handle attaching MAX pre-bid keywords to the MoPub ad request,
    /// tracking handoffs events to MoPub, and the `adView.loadAd()` call.
    /// NOTE: refresh() method is NOT threadsafe. Refreshes should be initiated by calling public startRefresh() method
    override internal func refresh() -> MAXAdRequest {
        MAXLog.debug("\(String(describing: self)) internal refresh() called")
        return self.runPreBid { (response, error) in
            MAXLog.debug("\(String(describing: self)).runPreBid() returned with error: \(String(describing: error))")
            self.lastResponse = response
            self.lastError = error
            self.completion(response, error)

            if let r = response {
                self.adView.keywords = r.preBidKeywords
            }

            response?.trackHandoff()

            // This needs to be called from the main thread, or could crash the app,
            // since the MoPub SDK doesn't explicitly prevent certain main-thread-only
            // subprocesses (e.g. UIKit/UIApplication calls) from happening on background
            // threads.
            DispatchQueue.main.sync {
                self.adView.loadAd()
            }
        }
    }

    @objc
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return bannerProxyDelegate.viewControllerForPresentingModalView()
    }

    /// Trigger a refresh on impressions rather than immediately rescheduling after a response.
    @objc
    public func adViewDidLoadAd(_ view: MPAdView!) {
        self.scheduleNewRefresh()
        self.bannerProxyDelegate.adViewDidLoadAd?(view)
    }

    /// Trigger a refresh on a display error.
    @objc
    public func adViewDidFail(toLoadAd view: MPAdView!) {
        self.scheduleNewRefresh()
        self.bannerProxyDelegate.adViewDidFail?(toLoadAd: view)
    }

    /*
     * Proxy changes back to the bannerProxyDelegate.
     */

    @objc
    public func willPresentModalView(forAd view: MPAdView!) {
        self.bannerProxyDelegate.willPresentModalView?(forAd: view)
    }

    @objc
    public func didDismissModalView(forAd view: MPAdView!) {
        self.bannerProxyDelegate.didDismissModalView?(forAd: view)
    }

    @objc
    public func willLeaveApplication(fromAd view: MPAdView!) {
        self.bannerProxyDelegate.willLeaveApplication?(fromAd: view)
    }
}
