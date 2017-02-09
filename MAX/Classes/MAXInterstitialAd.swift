//
//  MAXInterstitialAd.swift
//  Pods
//
//

import Foundation

public protocol MAXInterstitialAdDelegate {
    func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd)
    func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd)
}

open class MAXInterstitialAd {
    fileprivate var adResponse: MAXAdResponse!

    open var delegate: MAXInterstitialAdDelegate?
    var rootViewController : UIViewController?
    
    private var _vastDelegate: VASTDelegate!
    private var _vastViewController: SKVASTViewController?

    private var _mraidDelegate: MRAIDDelegate!
    private var _mraidInterstitial: SKMRAIDInterstitial?
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        self._vastDelegate = VASTDelegate(parent: self)
        self._mraidDelegate = MRAIDDelegate(parent: self)
    }
    
    open func showAdFromRootViewController(_ rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        switch self.adResponse.creativeType {
            case "vast3":
                if let videoData = self.adResponse.creative!.data(using: String.Encoding.utf8) {
                    self._vastViewController = SKVASTViewController(delegate: _vastDelegate,
                                                  with: rootViewController)
                    self._vastViewController!.loadVideo(with: videoData)
                }
            case "html":
                self._mraidInterstitial = SKMRAIDInterstitial(supportedFeatures:[],
                    withHtmlData: self.adResponse.creative!,
                    withBaseURL: URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)"),
                    delegate: _mraidDelegate,
                    serviceDelegate: _mraidDelegate,
                    rootViewController: rootViewController)
            case "native":
                break
            case "empty":
                MAXLog.debug("MAX: empty ad response, nothing to show")
                break
            default:
                MAXLog.error("MAX: unsupported ad creative_type=\(self.adResponse.creativeType)")
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

private class MRAIDDelegate : NSObject, SKMRAIDInterstitialDelegate, SKMRAIDServiceDelegate {
    private var parent : MAXInterstitialAd
    
    init(parent: MAXInterstitialAd) {
        self.parent = parent
    }
    
    //
    //
    //
    
    fileprivate func mraidInterstitialAdReady(_ mraidInterstitial: SKMRAIDInterstitial!) {
        if mraidInterstitial.isAdReady() {
            mraidInterstitial.show()
            self.parent.adResponse.trackImpression()
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
    }
    
    fileprivate func mraidInterstitialNavigate(_ mraidInterstitial: SKMRAIDInterstitial!, with url: URL!) {
        MAXLog.debug("MAX: mraidInterstitialNavigate")
    }
    
    //
    //
    //
    
    fileprivate func mraidServiceOpenBrowser(withUrlString url: String) {
        MAXLog.debug("MAX: mraidServiceOpenBrowserWithUrlString")
        MAXLinkHandler().openURL(parent.rootViewController!, url: URL(string: url)!, completion: nil)
    }

}
