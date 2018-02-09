import Foundation
import MAXBase
import MAXBase

public enum MAXInterstitialCreativeType: String {
    case VAST = "vast3"
    case HTML = "html"
    case empty = "empty"
}

public protocol MAXInterstitialAdDelegate: class {
    func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd)
    func interstitial(_ interstitialAd: MAXInterstitialAd, didFailWithError error: MAXClientError)
}

public enum MAXInterstitialAdError: Error {
    case adapterFailure(message: String)
    case creativeTypeNotFound
}

open class MAXInterstitialAd: MAXInterstitialAdapterDelegate {
    fileprivate var adResponse: MAXAdResponse!

    public weak var delegate: MAXInterstitialAdDelegate?

    fileprivate var rootViewController: UIViewController?

    private var vastDelegate: VASTDelegate!
    private var vastViewController: MaxVASTViewController?

    private var mraidDelegate: MRAIDDelegate!
    private var mraidInterstitial: MaxMRAIDInterstitial?

    private var interstitialAdapter: MAXInterstitialAdapter?

    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        self.vastDelegate = VASTDelegate(parent: self)
        self.mraidDelegate = MRAIDDelegate(parent: self)
    }

    public func showAdFromRootViewController(_ rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        switch adResponse.creativeType {
            case MAXInterstitialCreativeType.VAST.rawValue:
                MAXLog.debug("\(String(describing: self)): showing ad with VAST renderer")
                vastViewController?.presenterViewController = rootViewController
                vastViewController?.play()
            case MAXInterstitialCreativeType.HTML.rawValue:
                if adResponse.usePartnerRendering {
                    MAXLog.debug("\(String(describing: self)): attempting to load ad with third party renderer")
                    self.loadAdWithAdapter()
                } else {
                    MAXLog.debug("\(String(describing: self)): showing ad with MRAID renderer")
                    mraidInterstitial?.rootViewController = rootViewController
                    mraidInterstitial?.show()
                }
            case MAXInterstitialCreativeType.empty.rawValue:
                MAXLog.debug("\(String(describing: self)): had empty ad response, nothing to show")
            default:
                MAXLog.error("\(String(describing: self)): had unsupported ad creative_type=\(adResponse.creativeType)")
                delegate?.interstitial(self, didFailWithError: MAXClientError(message: "MAXInterstitialAdError.creativeTypeNotFound"))
        }
    }

    public func loadAdWithMRAIDRenderer() {
        MAXLog.debug("\(String(describing: self)): attempting to load ad with MRAID renderer")
        mraidInterstitial = MaxMRAIDInterstitial(
            supportedFeatures: [],
            withHtmlData: adResponse.creative!,
            withBaseURL: URL(string: "https://\(MAXAdRequest.adsDomain)"),
            delegate: mraidDelegate,
            serviceDelegate: mraidDelegate,
            // NOTE: A rootViewController must be injected later in order to show mraid interstitial (in showAdFromRootController method)
            rootViewController: nil
        )
    }

    public func loadAdWithVASTRenderer() {
        MAXLog.debug("\(String(describing: self)): attempting to load ad with VAST renderer")
        if let creative = adResponse.creative {
            if let videoData = creative.data(using: String.Encoding.utf8) {
                vastViewController = MaxVASTViewController(delegate: vastDelegate, with: rootViewController)
                vastViewController!.loadVideo(with: videoData)
            } else {
                MAXLog.debug("\(String(describing: self)): ERROR: VAST ad response creative had no video data")
            }
        } else {
            MAXLog.debug("\(String(describing: self)): ERROR: VAST ad response had no creative")
        }
    }

    func loadAdWithAdapter() {
        guard let partner = adResponse.partnerName else {
            MAXLog.error("\(String(describing: self)): Attempted to load interstitial with third party renderer, but no partner was declared")
            self.loadAdWithMRAIDRenderer()
            return
        }

        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            MAXLog.error("\(String(describing: self)): Tried loading ad with third party ad generator for \(partner), but no generator was configured.")
            self.loadAdWithMRAIDRenderer()
            return
        }

        let adapter = adViewGenerator.getInterstitialAdapter(fromResponse: adResponse)

        interstitialAdapter = adapter
        interstitialAdapter?.delegate = self
        interstitialAdapter?.loadAd()
    }

    func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return MAXConfiguration.shared.getInterstitialGenerator(forPartner: partner)
    }

    /*
     * MAXInterstitialAdapterDelegate methods
     */
    public func interstitialWasClicked(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWasClicked")
        adResponse.trackClick()
        delegate?.interstitialAdDidClick(self)
    }

    public func interstitialDidClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWasClicked")
        delegate?.interstitialAdDidClose(self)
    }

    public func interstitialWillClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillClose")
        delegate?.interstitialAdWillClose(self)
    }

    public func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialDidLoad")
        interstitialAdapter?.showAd(fromRootViewController: self.rootViewController)
    }

    public func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitialWillLogImpression")
        adResponse.trackImpression()
    }

    public func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: MAXClientError) {
        MAXLog.debug("\(String(describing: self)): MAXInterstitialAdapterDelegate interstitial:didFailWithError: \(error.message)")
        delegate?.interstitial(self, didFailWithError: error)
    }
}

