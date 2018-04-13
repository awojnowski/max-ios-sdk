import Foundation
import SnapKit

// NOTE: MAXMoPubBanner will display expanded ads in the parent view controller of the bannerAdView injected in init

class MAXBannerController: NSObject, MAXAdViewDelegate, MAXAdRequestManagerDelegate {
    
    //TODO - Bryan: Break up MAXAdView and create MAXBannerFactory. Then include factory in this class
    
    // NOTE: MAXBannerController does not have its own MAXBannerControllerDelegate. Instead, it will funnel MAXAdRequestManager and MAXAdView callbacks into MAXBannerAdControllerDelegate callbacks.
    internal weak var delegate: MAXBannerAdViewDelegate?
    internal var disableAutoRefresh = false
    
    private let bannerAdView: UIView
    private let requestManager: MAXAdRequestManager
    private let sessionManager: MAXSessionManager
    // Use a current and next ad view to prevent lag time between ads. With two ads, we can fully load the next ad before attempting to display it.
    private var currentAdView: MAXAdView?
    // The next ad to be shown. It will be completely loaded before an ad that is already showing will be replaced.
    private var nextAdView: MAXAdView?
    
    
    internal convenience init(bannerAdView: UIView) {
        self.init(bannerAdView: bannerAdView, requestManager: MAXAdRequestManager(), sessionManager: MAXSessionManager.shared)
    }

    internal init(bannerAdView: UIView, requestManager: MAXAdRequestManager, sessionManager: MAXSessionManager) {
        self.bannerAdView = bannerAdView
        self.requestManager = requestManager
        self.sessionManager = sessionManager
        super.init()
        self.requestManager.delegate = self
    }
    
    // If another class would like to be the delegate of the MAXAdRequestManager held by MAXBannerController, it can hijack it through this method.
    internal func hijackRequestManagerDelegate(maxRequestManagerDelegate: MAXAdRequestManagerDelegate) {
        requestManager.delegate = maxRequestManagerDelegate
    }
    
    internal func load(adUnitId: String) {
        requestManager.adUnitId = adUnitId
        requestManager.requestAd()
        requestManager.stopRefreshTimer()
    }

    internal func showAd(maxAdResponse: MAXAdResponse) {
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        nextAdView = MAXAdView(adResponse: maxAdResponse, size: bannerAdView.frame.size)
        nextAdView?.delegate = self
        guard nextAdView != nil else {
            requestManager.startRefreshTimer(delay: maxAdResponse.autoRefreshInterval?.intValue ?? MAXAdRequestManager.defaultRefreshTimeSeconds)
            if let d = delegate {
                let error = MAXClientError(message: "\(String(describing: MAXBannerController.self)) had an error creating the next banner ad view for MAXAdResponse: \(maxAdResponse)")
                d.onBannerError(banner: getBannerAdView(), error: error)
            }
            return
        }
        nextAdView?.loadAd()
    }
    
    internal func startRefreshTimer(delay: Int) {
        if disableAutoRefresh == false {
            requestManager.startRefreshTimer(delay: delay)
        }
    }
    
    // NOTE: If MAXBannerController is being wrapped by a MAXBannerAdView facade, then bannerAdView will be a MAXBannerAdView. For other cases, such as when MAXMoPubBanner wrap an instance of MAXBannerController, getBannerAdView will return nil
    internal func getBannerAdView() -> MAXBannerAdView? {
        if bannerAdView is MAXBannerAdView {
            return bannerAdView as? MAXBannerAdView
        }
        return nil
    }
    
    
    internal func loadResponse(adResponse: MAXAdResponse) {
        showAd(maxAdResponse: adResponse)
    }
    
    
    //MARK: MAXAdRequestManagerDelegate
    // NOTE: MAXAdRequestManagerDelegate callbacks will not happen here when MAXBannerController is wrapped by MAXMoPubBanner because MAXMoPubBanner has hijacked them
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        
        guard adResponse != nil else {
            MAXLogger.debug("\(String(describing: self)).requestAd() succeeded but the ad response was nil")
            return
        }
        
        DispatchQueue.main.async {
            self.loadResponse(adResponse: adResponse!)
        }
    }
    
    public func onRequestFailed(error: NSError?) {
        
        // Retrys for errors will occur with an exponential backoff
        startRefreshTimer(delay: Int(MAXAdRequestManager.defaultRefreshTimeSeconds))
        
        if let d = delegate {
            let maxError = MAXClientError(message: error?.localizedDescription ?? "a nil reqest error was passed back..")
            d.onBannerError(banner: getBannerAdView(), error: maxError)
        }
    }

    
    //MARK: MAXAdViewDelegate
    // NOTE: MAXAdViewDelegate callbacks will not happen here when MAXBannerController is wrapped by MAXMoPubBanner because MAXMoPubBanner has hijacked them
    
    // This callback will only happen for MAX reserved ads
    internal func adViewDidLoad(_ adView: MAXAdView?) {
        
        // A banner loaded for a MAX 'reserved' ad response
        sessionManager.incrementMaxSessionDepth(adUnitId: (adView?.adUnitId)!)
        
        startRefreshTimer(delay: Int(adView?.adResponse.autoRefreshInterval?.intValue ?? MAXAdRequestManager.defaultRefreshTimeSeconds))
        
        if let next = nextAdView {
            currentAdView?.removeFromSuperview()
            currentAdView = next
            nextAdView = nil
            bannerAdView.addSubview(currentAdView!)
            currentAdView!.snp.makeConstraints { (make) -> Void in
                make.edges.equalTo(self.bannerAdView)
            }
        }
        
        if let d = delegate {
            d.onBannerLoaded(banner: getBannerAdView())
        }
    }
    
    internal func adViewDidFailWithError(_ adView: MAXAdView?, error: NSError?) {
        
        startRefreshTimer(delay: Int(MAXAdRequestManager.defaultRefreshTimeSeconds))
        reportError(message: error?.localizedDescription ?? "")
    }
    
    internal func adViewDidClick(_ adView: MAXAdView?) {
        if let d = delegate {
            d.onBannerClicked(banner: getBannerAdView())
        }
    }
    
    internal func adViewDidFinishHandlingClick(_ adView: MAXAdView?) {
            // MAXBannerAdView does not have a matching callback
    }
    
    internal func adViewWillLogImpression(_ adView: MAXAdView?) {
        // MAXBannerAdView does not have a matching callback
    }
    
    internal func viewControllerForMaxPresentingModalView() -> UIViewController? {
        return bannerAdView.parentViewController
    }
    
    
    //MARK: overrides
    
    public override var description: String {
        return "\(super.description)\n --- \nbannerAdView: \(bannerAdView)\n currentAdView: \(String(describing: currentAdView))\n nextAdView: \(String(describing: nextAdView))"
    }
    
    
    //MARK: Errors
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        
        if let d = delegate {
            let error = MAXClientError(message: message)
            d.onBannerError(banner: getBannerAdView(), error: error)
        }
    }
}
