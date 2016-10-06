//
//  MAXInterstitialAd.swift
//  Pods
//
//

import Foundation

public class MAXInterstitialAd : NSObject, SKVASTViewControllerDelegate {
    private var adResponse: MAXAdResponse!
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
    }
    
    func showAdFromRootViewController(rootViewController: UIViewController) {
        if let winner = self.adResponse.response["ad_source_response"] {
            switch winner["creative_type"] as! String {
            case "vast3":
                if let videoData = (winner["creative"] as! String).dataUsingEncoding(NSUTF8StringEncoding) {
                    SKLogger.setLogLevel(SourceKitLogLevelDebug)
                    let vc = SKVASTViewController(delegate: self, withViewController: rootViewController)
                    vc.loadVideoWithData(videoData)
                }
            case "empty":
                break
            default:
                break
            }
        }
    }
    
    //
    //
    //
    
    @objc public func vastReady(vastVC: SKVASTViewController!) {
        vastVC.play()
    }
    
    @objc public func vastTrackingEvent(eventName: String!) {
        NSLog("vastTrackingEvent(\(eventName)")
    }
    
    @objc public func vastDidDismissFullScreen(vastVC: SKVASTViewController!) {
        
    }
    
    @objc public func vastOpenBrowseWithUrl(vastVC: SKVASTViewController!, url: NSURL!) {
        vastVC.dismissViewControllerAnimated(false) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}