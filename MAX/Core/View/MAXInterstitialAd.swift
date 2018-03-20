import UIKit

public enum MAXInterstitialCreativeType: String {
    case VAST = "vast3"
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
        self.init(requestManager: MAXAdRequestManager(), sessionManager: MAXSessionManager.shared)
    }
    
    internal init(requestManager: MAXAdRequestManager, sessionManager: MAXSessionManager) {
        self.requestManager = requestManager
        self.sessionManager = sessionManager
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
    
    // NOTE: Call this function on the main queue
    internal func loadInterstitial() {
        switch adResponse?.creativeType {
        case MAXInterstitialCreativeType.VAST.rawValue?:
            loadAdWithVASTRenderer()
        case MAXInterstitialCreativeType.HTML.rawValue?:
            loadAdWithMRAIDRenderer()
        case MAXInterstitialCreativeType.empty.rawValue?:
            loadAdWithAdapter()
        default:
            MAXLog.error("\(String(describing: self)): had unsupported ad creative_type=\(String(describing: adResponse?.creativeType))")
            if let d = delegate {
                d.interstitial(self, didFailWithError: MAXClientError(message: "MAXInterstitialAdError.creativeTypeNotFound"))
            }
        }
    }

    // NOTE: Call this function on the main queue
    @objc public func showAdFromRootViewController(_ rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        switch adResponse?.creativeType {
        case MAXInterstitialCreativeType.VAST.rawValue?:
                MAXLog.debug("\(String(describing: self)): showing ad with VAST renderer")
                vastViewController?.presenterViewController = rootViewController
                vastViewController?.play()
            case MAXInterstitialCreativeType.HTML.rawValue?:
                if (adResponse?.usePartnerRendering)! {
                    MAXLog.debug("\(String(describing: self)): attempting to load ad with third party renderer")
                    interstitialAdapter?.showAd(fromRootViewController: rootViewController)
                } else {
                    MAXLog.debug("\(String(describing: self)): showing ad with MRAID renderer")
                    mraidInterstitial?.rootViewController = rootViewController
                    mraidInterstitial?.show()
                }
            case MAXInterstitialCreativeType.empty.rawValue?:
                MAXLog.debug("\(String(describing: self)): had empty ad response, nothing to show")
            default:
                MAXLog.error("\(String(describing: self)): had unsupported ad creative_type=\(String(describing: adResponse?.creativeType))")
                if let d = delegate {
                    d.interstitial(self, didFailWithError: MAXClientError(message: "MAXInterstitialAdError.creativeTypeNotFound"))
            }
        }
    }

    internal func loadAdWithMRAIDRenderer() {
        MAXLog.debug("\(String(describing: self)): attempting to load ad with MRAID renderer")
        mraidInterstitial = MaxMRAIDInterstitial(
            supportedFeatures: [],
            withHtmlData: adResponse?.creative!,
            withBaseURL: URL(string: "https://\(MAXAdRequest.adsDomain)"),
            delegate: self,
            serviceDelegate: self,
            // NOTE: A rootViewController must be injected later in order to show mraid interstitial (in showAdFromRootController method)
            rootViewController: nil
        )
    }

    internal func loadAdWithVASTRenderer() {
        MAXLog.debug("\(String(describing: self)): attempting to load ad with VAST renderer")
        if let creative = adResponse?.creative {
            if let videoData = creative.data(using: String.Encoding.utf8) {
                vastViewController = MaxVASTViewController(delegate: self, with: rootViewController)
                vastViewController!.loadVideo(with: videoData)
            } else {
                MAXLog.debug("\(String(describing: self)): ERROR: VAST ad response creative had no video data")
            }
        } else {
            MAXLog.debug("\(String(describing: self)): ERROR: VAST ad response had no creative")
        }
    }

    internal func loadAdWithAdapter() {
        guard let adR = adResponse else {
            MAXLog.error("\(String(describing: self)): Tried loading ad with adapter but adResponse was nil.")
            return
        }
        guard let partner = adResponse?.partnerName else {
            MAXLog.error("\(String(describing: self)): Attempted to load interstitial with third party renderer, but no partner was declared")
            loadAdWithMRAIDRenderer()
            return
        }
        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            MAXLog.error("\(String(describing: self)): Tried loading ad with third party ad generator for \(partner), but no generator was configured.")
            loadAdWithMRAIDRenderer()
            return
        }
        let adapter = adViewGenerator.getInterstitialAdapter(fromResponse: adR)
        interstitialAdapter = adapter
        interstitialAdapter?.delegate = self
        interstitialAdapter?.loadAd()
    }

    //TODO - Bryan: Replace interstitial generator with MAXInterstitialFactory (to mirror Android implementation)
    internal func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return MAXConfiguration.shared.getInterstitialGenerator(forPartner: partner)
    }
    
    
    internal func loadResponse(adResponse: MAXAdResponse) {
        
        //TODO - Bryan: For now we keep the adResponse around. Once an InterstitialFactory and Interstitial base class are created, MAXInterstitialAd will keep an Interstitial instance, which can be kept instead of a MAXAdResponse.
        self.adResponse = adResponse
        
        // DANGER: Not threadsafe - If load() is called once and then again before a request returns for the first call, mpAdUnitId will have changed by the time this code is executed. It seems unlikely that a pub would call load() rapidly on the same instance of MAXMoPubBanner, but, if one did, our reporting of which ads are being shown would be inaccurate.
        self.loadInterstitial()
    }
    
    //MARK: MAXAdRequestManagerDelegate
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        MAXLog.debug("\(String(describing: self)).requestAd() succeeded for adUnit:\(String(describing: adResponse?.adUnitId))")
        
        guard adResponse != nil else {
            MAXLog.debug("\(String(describing: self)).requestAd() succeeded but the ad response was nil")
            return
        }
        
        DispatchQueue.main.async {
            self.loadResponse(adResponse: adResponse!)
        }
    }
    
    public func onRequestFailed(error: NSError?) {
        MAXLog.debug("\(String(describing: self)).requestAd() failed with error: \(String(describing: error?.localizedDescription))")
        if let d = self.delegate {
            d.interstitial(nil, didFailWithError: MAXClientError(message: error?.localizedDescription ?? "a nil request error was passed back.."))
        }
    }

    //TODO - Bryan: When Interstitial base class is created, the below methods can be consolidated to one set of InterstitialDelegate methods
    
    //MARK: MAXInterstitialAdapterDelegate methods
 
    public func interstitialWasClicked(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWasClicked")
        adResponse?.trackClick()
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
    }

    public func interstitialDidClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialDidClose")
        if let d = delegate {
            d.interstitialAdDidClose(self)
        }
    }

    public func interstitialWillClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillClose")
        if let d = delegate {
            d.interstitialAdWillClose(self)
        }
    }

    public func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialDidLoad")
        interstitialAdapter?.showAd(fromRootViewController: self.rootViewController)
    }

    public func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillLogImpression")
        adResponse?.trackImpression()
    }

    public func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: MAXClientError) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitial:didFailWithError: \(error.message)")
        if let d = delegate {
            d.interstitial(self, didFailWithError: error)
        }
    }

    
    //MARK: MaxVASTViewControllerDelegate
    
    public func vastReady(_ vastVC: MaxVASTViewController!) {
        MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastReady")
        if let d = delegate {
            d.interstitialAdDidLoad(self)
        }
    }

    public func vastTrackingEvent(_ eventName: String!) {
        MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastTrackingEvent(\(eventName!))")
        if eventName == "start"{
            
            adResponse?.trackImpression()
            
            // An interstitial will be shown because a MAX response was ‘reserved,’ so MAX bypassed any SSP and directly rendered an ad response
            if let adR = adResponse {
                if adR.isReserved {
                    sessionManager.incrementMaxSessionDepth(adUnitId: adR.adUnitId)
                }
            } else {
                MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate - vastTrackingEvent - max session depth was not incremented because the ad response was nil")
            }
        }
        if eventName == "close" {
            if let d = delegate {
                d.interstitialAdWillClose(self)
            }
        }
    }

    public func vastDidDismissFullScreen(_ vastVC: MaxVASTViewController!) {
        MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastDidDismissFullScreen")
        if let d = delegate {
            d.interstitialAdDidClose(self)
        }
    }

    public func vastOpenBrowse(with url: URL!, vastVC: MaxVASTViewController!) {
        MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: vastOpenBrowse")
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
        vastVC.dismiss(animated: false) {
            MAXLinkHandler().openURL(vastVC, url: url, completion: nil)
        }
        vastVC.close()
    }

    public func vastError(_ vastVC: MaxVASTViewController!,_ error: MaxVASTError) {
        MAXLog.debug("\(String(describing: self)) - MaxVASTViewControllerDelegate: failedToLoadAd - Code:\(error.rawValue)")
        let tmpError = MAXClientError(message: "MaxVASTError - \(error.rawValue)")
        if let d = delegate {
            d.interstitial(self, didFailWithError: tmpError)
        }
    }
    
    
    //MARK: MaxMRAIDInterstitialDelegate

    public func mraidInterstitialAdReady(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialAdReady")
        if let d = delegate {
            d.interstitialAdDidLoad(self)
        }
    }

    public func mraidInterstitialDidHide(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialDidHide")
        if let d = delegate {
            d.interstitialAdWillClose(self)
            d.interstitialAdDidClose(self)
        }
    }

    public func mraidInterstitialAdFailed(_ mraidInterstitial: MaxMRAIDInterstitial!, error: Error!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialAdFailed with error - \(error.localizedDescription)")
        if let d = delegate {
            d.interstitial(self, didFailWithError: MAXClientError(message: error.localizedDescription))
        }
    }

    public func mraidInterstitialWillShow(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate - mraidInterstitialWillShow")
        adResponse?.trackImpression()
        
        // An interstitial will be shown because a MAX response was ‘reserved,’ so MAX bypassed any SSP and directly rendered an ad response
        if let adR = adResponse {
            if adR.isReserved {
                sessionManager.incrementMaxSessionDepth(adUnitId: adR.adUnitId)
            }
        } else {
            MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate - mraidInterstitialWillShow - max session depth was not incremented because the ad response was nil")
        }
    }

    public func mraidInterstitialNavigate(_ mraidInterstitial: MaxMRAIDInterstitial!, with url: URL!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidInterstitialNavigate")
        adResponse?.trackClick()
        MAXLinkHandler().openURL(rootViewController!, url: url, completion: nil)
        if let d = delegate {
            d.interstitialAdDidClick(self)
        }
    }

    public func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDInterstitialDelegate: mraidServiceOpenBrowserWithUrlString")

        // This method is called when the MRAID creative requests a native browser to be opened. This is
        // considered to be a click event
        adResponse?.trackClick()
        MAXLinkHandler().openURL(rootViewController!, url: URL(string: url)!, completion: nil)
    }
}
