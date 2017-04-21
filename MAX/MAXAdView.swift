//
//  MAXAdView.swift
//  Pods
//
//

import Foundation
import SKFramework

public protocol MAXAdViewDelegate {
    func viewControllerForPresentingModalView() -> UIViewController!
    
    func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?)
    func adViewDidClick(_ adView: MAXAdView)
    func adViewDidFinishHandlingClick(_ adView: MAXAdView)
    func adViewDidLoad(_ adView: MAXAdView)
    func adViewWillLogImpression(_ adView: MAXAdView)
}

open class MAXAdView : UIView, SKMRAIDViewDelegate, SKMRAIDServiceDelegate {
    private var adResponse: MAXAdResponse!
    
    open var delegate: MAXAdViewDelegate?
    
    private var _mraidView: SKMRAIDView!
    
    public init(adResponse: MAXAdResponse,
                size: CGSize) {
        super.init(frame: CGRect(origin: CGPoint.zero, size: size))
        
        self.adResponse = adResponse
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func loadAd() {
        switch self.adResponse.creativeType {
        case "html":
            if let htmlData = self.adResponse.creative {
                self._mraidView = SKMRAIDView(frame: self.frame,
                                              withHtmlData: htmlData,
                                              withBaseURL: URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)"),
                                              supportedFeatures: [],
                                              delegate: self,
                                              serviceDelegate: self,
                                              rootViewController: self.delegate?.viewControllerForPresentingModalView() ?? self.window?.rootViewController)
                self.addSubview(self._mraidView)
                break
            } else {
                MAXLog.error("MAX: malformed response, HTML creative type but no markup... failing")
                self.delegate?.adViewDidFailWithError(self, error: nil)
                break
            }
        case "empty":
            MAXLog.debug("MAX: empty ad response, nothing to show")
            self.delegate?.adViewDidLoad(self)
            break
        default:
            MAXLog.error("MAX: unsupported ad creative_type=\(self.adResponse.creativeType)")
            self.delegate?.adViewDidFailWithError(self, error: nil)
            break
        }
    }
    
    func trackImpression() {
        self.delegate?.adViewWillLogImpression(self)
        self.adResponse.trackImpression()
    }
    
    func trackClick() {
        self.adResponse.trackClick()
        self.delegate?.adViewDidClick(self)
    }
    
    func click(_ url: URL) {
        self.trackClick()
        
        let vc = self.delegate?.viewControllerForPresentingModalView() ?? self.window?.rootViewController
        MAXLinkHandler().openURL(vc, url: url) {
            self.delegate?.adViewDidFinishHandlingClick(self)
        }
    }
    
    //
    // SKMRAIDViewDelegate
    //
    
    public func mraidViewAdReady(_ mraidView: SKMRAIDView!) {
        MAXLog.debug("MAX: mraidViewAdReady")
        self.trackImpression()
        self.delegate?.adViewDidLoad(self)
    }
    public func mraidViewAdFailed(_ mraidView: SKMRAIDView!) {
        MAXLog.debug("MAX: mraidViewAdFailed")
        self.delegate?.adViewDidFailWithError(self, error: nil)
    }
    public func mraidViewDidClose(_ mraidView: SKMRAIDView!) {
        MAXLog.debug("MAX: mraidViewDidClose")
    }
    public func mraidViewWillExpand(_ mraidView: SKMRAIDView!) {
        MAXLog.debug("MAX: mraidViewWillExpand")
        
        // An MRAID expand action is considered to be a click for tracking purposes. 
        self.trackClick()
    }
    public func mraidViewNavigate(_ mraidView: SKMRAIDView!, with url: URL!) {
        MAXLog.debug("MAX: mraidViewNavigate \(url)")

        // The main mechanism for MRAID banners to request a navigation out to an external browser
        self.click(url)
    }
    public func mraidViewShouldResize(_ mraidView: SKMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        MAXLog.debug("MAX: mraidViewShouldResize to \(position) offscreen=\(allowOffscreen)")
        return true
    }
    
    //
    // SKMRAIDServiceDelegate
    //
    
    public func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("MAX: mraidServiceOpenBrowserWithUrlString \(url)")
        
        // This method is called when an MRAID creative requests a native browser open.
        // This is considered to be a click.
        if let url = URL(string: url) {
            self.click(url)
        }
    }
    
}

