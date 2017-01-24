//
//  MAXAdView.swift
//  Pods
//
//

import Foundation

public protocol MAXAdViewDelegate {
    var viewControllerForPresentingModalView :  UIViewController { get }
    
    func adViewDidFailWithError(adView: MAXAdView, error: NSError?)
    func adViewDidClick(adView: MAXAdView)
    func adViewDidFinishHandlingClick(adView: MAXAdView)
    func adViewDidLoad(adView: MAXAdView)
    func adViewWillLogImpression(adView: MAXAdView)
}

public class MAXAdView : UIView {
    private var adResponse: MAXAdResponse!
    
    public var delegate: MAXAdViewDelegate?
    
    private var _mraidDelegate: MRAIDDelegate!
    private var _mraidView: SKMRAIDView!
    
    public init(adResponse: MAXAdResponse,
                size: CGSize) {
        super.init(frame: CGRect(origin: CGPointZero, size: size))
        
        self.adResponse = adResponse
        self._mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func loadAd() {
        switch self.adResponse.creativeType {
        case "html":
            self._mraidView = SKMRAIDView(frame: self.frame,
                                          withHtmlData: self.adResponse.creative,
                                          withBaseURL: NSURL(string: "https://\(MAXAdRequest.ADS_DOMAIN)"),
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
    
    func click(url: NSURL) {
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
    
    public func mraidViewAdReady(mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewAdReady")
        parent.trackImpression()
        parent.delegate?.adViewDidLoad(parent)
    }
    public func mraidViewAdFailed(mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewAdFailed")
        parent.delegate?.adViewDidFailWithError(parent, error: nil)
    }
    public func mraidViewDidClose(mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewDidClose")
    }
    public func mraidViewWillExpand(mraidView: SKMRAIDView!) {
        NSLog("MAX: mraidViewWillExpand")
    }
    public func mraidViewNavigate(mraidView: SKMRAIDView!, withURL url: NSURL!) {
        NSLog("MAX: mraidViewNavigate \(url)")
        parent.click(url)
    }
    public func mraidViewShouldResize(mraidView: SKMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        NSLog("MAX: mraidViewShouldResize")
        return false
    }
    
    //
    //
    //
    
    public func mraidServiceOpenBrowserWithUrlString(url: String) {
        NSLog("MAX: mraidServiceOpenBrowserWithUrlString \(url)")
        if let url = NSURL(string: url) {
            parent.click(url)
        }
    }
    
}

