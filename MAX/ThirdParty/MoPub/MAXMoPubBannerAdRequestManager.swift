import Foundation
import MoPub

public class MAXMoPubBannerAdRequestManager: MAXAdRequestManager, MPAdViewDelegate, MAXAdViewDelegate {

    /// MAXMoPubBannerAdRequestManager will manage the refresh interval of this MPAdView
    /// and listens to ad display events to trigger refreshes.
    private let mpAdView: MPAdView
    
    /// The refresh manager only cares about listening to ad display events.
    /// `MAXMoPubBannerAdRequestManager` proxies the view presentation events
    /// to whatever delegate the user had previously set.
    private weak var mpAdViewProxyDelegate: MPAdViewDelegate!
    
    private var maxAdView: MAXAdView?

    /// Initializes a `MAXMoPubBannerAdRequestManager` with a MAX ad unit ID and a MoPub banner ad view.
    /// A completion callback should be provided, which fires after the
    public init(maxAdUnitID: String, mpAdView: MPAdView, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self.mpAdView = mpAdView
        super.init(adUnitID: maxAdUnitID, completion: completion)

        self.mpAdViewProxyDelegate = self.mpAdView.delegate
        self.mpAdView.delegate = self
        self.mpAdView.stopAutomaticallyRefreshingContents()
    }

    /// MAXMoPubBannerAdRequestManager's refresh differs from the parent class in that it won't
    /// immediately start a new refresh interval on an ad response -- it will wait until the
    /// managed `mpAdView` triggers an impression or impression failure. This more closely mimics
    /// MoPub's own refresh logic.
    ///
    /// The request manager will also handle attaching MAX pre-bid keywords to the MoPub ad request,
    /// tracking handoffs events to MoPub, and the `mpAdView.loadAd()` call.
    /// NOTE: refresh() method is NOT threadsafe. Refreshes should be initiated by calling public startRefreshTimer() method
    override internal func refresh() -> MAXAdRequest {
        MAXLog.debug("\(String(describing: self)) internal refresh() called")
        return self.requestAd { (response, error) in
            self.lastResponse = response
            self.lastError = error
            self.completion(response, error)

            // This needs to be called from the main thread, or could crash the app,
            // since third party SDKs don't explicitly prevent certain main-thread-only
            // subprocesses (e.g. UIKit/UIApplication calls) from happening on background
            // threads.
            DispatchQueue.main.sync {
                if let r = response {
                    MAXLog.debug("\(String(describing: self)).requestAd() succeeded for adUnit:\(r.adUnitId)")
                    if r.isReserved {
                        let size = CGSize(width: 320, height: 50)
                        self.maxAdView = MAXAdView(adResponse: r, size: size)
                        
                        
                        //  TODO - Bryan: MME-105 ==========================================
                        
                        
                        
                        self.maxAdView?.delegate = self
                        self.maxAdView?.loadAd()
                    } else {
                        response?.trackHandoff()
                        self.mpAdView.keywords = r.preBidKeywords
                        self.mpAdView.loadAd()
                    }
                } else {
                    MAXLog.debug("\(String(describing: self)).requestAd() returned with error: \(String(describing: error))")
                }
            }
        }
    }

    
    //MARK: MPAdViewDelegate
    // Called when a MoPub line item won in the MoPub waterfall
    
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return mpAdViewProxyDelegate.viewControllerForPresentingModalView()
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {
        /// Trigger a refresh on impressions rather than immediately rescheduling after a response.
        self.scheduleNewRefresh()
        self.mpAdViewProxyDelegate.adViewDidLoadAd?(view)
        
        // A banner loaded because a non-MAX line item in the MoPub waterfall was selected
        MAXSessionManager.shared.incrementSSPSessionDepth(adUnitId: view.adUnitId)
    }

    public func adViewDidFail(toLoadAd view: MPAdView!) {
        /// Trigger a refresh on a display error.
        self.scheduleNewRefresh()
        self.mpAdViewProxyDelegate.adViewDidFail?(toLoadAd: view)
    }

    public func willPresentModalView(forAd view: MPAdView!) {
        self.mpAdViewProxyDelegate.willPresentModalView?(forAd: view)
    }

    public func didDismissModalView(forAd view: MPAdView!) {
        self.mpAdViewProxyDelegate.didDismissModalView?(forAd: view)
    }

    public func willLeaveApplication(fromAd view: MPAdView!) {
        self.mpAdViewProxyDelegate.willLeaveApplication?(fromAd: view)
    }
    
    
    //MARK: MAXAdViewDelegate
    
    //TODO - Bryan: Fill out delegate as necessary for MME-105
    
    public func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?) {
        
    }
    
    public func adViewDidClick(_ adView: MAXAdView) {
        
    }
    
    public func adViewDidFinishHandlingClick(_ adView: MAXAdView) {
        
    }
    
    public func adViewDidLoad(_ adView: MAXAdView) {
        
    }
    
    public func adViewWillLogImpression(_ adView: MAXAdView) {
        
    }
}
