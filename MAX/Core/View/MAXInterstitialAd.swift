import UIKit

public enum MAXInterstitialCreativeType: String {
    case VAST = "vast3"
    // HTML is equivalent to MRAID. We have it as 'html' for backwards compatibility.
    case HTML = "html"
    case empty = "empty"
}

@objc public protocol MAXInterstitialAdDelegate: class {
    @objc func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd)
    @objc func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd)
    @objc func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd)
    @objc func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd)
    @objc func interstitial(_ interstitialAd: MAXInterstitialAd?, didFailWithError error: MAXClientError)
}

open class MAXInterstitialAd: NSObject, MAXInterstitialAdapterDelegate, MaxVASTViewControllerDelegate, MaxMRAIDInterstitialDelegate, MaxMRAIDServiceDelegate, MAXAdRequestManagerDelegate {
    
    @objc public weak var delegate: MAXInterstitialAdDelegate?
    
    private let configuration: MAXConfiguration
    private let requestManager: MAXAdRequestManager
    private let sessionManager: MAXSessionManager
    private var adResponse: MAXAdResponse?
    private var rootViewController: UIViewController?
    private var vastViewController: MaxVASTViewController?
    private var mraidInterstitial: MaxMRAIDInterstitial?
    private var interstitialAdapter: MAXInterstitialAdapter?
    
    @objc public var adUnitId: String? {
        return adResponse?.adUnitId
    }
    
    @objc public override convenience init() {
        self.init(requestManager: MAXAdRequestManager(), sessionManager: MAXSessionManager.shared, configuration: MAXConfiguration.shared)
    }
    
    internal init(requestManager: MAXAdRequestManager, sessionManager: MAXSessionManager, configuration: MAXConfiguration) {
        self.requestManager = requestManager
        self.sessionManager = sessionManager
        self.configuration = configuration
        super.init()
        self.requestManager.delegate = self
    }
    
    // If another class would like to be the delegate of the MAXAdRequestManager held by MAXBannerController, it can hijack it through this method.
    internal func hijackRequestManagerDelegate(maxRequestManagerDelegate: MAXAdRequestManagerDelegate) {
        requestManager.delegate = maxRequestManagerDelegate
    }
    
    @objc public func load(adUnitId: String) {
        requestManager.adUnitId = adUnitId
        requestManager.requestAd()
    }
    
    // DANGER: Not threadsafe - If load() is called once and then again before a request returns for the first call, mpAdUnitId will have changed by the time this code is executed. It seems unlikely that a pub would call load() rapidly on the same instance of MAXMoPubBanner, but, if one did, our reporting of which ads are being shown would be inaccurate.
    internal func loadResponse(adResponse: MAXAdResponse) {
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        self.adResponse = adResponse
        
        //TODO - Bryan: For now we keep the adResponse around. Once an InterstitialFactory and Interstitial base class are created, MAXInterstitialAd will keep an Interstitial instance, which can be kept instead of a MAXAdResponse.
        
        guard let adR = self.adResponse else {
            reportError(message: "\(String(describing: self)): loading an interstitial failed because the adResponse was nil.")
            return
        }
        
        guard let creative = self.adResponse?.creative else {
            reportError(message: "\(String(describing: self)): loading an interstitial failed because the creative was nil.")
            return
        }
        
        if let error =  configuration.directSDKManager.checkDirectIntegrationsInitialized() {
            MAXLogger.warn(error.message)
        }
        
        switch adR.creativeType {
        case MAXInterstitialCreativeType.VAST.rawValue:
            MAXLogger.debug("\(String(describing: self)): loading interstitial with VAST renderer")
            loadAdWithVASTRenderer(creative: creative)
            // HTML is equivalent to MRAID. We have it as 'html' for backwards compatibility.
        case MAXInterstitialCreativeType.HTML.rawValue:
            if adR.usePartnerRendering {
                MAXLogger.debug("\(String(describing: self)): loading interstitial with third party renderer")
                loadAdWithAdapter(adResponse: adR)
            } else {
                MAXLogger.debug("\(String(describing: self)): loading interstitial with MRAID renderer")
                loadAdWithMRAIDRenderer(creative: creative)
            }
        case MAXInterstitialCreativeType.empty.rawValue:
            MAXLogger.debug("\(String(describing: self)): attempting to load with an empty creative type, nothing to show")
        default:
            reportError(message: "\(String(describing: self)): loadInterstitial() called for an unsupported ad creative_type=\(String(describing: adR.creativeType))")
        }
    }

