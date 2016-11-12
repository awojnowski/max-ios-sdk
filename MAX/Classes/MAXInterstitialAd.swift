//
//  MAXInterstitialAd.swift
//  Pods
//
//

import Foundation

public protocol MAXInterstitialAdDelegate {
    func interstitialAdDidClick(interstitialAd: MAXInterstitialAd)
    func interstitialAdWillClose(interstitialAd: MAXInterstitialAd)
    func interstitialAdDidClose(interstitialAd: MAXInterstitialAd)
}

public class MAXInterstitialAd {
    private var adResponse: MAXAdResponse!

    public var delegate: MAXInterstitialAdDelegate?
    
    private var _vastDelegate: VASTDelegate!
    private var _mraidDelegate: MRAIDDelegate!
    
    private var _vastViewController: SKVASTViewController?
    private var _mraidInterstitial: SKMRAIDInterstitial?
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        self._vastDelegate = VASTDelegate(parent: self)
        self._mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    public func showAdFromRootViewController(rootViewController: UIViewController) {
        switch self.adResponse.creativeType {
            case "vast3":
                if let videoData = self.adResponse.creative!.dataUsingEncoding(NSUTF8StringEncoding) {
                    self._vastViewController = SKVASTViewController(delegate: _vastDelegate,
                                                  withViewController: rootViewController)
                    self._vastViewController!.loadVideoWithData(videoData)
                }
            case "html":
                self._mraidInterstitial = SKMRAIDInterstitial(supportedFeatures:[],
                    withHtmlData: self.adResponse.creative!,
                    withBaseURL: NSURL(string: "https://sprl.com"),
                    delegate: _mraidDelegate,
                    serviceDelegate: _mraidDelegate,
                    rootViewController: rootViewController)
            case "native":
                break
            case "empty":
                NSLog("MAX: empty ad response, nothing to show")
                break
            default:
                NSLog("MAX: unsupported ad creative_type=\(self.adResponse.creativeType)")
                break
        }
    }
}

private class VASTDelegate : NSObject, SKVASTViewControllerDelegate {

    private var parent : MAXInterstitialAd
    
    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }
    
    //
    //
    //
    
    public func vastReady(vastVC: SKVASTViewController!) {
        vastVC.play()
    }
    
    public func vastTrackingEvent(eventName: String!) {
        NSLog("vastTrackingEvent(\(eventName)")
        if eventName == "close" {
            self.parent.delegate?.interstitialAdWillClose(self.parent)
        }
    }
    
    public func vastDidDismissFullScreen(vastVC: SKVASTViewController!) {
        self.parent.delegate?.interstitialAdDidClose(self.parent)
    }
    
    public func vastOpenBrowseWithUrl(vastVC: SKVASTViewController!, url: NSURL!) {
        self.parent.delegate?.interstitialAdDidClick(self.parent)
        vastVC.dismissViewControllerAnimated(false) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}

private class MRAIDDelegate : NSObject, SKMRAIDInterstitialDelegate, SKMRAIDServiceDelegate {
    private var parent : MAXInterstitialAd
    
    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }
    
    //
    //
    //
    
    public func mraidInterstitialAdReady(mraidInterstitial: SKMRAIDInterstitial!) {
        if mraidInterstitial.isAdReady() {
            mraidInterstitial.show()
        }
    }
    
    public func mraidInterstitialDidHide(mraidInterstitial: SKMRAIDInterstitial!) {
        NSLog("mraidInterstitialDidHide")
    }
    
    public func mraidInterstitialAdFailed(mraidInterstitial: SKMRAIDInterstitial!) {
        NSLog("mraidInterstitialAdFailed")
    }
    
    public func mraidInterstitialWillShow(mraidInterstitial: SKMRAIDInterstitial!) {
        NSLog("mraidInterstitialWillShow")
    }
    
    public func mraidInterstitialNavigate(mraidInterstitial: SKMRAIDInterstitial!, withURL url: NSURL!) {
        NSLog("mraidInterstitialNavigate")
    }
    
    //
    //
    //
    
    public func mraidServiceOpenBrowserWithUrlString(url: String) {
        NSLog("mraidServiceOpenBrowserWithUrlString")

    }

}
