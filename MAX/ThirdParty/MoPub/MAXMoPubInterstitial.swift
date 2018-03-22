//
//  MAXMoPubInterstitial.swift
//  MAX
//
//  Created by Bryan Boyko on 3/7/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import UIKit
import MoPub

public class MAXMoPubInterstitial: NSObject, MPInterstitialAdControllerDelegate, MAXInterstitialAdDelegate, MAXAdRequestManagerDelegate {
    
    @objc public weak var mpInterstitialDelegate: MPInterstitialAdControllerDelegate?
    @objc public weak var maxInterstitialDelegate: MAXInterstitialAdDelegate?
    
    private let maxAdUnitId: String
    private let mpInterstitial: MPInterstitialAdController
    private let maxInterstitial: MAXInterstitialAd
    private let sessionManager: MAXSessionManager
    private let rootViewController: UIViewController
    private var adResponse: MAXAdResponse?
    
    @objc public convenience init(maxAdUnitId: String, mpInterstitial: MPInterstitialAdController, rootViewController: UIViewController) {
        self.init(maxAdUnitId: maxAdUnitId, mpInterstitial: mpInterstitial, maxInterstitial: MAXInterstitialAd(), sessionManager: MAXSessionManager.shared, rootViewController: rootViewController)
    }
    
    internal init(maxAdUnitId: String, mpInterstitial: MPInterstitialAdController, maxInterstitial: MAXInterstitialAd, sessionManager: MAXSessionManager, rootViewController: UIViewController) {
        self.maxAdUnitId = maxAdUnitId
        self.mpInterstitial = mpInterstitial
        self.maxInterstitial = maxInterstitial
        self.sessionManager = sessionManager
        self.rootViewController = rootViewController
        super.init()
        self.mpInterstitial.delegate = self
        self.maxInterstitial.delegate = self
        self.maxInterstitial.hijackRequestManagerDelegate(maxRequestManagerDelegate: self)
    }
    
    // NOTE: Loading will not show an ad. show() function must be called separately after interstitialDidLoadAd() or interstitialAdDidLoad() callbacks occur. (For banners, calling load() will also show the banner)
    // Call on main thread
    @objc public func load() {
        
        guard maxAdUnitId != nil else {
            MAXLogger.error("\(String(describing: self)) load called with nil MAX ad unit id")
            return
        }
        
        maxInterstitial.load(adUnitId: maxAdUnitId)
    }
    
    // Call on main thread
    @objc public func show() {
        
        guard let adR = adResponse else {
            MAXLogger.debug("\(String(describing: self)): show() failed because an ad has not loaded yet -> either show() was called before load() call finished and interstitialDidLoadAd() callback fired, or load() returned a nil adResponse")
            return
        }
        
        doShow(adResponse: adR)
    }
    
    private func doShow(adResponse: MAXAdResponse) {
        self.mpInterstitial.keywords = adResponse.preBidKeywords
        
        if adResponse.isReserved {
            // An ad response has been 'reserved' for MAX, meaning that it will bypass the MoPub SSP waterfall and the ad response will be immediately rendered by MAX
            maxInterstitial.showAdFromRootViewController(rootViewController)
        } else {
            mpInterstitial.show(from: rootViewController)
        }
    }
    
    internal func loadResponse(adResponse: MAXAdResponse) {
        self.adResponse = adResponse
        
        if adResponse.isReserved {
            MAXLogger.debug("\(String(describing: self)): Ad is eligible for auction rounds, loading ad through MAX SDK")
            // Make call to bannerController in opposite direction of normal callbacks (up dependency chain) because this class hijacked maxInterstitial.requestManager callbacks
            maxInterstitial.onRequestSuccess(adResponse: adResponse)
        } else {
            MAXLogger.debug("\(String(describing: self)): Ad is not eligible for auction rounds, loading ad through MoPub SDK")
            // MAX passes control to MoPub and inserts MAX line items in MoPub waterfall.
            adResponse.trackHandoff()
            mpInterstitial.keywords = adResponse.preBidKeywords
            mpInterstitial.loadAd()
        }
    }
    
    internal func loadVanillaMoPub() {
        mpInterstitial.loadAd()
    }
    
    //MARK: MAXAdRequestManagerDelegate
    // NOTE This class will hijack the MAXAdRequestManagerDelegate of the MAXInterstitialAd instance it owns to intercept MAXInterstitialAd.requestManager callbacks.
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        MAXLogger.debug("\(String(describing: self)).requestAd() succeeded for adUnit:\(String(describing: adResponse?.adUnitId))")
        
        guard adResponse != nil else {
            MAXLogger.debug("\(String(describing: self)).requestAd() succeeded but the ad response was nil")
            return
        }
        
        DispatchQueue.main.async {
            self.loadResponse(adResponse: adResponse!)
        }
    }
    
    public func onRequestFailed(error: NSError?) {
        MAXLogger.debug("\(String(describing: self)).requestAd() failed with error: \(String(describing: error?.localizedDescription)). Will try to load an ad from the MoPub SDK.")
        
        DispatchQueue.main.async {
            // Fall back on MoPub if MAX ad request fails
            self.loadVanillaMoPub()
        }
    }

    
    //MARK: MPInterstitialAdControllerDelegate
    
    public func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidLoadAd?(interstitial)
        }
    }
    
    public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidFail?(toLoadAd: interstitial)
        }
    }
    
    public func interstitialWillAppear(_ interstitial: MPInterstitialAdController!) {

        // An interstitial will be shown because a MAX line item in the MoPub waterfall was selected
        sessionManager.incrementSSPSessionDepth(adUnitId: interstitial.adUnitId)
        
         if let d = mpInterstitialDelegate {
            d.interstitialWillAppear?(interstitial)
        }
    }
    
    public func interstitialDidAppear(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidAppear?(interstitial)
        }
    }
    
    public func interstitialWillDisappear(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialWillDisappear?(interstitial)
        }
    }
    
    public func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidDisappear?(interstitial)
        }
    }
    
    public func interstitialDidExpire(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidExpire?(interstitial)
        }
    }
    
    public func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
         if let d = mpInterstitialDelegate {
            d.interstitialDidReceiveTapEvent?(interstitial)
        }
    }
    
    
    //MARK: MAXInterstitialAdDelegate
    
    public func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd) {
        if let d = maxInterstitialDelegate {
            d.interstitialAdDidLoad(interstitialAd)
        }
    }
    
    public func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        if let d = maxInterstitialDelegate {
            d.interstitialAdDidClick(interstitialAd)
        }
    }
    
    public func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        if let d = maxInterstitialDelegate {
            d.interstitialAdWillClose(interstitialAd)
        }
    }
    
    public func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        if let d = maxInterstitialDelegate {
            d.interstitialAdDidClose(interstitialAd)
        }
    }
    
    public func interstitial(_ interstitialAd: MAXInterstitialAd?, didFailWithError error: MAXClientError) {
        MAXLogger.debug("\(String(describing: self)) MAXInterstitialAdDelegate failed to load ad with error: \(error.message)")
        if let d = maxInterstitialDelegate {
            d.interstitial(interstitialAd, didFailWithError: error)
        }
    }
    
    
    //MARK: Overrides
    
    public override var description: String {
        return "\(super.description)\nmaxAdUnitId: \(maxAdUnitId)\nmpInterstitial: \(String(describing:mpInterstitial))"
    }
}