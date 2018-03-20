import UIKit

public enum MAXBannerCreativeType: String {
    case MRAID = "html"
    case empty = "empty"
}

// TODO - Bryan: These callbacks don't currently match Android Banner callbacks. When MAXAdView is broken up, it may make sense to remove some of these.
@objc public protocol MAXAdViewDelegate: NSObjectProtocol {
    func adViewDidLoad(_ adView: MAXAdView?)
    func adViewWillLogImpression(_ adView: MAXAdView?)
    func adViewDidClick(_ adView: MAXAdView?)
    func adViewDidFinishHandlingClick(_ adView: MAXAdView?)
    func adViewDidFailWithError(_ adView: MAXAdView?, error: NSError?)
    
    // NOTE: If this function is not implemented, ads will be shown in the application's root view controller.
    @objc optional func viewControllerForMaxPresentingModalView() -> UIViewController?
}

// NOTE: MAXAdView is approximately equivalent to a combination of Android Banner, BannerDecorator, HTMLBanner, MRAIDBanner, and BannerFactoryImpl classes
// TODO - Bryan: Break up this class into corresponding Android classes
// TODO - Since we have external facing MAXBannerAdView, maybe it's alright for this class to be internal? Unfortunately sample app CreativeController needs direct access to this class to show bundled creative responses..
public class MAXAdView: UIView, MaxMRAIDViewDelegate, MaxMRAIDServiceDelegate, MAXAdViewAdapterDelegate {
    // The delegate should be weak here so that if the CustomEvent object itself gets deallocated
    // due to a new request being initiated by the SSP (e.g. for a timeout or other failure) 
    // then this reference becomes nil. This way we do not end up calling back into an invalid SSP stack.
    @objc public weak var delegate: MAXAdViewDelegate?

    private let sessionManager: MAXSessionManager
    private let adResponse: MAXAdResponse
    private var mraidView: MaxMRAIDView!
    private var adViewAdapter: MAXAdViewAdapter!
    private var adSize: CGSize!
    
    internal var adUnitId: String {
        return adResponse.adUnitId
    }

    @objc public convenience init(adResponse: MAXAdResponse, size: CGSize) {
        self.init(adResponse: adResponse, size: size, sessionManager: MAXSessionManager.shared)
    }
    
