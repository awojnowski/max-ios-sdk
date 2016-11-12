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
    
    private var creative: String = ""
    private var creative_type: String = "empty"
    
    private var _mraidDelegate: MRAIDDelegate!
    private var _mraidView: SKMRAIDView!
    
    public init(adResponse: MAXAdResponse,
                size: CGSize) {
        super.init(frame: CGRect(origin: CGPointZero, size: size))
        SKLogger.setLogLevel(SourceKitLogLevelDebug)
        
        self.adResponse = adResponse
        if let winner = self.adResponse.response["ad_source_response"] {
            self.creative = winner["creative"] as! String
            self.creative_type = winner["creative_type"] as! String
        }
        
        self._mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func loadAd() {
        switch creative_type {
        case "html":
            self._mraidView = SKMRAIDView(frame: self.frame,
                                          withHtmlData: self.creative,
                                          withBaseURL: NSURL(string: "https://sprl.com"),
                                          supportedFeatures: [],
                                          delegate: self._mraidDelegate,
                                          serviceDelegate: self._mraidDelegate,
                                          rootViewController: self.delegate?.viewControllerForPresentingModalView)
            self.delegate?.adViewWillLogImpression(self)
            self.addSubview(self._mraidView)
        case "empty":
            NSLog("MAX: empty ad response, nothing to show")
            break
        default:
            NSLog("MAX: unsupported ad creative_type=\(creative_type)")
            break
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
        NSLog("mraidViewAdReady")
        parent.delegate?.adViewDidLoad(parent)
    }
    public func mraidViewAdFailed(mraidView: SKMRAIDView!) {
        NSLog("mraidViewAdFailed")
        parent.delegate?.adViewDidFailWithError(parent, error: nil)
    }
    public func mraidViewDidClose(mraidView: SKMRAIDView!) {
        NSLog("mraidViewDidClose")
    }
    public func mraidViewWillExpand(mraidView: SKMRAIDView!) {
        NSLog("mraidViewWillExpand")
    }
    public func mraidViewNavigate(mraidView: SKMRAIDView!, withURL url: NSURL!) {
        NSLog("mraidViewNavigate")
    }
    public func mraidViewShouldResize(mraidView: SKMRAIDView!, toPosition position: CGRect, allowOffscreen: Bool) -> Bool {
        NSLog("mraidViewShouldResize")
        return false
    }
    
    //
    //
    //
    
    public func mraidServiceOpenBrowserWithUrlString(url: String) {
        NSLog("mraidServiceOpenBrowserWithUrlString")
        parent.delegate?.adViewDidClick(parent)
        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
        parent.delegate?.adViewDidFinishHandlingClick(parent)
    }
    
}
