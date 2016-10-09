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
    private var _videoData: NSData?
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        self._vastDelegate = VASTDelegate(parent: self)
    }
    
    public func showAdFromRootViewController(rootViewController: UIViewController) {
        if let winner = self.adResponse.response["ad_source_response"] {
            if let creative_type = winner["creative_type"] as? String {
                switch creative_type {
                case "vast3":
                    self._videoData = (winner["creative"] as? String ?? "").dataUsingEncoding(NSUTF8StringEncoding)
                    if let _videoData = self._videoData {
                        let vc = SKVASTViewController(delegate: _vastDelegate,
                                                      withViewController: rootViewController)
                        vc.loadVideoWithData(_videoData)
                    }
                case "html":
                    break
                case "native":
                    break
                case "empty":
                    NSLog("MAX: empty ad response, nothing to show")
                    break
                default:
                    NSLog("MAX: unsupported ad creative_type=\(creative_type)")
                    break
                }
            }
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
