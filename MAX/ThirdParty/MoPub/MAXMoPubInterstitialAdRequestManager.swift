//
//  MAXMoPubInterstitialAdRequestManager.swift
//  MAX
//
//  Created by Bryan Boyko on 3/5/18.
//

import Foundation
import MoPub

public class MAXMoPubInterstitialAdRequestManager: MAXAdRequestManager, MPInterstitialAdControllerDelegate {
   
    private let mpIntersititalAdController: MPInterstitialAdController
    private weak var interstitialProxyDelegate: MPInterstitialAdControllerDelegate!
    
    private var maxInterstitial: MAXInterstitialAd?
    
    public init(adUnitID: String, mpInterstitialAdController: MPInterstitialAdController, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self.mpIntersititalAdController = mpInterstitialAdController
        super.init(adUnitID: adUnitID, completion: completion)
        self.interstitialProxyDelegate = self.mpIntersititalAdController.delegate
        self.mpIntersititalAdController.delegate = self
    }
    
    public func loadAd() {
        MAXLog.debug("\(String(describing: self)) loadAd() called")
        _ = self.requestAd { (response, error) in
            MAXLog.debug("\(String(describing: self)).requestAd() returned with error: \(String(describing: error))")
            self.lastResponse = response
            self.lastError = error
            self.completion(response, error)
            
            // This needs to be called from the main thread, or could crash the app,
            // since third party SDKs don't explicitly prevent certain main-thread-only
            // subprocesses (e.g. UIKit/UIApplication calls) from happening on background
            // threads.
            DispatchQueue.main.sync {
                if let r = response {
                    self.mpIntersititalAdController.keywords = r.preBidKeywords
                    
                    if r.isReserved {
                        // An ad response has been 'reserved' for MAX, meaning that it will MoPub SSP waterfall will be bypassed and the ad response will be immediately rendered by MAX
                        self.maxInterstitial = MAXInterstitialAd(adResponse: r)
                        
                        
                        //  TODO - Bryan: MME-105 ==========================================
                        
                        
                        // TODO - Bryan?: check to see if interstitial is MRAID or VAST. Create factory to handle different cases
                        self.maxInterstitial?.loadAdWithMRAIDRenderer()
                    } else {
                        // MAX passes control to MoPub and inserts MAX line items in MoPub waterfall.
                        response?.trackHandoff()
                        self.mpIntersititalAdController.loadAd()
                    }
                }
            }
        }
    }
    
    
    //MARK: MPInterstitialAdControllerDelegate
    
    public func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidLoadAd")
        self.interstitialProxyDelegate.interstitialDidLoadAd?(interstitial)
    }
    
    public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidFail")
        self.interstitialProxyDelegate.interstitialDidFail?(toLoadAd: interstitial)
    }
    
    public func interstitialWillAppear(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialWillAppear")
        self.interstitialProxyDelegate.interstitialWillAppear?(interstitial)
        
        // An interstitial will be shown because a MAX line item in the MoPub waterfall was selected
        MAXSessionManager.shared.session.incrementSSPSessionDepth(adUnitId: (interstitial.adUnitId)!)
    }
    
    public func interstitialDidAppear(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidAppear")
        self.interstitialProxyDelegate.interstitialDidAppear?(interstitial)
    }
    
    public func interstitialWillDisappear(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialWillDisappear")
        self.interstitialProxyDelegate.interstitialWillDisappear?(interstitial)
    }
    
    public func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidDisappear")
        self.interstitialProxyDelegate.interstitialDidDisappear?(interstitial)
    }
    
    public func interstitialDidExpire(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidExpire")
        self.interstitialProxyDelegate.interstitialDidExpire?(interstitial)
    }
    
    public func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
        print("\(String(describing: self)): MPInterstitialAdControllerDelegate - interstitialDidReceiveTapEvent")
        self.interstitialProxyDelegate.interstitialDidReceiveTapEvent?(interstitial)
    }
    
    
    //TODO - Bryan: Add MAXInterstitialAdDelegate
}