    internal init(adResponse: MAXAdResponse, size: CGSize, sessionManager: MAXSessionManager) {
        self.adResponse = adResponse
        self.adSize = size
        self.sessionManager = sessionManager
        super.init(frame: CGRect(origin: CGPoint.zero, size: size))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func loadAd() {
        switch self.adResponse.creativeType {
        case MAXBannerCreativeType.MRAID.rawValue:
            if self.adResponse.usePartnerRendering {
                let partner = self.adResponse.partnerName
                MAXLog.debug("\(String(describing: self)) - Loading creative using view from third party: \(String(describing: partner))")
                self.loadAdWithAdapter()
            } else {
                MAXLog.debug("\(String(describing: self)) - Loading creative using MRAID renderer")
                self.loadAdWithMRAIDRenderer()
            }

        case MAXBannerCreativeType.empty.rawValue:
            MAXLog.debug("\(String(describing: self)) - AdView had empty ad response, nothing to show")
            self.delegate?.adViewDidLoad(self)

        default:
            MAXLog.error("\(String(describing: self)) - AdView had unsupported ad creative_type=\(self.adResponse.creativeType)")
            self.delegate?.adViewDidFailWithError(self, error: nil)
        }
    }

    internal func loadAdWithMRAIDRenderer() {
        guard let htmlData = self.adResponse.creative else {
            MAXLog.error("\(String(describing: self)) - Malformed response, HTML creative type but no markup... failing")
            MAXErrorReporter.shared.logError(message: "Malformed response, creative with type html had no markup")
            self.delegate?.adViewDidFailWithError(self, error: nil)
            return
        }

        self.mraidView = MaxMRAIDView(
            frame: self.bounds,
            withHtmlData: htmlData,
            withBaseURL: URL(string: "https://\(MAXAdRequest.adsDomain)"),
            supportedFeatures: [],
            delegate: self,
            serviceDelegate: self,
            rootViewController: self.delegate?.viewControllerForMaxPresentingModalView?() ?? UIApplication.shared.delegate?.window??.rootViewController
        )

        self.addSubview(self.mraidView)
    }

    /// Attempt to load the ad with a third party adapter. The adapter must have been registered
    /// in MAXConfiguration's adapter registry. The third party adapter will fail to be initialized
    /// if there's no identifiable partner in the ad response or if a generator for the adapter can't
    /// be found. This can also fail if the adapter doesn't create a renderable ad view with the
    /// third party's code. If for any reason `loadAdWithAdapter` fails, it will attempt to fall
    /// back to `loadAdWithMRAIDRenderer`.
    internal func loadAdWithAdapter() {
        guard let partner = self.adResponse.partnerName else {
            MAXLog.error("Attempted to load ad with third party renderer, but no winner was declared")
            self.loadAdWithMRAIDRenderer()
            return
        }

        guard let adViewGenerator = self.getGenerator(forPartner: partner) else {
            MAXLog.error("Tried loading ad with third party generator, but no generator for \(partner) was configured.")
            self.loadAdWithMRAIDRenderer()
            return
        }

        guard let adapter = adViewGenerator.getAdViewAdapter(
            fromResponse: self.adResponse,
            withSize: self.adSize,
            rootViewController: self.delegate?.viewControllerForMaxPresentingModalView?() ?? UIApplication.shared.delegate?.window??.rootViewController
        ) else {
            MAXLog.error("Unable to load ad view generator, generator loadAdView returned nil")
            self.loadAdWithMRAIDRenderer()
            return
        }

        self.adViewAdapter = adapter
        self.adViewAdapter.delegate = self
        self.adViewAdapter.loadAd()

        if let view = self.adViewAdapter.adView {
            self.addSubview(view)
        } else {
            // TODO - Bryan: Add an error to be passed back in adViewDidFailWithError
            self.delegate?.adViewDidFailWithError(self, error: nil)
        }
    }

    internal func getGenerator(forPartner: String) -> MAXAdViewAdapterGenerator? {
        return MAXConfiguration.shared.getAdViewGenerator(forPartner: forPartner)
    }

    internal func trackImpression() {
        self.delegate?.adViewWillLogImpression(self)
        self.adResponse.trackImpression()
    }

    internal func trackClick() {
        self.adResponse.trackClick()
        self.delegate?.adViewDidClick(self)
    }

    internal func click(_ url: URL) {
        self.trackClick()

        let vc = self.delegate?.viewControllerForMaxPresentingModalView?() ?? UIApplication.shared.delegate?.window??.rootViewController
        MAXLinkHandler().openURL(vc, url: url) {
            self.delegate?.adViewDidFinishHandlingClick(self)
        }
    }

    
    //MARK: MAXAdViewAdapterDelegate methods
    //TODO - Bryan: think if we would like to have MAXAdViewAdapter and delegate methods public or internal -> depends on if we want to allow pubs to make their own adapters?
 
    public func adViewWasClicked(_ adView: MAXAdViewAdapter) {
        MAXLog.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view was clicked")
        self.trackClick()
    }

    public func adViewDidLoad(_ adView: MAXAdViewAdapter) {
        MAXLog.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view was loaded")
        self.delegate?.adViewDidLoad(self)
    }

    public func adView(_ adView: MAXAdViewAdapter, didFailWithError error: Error) {
        MAXLog.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view failed with error: \(error.localizedDescription)")
        self.delegate?.adViewDidFailWithError(self, error: error as NSError)
    }

    public func adViewWillLogImpression(_ adView: MAXAdViewAdapter) {
        MAXLog.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view logged an impression")
        self.trackImpression()
    }

    
    //MARK: MaxMRAIDViewDelegate methods
    
    public func mraidViewAdReady(_ mraidView: MaxMRAIDView!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewAdReady")
        self.trackImpression()
        self.delegate?.adViewDidLoad(self)
    }

    public func mraidViewAdFailed(_ mraidView: MaxMRAIDView!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewAdFailed")
        self.delegate?.adViewDidFailWithError(self, error: nil)
    }

    public func mraidViewDidClose(_ mraidView: MaxMRAIDView!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewDidClose")
    }

    public func mraidViewWillExpand(_ mraidView: MaxMRAIDView!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewWillExpand")

        // An MRAID expand action is considered to be a click for tracking purposes. 
        self.trackClick()
    }

    public func mraidViewNavigate(_ mraidView: MaxMRAIDView!, with url: URL!) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewNavigate \(url)")

        // The main mechanism for MRAID banners to request a navigation out to an external browser
        self.click(url)
    }

    public func mraidViewShouldResize(_ mraidView: MaxMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewShouldResize to \(position) offscreen=\(allowOffscreen)")
        return true
    }

    
    //MARK: MaxMRAIDServiceDelegate
     
    public func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("\(String(describing: self)) - MaxMRAIDServiceDelegate - mraidServiceOpenBrowserWithUrlString \(url)")

        // This method is called when an MRAID creative requests a native browser open.
        // This is considered to be a click.
        if let url = URL(string: url) {
            self.click(url)
        }
    }
}
