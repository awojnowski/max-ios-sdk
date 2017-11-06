import Foundation
import MRAID
import VAST

public enum MAXInterstitialCreativeType: String {
    case VAST = "vast3"
    case HTML = "html"
    case Native = "native"
    case Empty = "empty"
}

public protocol MAXInterstitialAdDelegate {
    func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd)
    func interstitial(_ interstitialAd: MAXInterstitialAd, didFailWithError: Error)
}

public enum MAXInterstitialAdError: Error {
    case adapterFailure(message: String)
    case creativeTypeNotFound
}

open class MAXInterstitialAd: MAXInterstitialAdapterDelegate {
    fileprivate var adResponse: MAXAdResponse!

    open var delegate: MAXInterstitialAdDelegate?
    
    fileprivate var rootViewController : UIViewController?
    
    private var vastDelegate: VASTDelegate!
    private var vastViewController: SKVASTViewController?

    private var mraidDelegate: MRAIDDelegate!
    private var mraidInterstitial: SKMRAIDInterstitial?
    
    private var interstitialAdapter: MAXInterstitialAdapter?
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        self.vastDelegate = VASTDelegate(parent: self)
        self.mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    public func showAdFromRootViewController(_ rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        switch self.adResponse.creativeType {
            case MAXInterstitialCreativeType.VAST.rawValue:
                MAXLog.debug("Interstitial attempting to load ad with VAST renderer")
                if let videoData = self.adResponse.creative!.data(using: String.Encoding.utf8) {
                    self.vastViewController = SKVASTViewController(delegate: vastDelegate, with: rootViewController)
                    self.vastViewController!.loadVideo(with: videoData)
                }
            case MAXInterstitialCreativeType.HTML.rawValue:
                if self.adResponse.usePartnerRendering {
                    MAXLog.debug("Interstitial attempting to load ad with third party renderer")
                    self.loadAdWithAdapter()
                } else {
                    MAXLog.debug("Interstitial attempting to load ad with MRAID renderer")
                    self.loadAdWithMRAIDRenderer()
                }
            case MAXInterstitialCreativeType.Empty.rawValue:
                MAXLog.debug("Interstitial had empty ad response, nothing to show")
                break
            default:
                MAXLog.error("Interstitial had unsupported ad creative_type=\(self.adResponse.creativeType)")
                self.delegate?.interstitial(self, didFailWithError: MAXInterstitialAdError.creativeTypeNotFound)
                break
        }
    }
    
    func loadAdWithMRAIDRenderer() {
        self.mraidInterstitial = SKMRAIDInterstitial(
            supportedFeatures:[],
            withHtmlData: self.adResponse.creative!,
            withBaseURL: URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)"),
            delegate: self.mraidDelegate,
            serviceDelegate: self.mraidDelegate,
            rootViewController: self.rootViewController
        )
    }
    
    func loadAdWithAdapter() {
        guard let partner = self.adResponse.partnerName else {
            MAXLog.error("Attempted to load interstitial with third party renderer, but no partner was declared")
            self.loadAdWithMRAIDRenderer()
            return
        }
        
        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            MAXLog.error("Tried loading ad with third party ad generator for \(partner), but no generator was configured.")
            self.loadAdWithMRAIDRenderer()
            return
        }
        
        let adapter = adViewGenerator.getInterstitialAdapter(fromResponse: self.adResponse)

        self.interstitialAdapter = adapter
        self.interstitialAdapter?.delegate = self
        self.interstitialAdapter?.loadAd()
    }
    
    func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return MAXConfiguration.shared.getInterstitialGenerator(forPartner: partner)
    }
    
    /*
     * MAXInterstitialAdapterDelegate methods
     */
    public func interstitialWasClicked(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("adapter interstitialWasClicked")
        self.adResponse.trackClick()
        self.delegate?.interstitialAdDidClick(self)
    }
    
    public func interstitialDidClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWasClicked")
        self.delegate?.interstitialAdDidClose(self)
    }
    
    public func interstitialWillClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWillClose")
        self.delegate?.interstitialAdWillClose(self)
    }
    
    public func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialDidLoad")
        self.interstitialAdapter?.showAd(fromRootViewController: self.rootViewController)
    }
    
    public func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWillLogImpression")
        self.adResponse.trackImpression()
    }
    
    public func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: Error) {
        MAXLog.debug("adapter interstitial:didFailWithError: \(error.localizedDescription)")
        self.delegate?.interstitial(self, didFailWithError: error)
    }
}

private class VASTDelegate: NSObject, SKVASTViewControllerDelegate {

    private var parent: MAXInterstitialAd
    
    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }
    
    fileprivate func vastReady(_ vastVC: SKVASTViewController!) {
        self.parent.adResponse.trackImpression()
        vastVC.play()
    }
    
    fileprivate func vastTrackingEvent(_ eventName: String!) {
        MAXLog.debug("MAX: vastTrackingEvent(\(eventName!))")
        if eventName == "close" {
            self.parent.delegate?.interstitialAdWillClose(self.parent)
        }
    }
    
    fileprivate func vastDidDismissFullScreen(_ vastVC: SKVASTViewController!) {
        self.parent.delegate?.interstitialAdDidClose(self.parent)
    }
    
    fileprivate func vastOpenBrowse(withUrl vastVC: SKVASTViewController!, url: URL!) {
        self.parent.delegate?.interstitialAdDidClick(self.parent)
        vastVC.dismiss(animated: false) {
            MAXLinkHandler().openURL(vastVC, url: url, completion: nil)
        }
        vastVC.close()
    }
}

private class MRAIDDelegate: NSObject, SKMRAIDInterstitialDelegate, SKMRAIDServiceDelegate {
    private var parent: MAXInterstitialAd
    
    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }
    
    fileprivate func mraidInterstitialAdReady(_ mraidInterstitial: SKMRAIDInterstitial!) {
        if mraidInterstitial.isAdReady() {
            mraidInterstitial.show()
        }
    }
    
    fileprivate func mraidInterstitialDidHide(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialDidHide")
        self.parent.delegate?.interstitialAdWillClose(self.parent)
        self.parent.delegate?.interstitialAdDidClose(self.parent)
    }
    
    fileprivate func mraidInterstitialAdFailed(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialAdFailed")
    }
    
    fileprivate func mraidInterstitialWillShow(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialWillShow")
        self.parent.adResponse.trackImpression()
    }
    
    fileprivate func mraidInterstitialNavigate(_ mraidInterstitial: SKMRAIDInterstitial!, with url: URL!) {
        MAXLog.debug("MAX: mraidInterstitialNavigate")
    }
    
    fileprivate func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("MAX: mraidServiceOpenBrowserWithUrlString")

        // This method is called when the MRAID creative requests a native browser to be opened. This is
        // considered to be a click event
        self.parent.adResponse.trackClick()
        MAXLinkHandler().openURL(parent.rootViewController!, url: URL(string: url)!, completion: nil)
    }
}
