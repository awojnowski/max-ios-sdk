import UIKit

public enum MAXBannerCreativeType: String {
    // HTML is equivalent to MRAID. We have it as 'html' for backwards compatibility. 
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
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        // Guard for nil because MAXAdView is currently exposed to ObjC
        if adResponse == nil {
            reportError(message: "\(String(describing: self)): loading failed because the adResponse was nil.")
            return
        }
        
        guard let creative = self.adResponse.creative else {
            reportError(message: "\(String(describing: self)): loading failed because the ad response creative is nil")
            return
        }
        
        switch adResponse.creativeType {
        case MAXBannerCreativeType.MRAID.rawValue:
            if self.adResponse.usePartnerRendering {
                let partner = self.adResponse.partnerName
                MAXLogger.debug("\(String(describing: self)) - Loading creative using view from third party: \(String(describing: partner))")
                self.loadAdWithAdapter(adResponse: adResponse)
            } else {
                MAXLogger.debug("\(String(describing: self)) - Loading creative using MRAID renderer")
                self.loadAdWithMRAIDRenderer(creative: creative)
            }
        case MAXBannerCreativeType.empty.rawValue:
            MAXLogger.debug("\(String(describing: self)) - AdView had empty ad response, nothing to show")
            self.delegate?.adViewDidLoad(self)
        default:
            reportError(message: "\(String(describing: self)) - AdView had unsupported ad creative_type = <\(self.adResponse.creativeType)>")
        }
    }

    internal func loadAdWithMRAIDRenderer(creative: String) {
        
        self.mraidView = MaxMRAIDView(
            frame: self.bounds,
            withHtmlData: creative,
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
    internal func loadAdWithAdapter(adResponse: MAXAdResponse) {
        
        guard let partner = adResponse.partnerName else {
            reportError(message: "\(String(describing: self)): Attempted to load ad with third party renderer, but no winner was declared. Trying to load with MAX MRAID renderer instead.")
            self.loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }

        guard let adViewGenerator = getGenerator(forPartner: partner) else {
            reportError(message: "\(String(describing: self)): Tried loading ad with third party generator, but no generator for \(partner) was configured. Trying to load with MAX MRAID renderer instead.")
            self.loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }

        guard let adapter = adViewGenerator.getAdViewAdapter(
            fromResponse: adResponse,
            withSize: adSize,
            rootViewController: delegate?.viewControllerForMaxPresentingModalView?() ?? UIApplication.shared.delegate?.window??.rootViewController
        ) else {
            reportError(message: "\(String(describing: self)): Unable to retrieve third party ad renderer. Trying to load with MAX MRAID renderer instead.")
            self.loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }
        
        adViewAdapter = adapter
        adViewAdapter.delegate = self
        adViewAdapter.loadAd()
        
        guard let view = adapter.adView else {
            reportError(message: "\(String(describing: self)): Unable to render ad with a third party adapter since its adView is nil. Trying to load with MAX MRAID renderer instead.")
            self.loadAdWithMRAIDRenderer(creative: adResponse.creative!)
            return
        }
        
        self.addSubview(view)
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
        MAXLogger.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view was clicked")
        self.trackClick()
    }

    public func adViewDidLoad(_ adView: MAXAdViewAdapter) {
        MAXLogger.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view was loaded")
        self.delegate?.adViewDidLoad(self)
    }

    public func adView(_ adView: MAXAdViewAdapter, didFailWithError error: Error) {
        MAXLogger.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view failed with error: \(error.localizedDescription)")
        self.delegate?.adViewDidFailWithError(self, error: error as NSError)
    }

    public func adViewWillLogImpression(_ adView: MAXAdViewAdapter) {
        MAXLogger.debug("\(String(describing: self)) - MAXAdViewAdapterDelegate - Generated ad view logged an impression")
        self.trackImpression()
    }

    
    //MARK: MaxMRAIDViewDelegate methods
    
    public func mraidViewAdReady(_ mraidView: MaxMRAIDView!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewAdReady")
        self.trackImpression()
        self.delegate?.adViewDidLoad(self)
    }

    public func mraidViewAdFailed(_ mraidView: MaxMRAIDView!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewAdFailed")
        self.delegate?.adViewDidFailWithError(self, error: nil)
    }

    public func mraidViewDidClose(_ mraidView: MaxMRAIDView!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewDidClose")
    }

    public func mraidViewWillExpand(_ mraidView: MaxMRAIDView!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewWillExpand")

        // An MRAID expand action is considered to be a click for tracking purposes. 
        self.trackClick()
    }

    public func mraidViewNavigate(_ mraidView: MaxMRAIDView!, with url: URL!) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewNavigate \(url)")

        // The main mechanism for MRAID banners to request a navigation out to an external browser
        self.click(url)
    }

    public func mraidViewShouldResize(_ mraidView: MaxMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDViewDelegate - mraidViewShouldResize to \(position) offscreen=\(allowOffscreen)")
        return true
    }

    
    //MARK: MaxMRAIDServiceDelegate
     
    public func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLogger.debug("\(String(describing: self)) - MaxMRAIDServiceDelegate - mraidServiceOpenBrowserWithUrlString \(url)")

        // This method is called when an MRAID creative requests a native browser open.
        // This is considered to be a click.
        if let url = URL(string: url) {
            self.click(url)
        }
    }
    
    
    //MARK: Temp until MAXBannerDecorator is created
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        let error = MAXClientError(message: message)
        if let d = delegate {
            d.adViewDidFailWithError(self, error: error)
        }
    }
}
