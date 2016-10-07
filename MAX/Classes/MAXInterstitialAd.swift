//
//  MAXInterstitialAd.swift
//  Pods
//
//

import Foundation

public class MAXInterstitialAd : NSObject, SKVASTViewControllerDelegate {
    private var adResponse: MAXAdResponse!
    
    private var _videoData: NSData?
    
    public init(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
    }
    
    public func showAdFromRootViewController(rootViewController: UIViewController) {
        if let winner = self.adResponse.response["ad_source_response"] {
            if let creative_type = winner["creative_type"] as? String {
                switch creative_type {
                case "vast3":
                    self._videoData = (winner["creative"] as? String ?? "").dataUsingEncoding(NSUTF8StringEncoding)
                    if let _videoData = self._videoData {
                        let vc = SKVASTViewController(delegate: self, withViewController: rootViewController)
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
    
    //
    //
    //
    
    public func vastReady(vastVC: SKVASTViewController!) {
        vastVC.play()
    }
    
    public func vastTrackingEvent(eventName: String!) {
        NSLog("vastTrackingEvent(\(eventName)")
    }
    
    public func vastDidDismissFullScreen(vastVC: SKVASTViewController!) {
        
    }
    
    public func vastOpenBrowseWithUrl(vastVC: SKVASTViewController!, url: NSURL!) {
        vastVC.dismissViewControllerAnimated(false) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}