private class VASTDelegate: NSObject, MaxVASTViewControllerDelegate {

    weak private var parent: MAXInterstitialAd!

    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }

    fileprivate func vastReady(_ vastVC: MaxVASTViewController!) {
        MAXLog.debug("MAXInterstitialAd MaxVASTViewControllerDelegate: vastReady")
        parent.delegate?.interstitialAdDidLoad(parent)
    }

    fileprivate func vastTrackingEvent(_ eventName: String!) {
        MAXLog.debug("MAXInterstitialAd MaxVASTViewControllerDelegate: vastTrackingEvent(\(eventName!))")
        if eventName == "start"{
            parent.adResponse.trackImpression()
        }
        if eventName == "close" {
            parent.delegate?.interstitialAdWillClose(parent)
        }
    }

    fileprivate func vastDidDismissFullScreen(_ vastVC: MaxVASTViewController!) {
        MAXLog.debug("MAXInterstitialAd MaxVASTViewControllerDelegate: vastDidDismissFullScreen")
        parent.delegate?.interstitialAdDidClose(parent)
    }

    fileprivate func vastOpenBrowse(with url: URL!, vastVC: MaxVASTViewController!) {
        MAXLog.debug("MAXInterstitialAd MaxVASTViewControllerDelegate: vastOpenBrowse")
        parent.delegate?.interstitialAdDidClick(parent)
        vastVC.dismiss(animated: false) {
            MAXLinkHandler().openURL(vastVC, url: url, completion: nil)
        }
        vastVC.close()
    }

    fileprivate func vastError(_ vastVC: MaxVASTViewController!, error: MaxVASTError) {
        MAXLog.debug("MAXInterstitialAd MaxVASTViewControllerDelegate: failedToLoadAd - Code:\(error.rawValue)")
        let tmpError = MAXClientError(message: "MaxVASTError - \(error.rawValue)")
        parent.delegate?.interstitial(parent, didFailWithError: tmpError)
    }
}

private class MRAIDDelegate: NSObject, MaxMRAIDInterstitialDelegate, MaxMRAIDServiceDelegate {
    weak private var parent: MAXInterstitialAd!

    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }

    fileprivate func mraidInterstitialAdReady(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidInterstitialAdReady")
        parent.delegate?.interstitialAdDidLoad(parent)
    }

    fileprivate func mraidInterstitialDidHide(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidInterstitialDidHide")
        parent.delegate?.interstitialAdWillClose(parent)
        parent.delegate?.interstitialAdDidClose(parent)
    }

    fileprivate func mraidInterstitialAdFailed(_ mraidInterstitial: MaxMRAIDInterstitial!, error: Error!) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidInterstitialAdFailed with error - \(error.localizedDescription)")
        parent.delegate?.interstitial(parent, didFailWithError: MAXClientError(message: error.localizedDescription))
    }

    fileprivate func mraidInterstitialWillShow(_ mraidInterstitial: MaxMRAIDInterstitial!) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidInterstitialWillShow")
        parent.adResponse.trackImpression()
    }

    fileprivate func mraidInterstitialNavigate(_ mraidInterstitial: MaxMRAIDInterstitial!, with url: URL!) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidInterstitialNavigate")
        parent.adResponse.trackClick()
        MAXLinkHandler().openURL(parent.rootViewController!, url: url, completion: nil)
        parent.delegate?.interstitialAdDidClick(parent)
    }

    fileprivate func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("MAXInterstitialAd MaxMRAIDInterstitialDelegate: mraidServiceOpenBrowserWithUrlString")

        // This method is called when the MRAID creative requests a native browser to be opened. This is
        // considered to be a click event
        parent.adResponse.trackClick()
        MAXLinkHandler().openURL(parent.rootViewController!, url: URL(string: url)!, completion: nil)
    }
}
