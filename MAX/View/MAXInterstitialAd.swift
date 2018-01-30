import Foundation
import MRAID
import VAST

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
    func interstitial(_ interstitialAd: MAXInterstitialAd, didFailWithError error: Error)
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
        switch adResponse.creativeType {
            case MAXInterstitialCreativeType.VAST.rawValue:
                MAXLog.debug("Interstitial attempting to load ad with VAST renderer")
                if let videoData = adResponse.creative!.data(using: String.Encoding.utf8) {
                    vastViewController = SKVASTViewController(delegate: vastDelegate, with: rootViewController)
                    vastViewController!.loadVideo(with: videoData)
                }
            case MAXInterstitialCreativeType.HTML.rawValue:
                if adResponse.usePartnerRendering {
                    MAXLog.debug("Interstitial attempting to load ad with third party renderer")
                    self.loadAdWithAdapter()
                } else {
                    MAXLog.debug("Interstitial attempting to load ad with MRAID renderer")
                    mraidInterstitial?.rootViewController = rootViewController
                    mraidInterstitial?.show()
                }
            case MAXInterstitialCreativeType.empty.rawValue:
                MAXLog.debug("Interstitial had empty ad response, nothing to show")
            default:
                MAXLog.error("Interstitial had unsupported ad creative_type=\(adResponse.creativeType)")
                delegate?.interstitial(self, didFailWithError: MAXInterstitialAdError.creativeTypeNotFound)
        }
    }

    public func loadAdWithMRAIDRenderer() {
        mraidInterstitial = SKMRAIDInterstitial(
            supportedFeatures: [],
            withHtmlData: adResponse.creative!,
            withBaseURL: URL(string: "https://\(MAXAdRequest.adsDomain)"),
            delegate: mraidDelegate,
            serviceDelegate: mraidDelegate,
            // NOTE: A rootViewController must be injected later in order to show mraid interstitial (in showAdFromRootController method)
            rootViewController: nil
        )
    }

    func loadAdWithAdapter() {
        guard let partner = adResponse.partnerName else {
            MAXLog.error("Attempted to load interstitial with third party renderer, but no partner was declared")
            self.loadAdWithMRAIDRenderer()
            return
        }

        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            MAXLog.error("Tried loading ad with third party ad generator for \(partner), but no generator was configured.")
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
        MAXLog.debug("adapter interstitialWasClicked")
        adResponse.trackClick()
        delegate?.interstitialAdDidClick(self)
    }

    public func interstitialDidClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWasClicked")
        delegate?.interstitialAdDidClose(self)
    }

    public func interstitialWillClose(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWillClose")
        delegate?.interstitialAdWillClose(self)
    }

    public func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialDidLoad")
        interstitialAdapter?.showAd(fromRootViewController: self.rootViewController)
    }

    public func interstitialWillLogImpression(_ interstitial: MAXInterstitialAdapter) {
        MAXLog.debug("Adapter interstitialWillLogImpression")
        adResponse.trackImpression()
    }

    public func interstitial(_ interstitial: MAXInterstitialAdapter, didFailWithError error: Error) {
        MAXLog.debug("adapter interstitial:didFailWithError: \(error.localizedDescription)")
        delegate?.interstitial(self, didFailWithError: error)
    }
}

private class VASTDelegate: NSObject, SKVASTViewControllerDelegate {

    weak private var parent: MAXInterstitialAd!

    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }

    fileprivate func vastReady(_ vastVC: SKVASTViewController!) {
        MAXLog.debug("MAX: vastReady")
        parent.adResponse.trackImpression()
        vastVC.play()
        parent.delegate?.interstitialAdDidLoad(parent)
    }

    fileprivate func vastTrackingEvent(_ eventName: String!) {
        MAXLog.debug("MAX: vastTrackingEvent(\(eventName!))")
        if eventName == "close" {
            parent.delegate?.interstitialAdWillClose(parent)
        }
    }

    fileprivate func vastDidDismissFullScreen(_ vastVC: SKVASTViewController!) {
        MAXLog.debug("MAX: vastDidDismissFullScreen")
        parent.delegate?.interstitialAdDidClose(parent)
    }

    fileprivate func vastOpenBrowse(withUrl vastVC: SKVASTViewController!, url: URL!) {
        MAXLog.debug("MAX: vastOpenBrowse")
        parent.delegate?.interstitialAdDidClick(parent)
        vastVC.dismiss(animated: false) {
            MAXLinkHandler().openURL(vastVC, url: url, completion: nil)
        }
        vastVC.close()
    }
}

private class MRAIDDelegate: NSObject, SKMRAIDInterstitialDelegate, SKMRAIDServiceDelegate {
    weak private var parent: MAXInterstitialAd!

    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }

    fileprivate func mraidInterstitialAdReady(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialAdReady")
        parent.delegate?.interstitialAdDidLoad(parent)
    }

    fileprivate func mraidInterstitialDidHide(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialDidHide")
        parent.delegate?.interstitialAdWillClose(parent)
        parent.delegate?.interstitialAdDidClose(parent)
    }

    fileprivate func mraidInterstitialAdFailed(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialAdFailed")
    }

    fileprivate func mraidInterstitialWillShow(_ mraidInterstitial: SKMRAIDInterstitial!) {
        MAXLog.debug("MAX: mraidInterstitialWillShow")
        parent.adResponse.trackImpression()
    }

    fileprivate func mraidInterstitialNavigate(_ mraidInterstitial: SKMRAIDInterstitial!, with url: URL!) {
        MAXLog.debug("MAX: mraidInterstitialNavigate")

        parent.adResponse.trackClick()
        MAXLinkHandler().openURL(parent.rootViewController!, url: url, completion: nil)
    }

    fileprivate func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("MAX: mraidServiceOpenBrowserWithUrlString")

        // This method is called when the MRAID creative requests a native browser to be opened. This is
        // considered to be a click event
        parent.adResponse.trackClick()
        MAXLinkHandler().openURL(parent.rootViewController!, url: URL(string: url)!, completion: nil)
    }
}
