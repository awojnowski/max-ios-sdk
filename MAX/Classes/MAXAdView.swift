//
//  MAXAdView.swift
//  Pods
//
//

import Foundation

public protocol MAXAdViewDelegate {
    var viewControllerForPresentingModalView :  UIViewController { get }
    
    func adViewDidFailWithError(_ adView: MAXAdView, error: NSError?)
    func adViewDidClick(_ adView: MAXAdView)
    func adViewDidFinishHandlingClick(_ adView: MAXAdView)
    func adViewDidLoad(_ adView: MAXAdView)
    func adViewWillLogImpression(_ adView: MAXAdView)
}

open class MAXAdView : UIView {
    private var adResponse: MAXAdResponse!
    
    open var delegate: MAXAdViewDelegate?
    
    private var _mraidDelegate: MRAIDDelegate!
    private var _mraidView: SKMRAIDView!
    
    public init(adResponse: MAXAdResponse,
                size: CGSize) {
        super.init(frame: CGRect(origin: CGPoint.zero, size: size))
        
        self.adResponse = adResponse
        self._mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func loadAd() {
        switch self.adResponse.creativeType {
        case "html":
            self._mraidView = SKMRAIDView(frame: self.frame,
                                          withHtmlData: self.adResponse.creative,
                                          withBaseURL: URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)"),
                                          supportedFeatures: [],
                                          delegate: self._mraidDelegate,
                                          serviceDelegate: self._mraidDelegate,
                                          rootViewController: self.delegate?.viewControllerForPresentingModalView ?? self.window?.rootViewController)
            self.addSubview(self._mraidView)
        case "empty":
            NSLog("MAX: empty ad response, nothing to show")
            self.delegate?.adViewDidLoad(self)
            break
        default:
            NSLog("MAX: unsupported ad creative_type=\(self.adResponse.creativeType)")
            self.delegate?.adViewDidFailWithError(self, error: nil)
            break
        }
    }
    
    func trackImpression() {
        self.delegate?.adViewWillLogImpression(self)
        self.adResponse.trackImpression()
    }
    
    func click(_ url: URL) {
        self.delegate?.adViewDidClick(self)
        let vc = self.delegate?.viewControllerForPresentingModalView ?? self.window?.rootViewController
        MAXLinkHandler().openURL(vc, url: url) {
            self.delegate?.adViewDidFinishHandlingClick(self)
        }
    }
}

private class MRAIDDelegate : NSObject, SKMRAIDViewDelegate, SKMRAIDServiceDelegate {
    private var parent : MAXAdView
    
    init(parent: MAXAdView) {
        self.parent = parent
    }
    
    //
    //
    //
    
    open func mraidViewAdReady(_ mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewAdReady")
        parent.trackImpression()
        parent.delegate?.adViewDidLoad(parent)
    }
    open func mraidViewAdFailed(_ mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewAdFailed")
        parent.delegate?.adViewDidFailWithError(parent, error: nil)
    }
    open func mraidViewDidClose(_ mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewDidClose")
    }
    open func mraidViewWillExpand(_ mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewWillExpand")
    }
    open func mraidViewNavigate(_ mraidView: SKMRAIDView!, with url: URL!) {
        NSLog("MAX: mraidViewNavigate \(url)")
        parent.click(url)
    }
    open func mraidViewShouldResize(_ mraidView: SKMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        NSLog("MAX: mraidViewShouldResize")
        return false
    }
    
    //
    //
    //
    
    open func mraidServiceOpenBrowser(withUrlString url: String) {
        NSLog("MAX: mraidServiceOpenBrowserWithUrlString \(url)")
        if let url = URL(string: url) {
            parent.click(url)
        }
    }
    
}