    // NOTE: Call this function on the main queue
    @objc public func showAdFromRootViewController(_ rootViewController: UIViewController?) {
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        // must check for nil since this method is exposed to ObjC
        if rootViewController == nil {
            reportError(message: "\(String(describing: self)): showAdFromRootViewController was called with a nil root view controller.")
            return
        }
        
        self.rootViewController = rootViewController
        switch adResponse?.creativeType {
        case MAXInterstitialCreativeType.VAST.rawValue?:
                MAXLogger.debug("\(String(describing: self)): showing ad with VAST renderer")
                vastViewController?.presenterViewController = rootViewController
                vastViewController?.play()
            // HTML is equivalent to MRAID. We have it as 'html' for backwards compatibility.
            case MAXInterstitialCreativeType.HTML.rawValue?:
                if (adResponse?.usePartnerRendering)! {
                    MAXLogger.debug("\(String(describing: self)): showing ad with third party renderer")
                    interstitialAdapter?.showAd(fromRootViewController: rootViewController)
                } else {
                    MAXLogger.debug("\(String(describing: self)): showing ad with MRAID renderer")
                    mraidInterstitial?.rootViewController = rootViewController
                    mraidInterstitial?.show()
                }
            case MAXInterstitialCreativeType.empty.rawValue?:
                MAXLogger.debug("\(String(describing: self)): had empty ad response, nothing to show")
            default:
                reportError(message: "\(String(describing: self)): show() called for an unsupported ad creative_type=\(String(describing: adResponse?.creativeType))")
        }
    }

    internal func loadAdWithMRAIDRenderer(creative: String) {
        MAXLogger.debug("\(String(describing: self)): attempting to load ad with MRAID renderer")
        
        mraidInterstitial = MaxMRAIDInterstitial(
            supportedFeatures: [],
            withHtmlData: creative,
            withBaseURL: URL(string: "https://\(MAXAdRequest.adsDomain)"),
            delegate: self,
            serviceDelegate: self,
            // NOTE: A rootViewController must be injected later in order to show mraid interstitial (in showAdFromRootController method)
            rootViewController: nil
        )
    }

    internal func loadAdWithVASTRenderer(creative: String) {
        MAXLogger.debug("\(String(describing: self)): attempting to load ad with VAST renderer")
        
        guard let videoData = creative.data(using: String.Encoding.utf8) else {
            MAXLogger.error("\(String(describing: self)): ERROR: VAST ad response creative had no video data")
            if let d = delegate {
                let error = MAXClientError(message: "MAXInterstitialAd: VAST creative video data could not be extracted")
                d.interstitial(self, didFailWithError: error)
            }
            return
        }
        
        vastViewController = MaxVASTViewController(delegate: self, with: rootViewController)
        vastViewController!.loadVideo(with: videoData)
    }

    internal func loadAdWithAdapter(adResponse: MAXAdResponse) {
        MAXLogger.debug("\(String(describing: self)): attempting to load ad with a third party renderer")

        guard let partner = adResponse.partnerName else {
            reportError(message: "\(String(describing: self)): Attempted to load interstitial with third party renderer, but no partner was declared. Trying to load with a MAX MRAID renderer instead.")
            loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }
        
        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            reportError(message: "\(String(describing: self)): Tried loading ad with third party ad generator for \(partner), but no generator was configured. Trying to load with a MAX MRAID renderer instead.")
            loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }
        
        let adapter = adViewGenerator.getInterstitialAdapter(fromResponse: adResponse)
        interstitialAdapter = adapter
        interstitialAdapter?.delegate = self
        interstitialAdapter?.loadAd()
    }

    //TODO - Bryan: Replace interstitial generator with MAXInterstitialFactory (to mirror Android implementation)
    internal func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return MAXConfiguration.shared.getInterstitialGenerator(forPartner: partner)
    }
    
    //MARK: MAXAdRequestManagerDelegate
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        MAXLogger.debug("\(String(describing: self)).requestAd() succeeded for adUnit:\(String(describing: adResponse?.adUnitId))")
        
        guard adResponse != nil else {
            MAXLogger.debug("\(String(describing: self)).requestAd() succeeded but the ad response was nil")
            return
        }
        
        DispatchQueue.main.async {
            self.loadResponse(adResponse: adResponse!)
        }
    }
    
    public func onRequestFailed(error: NSError?) {
        reportError(message: "\(String(describing: self)).requestAd() failed with error: \(String(describing: error?.localizedDescription))")
    }

    //TODO - Bryan: When Interstitial base class is created, the below methods can be consolidated to one set of InterstitialDelegate methods
    
    //MARK: MAXInterstitialAdapterDelegate methods
 
    public func interstitialWasClicked(_ interstitial: MAXInterstitialAdapter) {
        MAXLogger.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWasClicked")
        adResponse?.trackClick()
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
    }

    public func interstitialDidClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLogger.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialDidClose")
        if let d = delegate {
            d.interstitialAdDidClose(self)
        }
    }

    public func interstitialWillClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLogger.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillClose")
        if let d = delegate {
            d.interstitialAdWillClose(self)
        }
    }

    public func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        MAXLogger.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialDidLoad")
        if let d = delegate {
            d.interstitialAdDidLoad(self)
        }
    }

    public func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter) {
        MAXLogger.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillLogImpression")
        adResponse?.trackImpression()
    }

    public func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: MAXClientError) {
        reportError(message: "\(String(describing: self)): MAXInterstitialAdapterDelegate interstitial:didFailWithError: \(error.message)")
    }

    
    //MARK: MaxVASTViewControllerDelegate
    
    public func vastReady(_ vastVC: MaxVASTViewController!) {
        MAXLogger.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastReady")
        if let d = delegate {
            d.interstitialAdDidLoad(self)
        }
    }

    public func vastTrackingEvent(_ eventName: String!) {
        MAXLogger.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastTrackingEvent(\(eventName!))")
        
        if eventName == "start"{
            guard let adR = adResponse else {
                MAXLogger.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate - vastTrackingEvent - called for a nil ad response. Impression was not tracked and MAX session depth could not be incremented")
                return
            }
            
            adResponse?.trackImpression()
            
            // An interstitial will be shown because a MAX response was ‘reserved,’ so MAX bypassed any SSP and directly rendered an ad response
            if adR.isReserved {
                sessionManager.incrementMaxSessionDepth(adUnitId: adR.adUnitId)
            }
        }
        
        if eventName == "close" {
            if let d = delegate {
                d.interstitialAdWillClose(self)
            }
        }
    }

    public func vastDidDismissFullScreen(_ vastVC: MaxVASTViewController!) {
        MAXLogger.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastDidDismissFullScreen")
        if let d = delegate {
            d.interstitialAdDidClose(self)
        }
    }

    public func vastOpenBrowse(with url: URL!, vastVC: MaxVASTViewController!) {
        MAXLogger.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastOpenBrowse")
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
        vastVC.dismiss(animated: false) {
            MAXLinkHandler().openURL(vastVC, url: url, completion: nil)
        }
        vastVC.close()
    }

    public func vastError(_ vastVC: MaxVASTViewController!,_ error: MaxVASTError) {
        reportError(message: "\(String(describing: self)) - MaxVASTViewControllerDelegate: failedToLoadAd - Code:\(error.rawValue)")
    }
    
    
    //MARK: MaxMRAIDInterstitialDelegate

    public func mraidInterstitialAdReady(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialAdReady")
        if let d = delegate {
            d.interstitialAdDidLoad(self)
        }
    }

    public func mraidInterstitialDidHide(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialDidHide")
        if let d = delegate {
            d.interstitialAdWillClose(self)
            d.interstitialAdDidClose(self)
        }
    }

    public func mraidInterstitialAdFailed(_ mraidInterstitial: MaxMRAIDInterstitial!, error: Error!) {
        reportError(message: "\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialAdFailed with error - \(error.localizedDescription)")
    }

    public func mraidInterstitialWillShow(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate - mraidInterstitialWillShow")
        
        guard let adR = adResponse else {
            MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate - mraidInterstitialWillShow - called for a nil ad response. Impression was not tracked and MAX session depth could not be incremented")
            return
        }
        
        adR.trackImpression()
        
        if adR.isReserved {
            sessionManager.incrementMaxSessionDepth(adUnitId: adR.adUnitId)
        }
    }

    public func mraidInterstitialNavigate(_ mraidInterstitial: MaxMRAIDInterstitial!, with url: URL!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialNavigate")
        adResponse?.trackClick()
        MAXLinkHandler().openURL(rootViewController!, url: url, completion: nil)
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
    }

    public func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidServiceOpenBrowserWithUrlString")

        // This method is called when the MRAID creative requests a native browser to be opened. This is
        // considered to be a click event
        adResponse?.trackClick()
        MAXLinkHandler().openURL(rootViewController!, url: URL(string: url)!, completion: nil)
    }
    
    
    //MARK: Temp until MAXInterstitialDecorator is created
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        let error = MAXClientError(message: message)
        if let d = delegate {
            d.interstitial(self, didFailWithError: error)
        }
    }
}
