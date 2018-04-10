//
//  MAXVungleInterstitialAdapter.swift
//  MAX
//
//  Created by Bryan Boyko on 3/23/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

// NOTE: Vungle is imported via MAX-Bridging-Header.h
import VungleSDK

internal class MAXVungleInterstitialAdapter: MAXInterstitialAdapter, VungleSDKDelegate {
    
    let vungleSDK = VungleSDK.shared()
    let placementId: String
    
    internal init(placementId: String) {
        self.placementId = placementId
        super.init()
    }
    
    override internal func loadAd() {
        
        guard vungleSDK.isInitialized else {
            reportError(message: "\(String(describing: self)): cannot load an ad because the Vungle SDK hasn't been initialized yet. MAXCongfiguration.initializeVungleSDK() must be called first.")
            return
        }
        
        guard vungleSDK.isAdCached(forPlacementID: placementId) == false else {
            MAXLogger.debug("\(String(describing: self)): attempted to load an ad for placement id <\(String(describing: placementId))>, which Vungle has already loaded into its cache")
            if let d = delegate {
                d.interstitialDidLoad(self)
            }
            return
        }
        
        // Only set this instance as a delegate of the vungle sdk when load is called. For initialization, the vungle delegate will be set to another class
        vungleSDK.delegate = self
        
        do {
            try vungleSDK.loadPlacement(withID: placementId)
        }
        catch let error as NSError {
            reportError(message: "\(String(describing: self)): Unable to load placement with reference ID :\(placementId), Error: \(error)")
            return
        }
    }
    
    override internal func showAd(fromRootViewController rvc: UIViewController?) {
        
        guard vungleSDK.isInitialized else {
            reportError(message: "\(String(describing: self)): cannot show an ad because the Vungle SDK hasn't been initialized yet. MAXCongfiguration.initializeVungleSDK() must be called first.")
            return
        }
        
        guard let viewController = rvc else {
            reportError(message: "\(String(describing: self)): cannot show an ad on a nil view controller.")
            return
        }
        
        do {
            try vungleSDK.playAd(viewController, options: nil, placementID: placementId)
        }
        catch let error as NSError {
            reportError(message: "\(String(describing: self)): Error encountered playing ad: + \(error)")
        }
    }
    
    //MARK: Vungle SDK Delegate
    
    // Once the SDK finishes caching an ad for a placement, the following callback method is called:
    func vungleAdPlayabilityUpdate(_ isAdPlayable: Bool, placementID: String?, error: Error?) {
        MAXLogger.debug("\(String(describing: self)): VungleSDKDelegate - vungleAdPlayabilityUpdate for placementId: <\(String(describing: placementID))>")
        
        guard placementId == placementID else {
            reportError(message: "\(String(describing: self)): registered an attempt by Vungle to load an ad with a placement id <\(String(describing: placementID))> different than its own placement id <\(String(describing: placementId))>")
            return
        }
        
        guard error == nil else {
            reportError(message: "\(String(describing: self)): vungle ad playability error - \(String(describing: error))")
            return
        }
        
        if let d = delegate {
            d.interstitialDidLoad(self)
        }
    }
    
    func vungleWillShowAd(forPlacementID placementID: String?) {
        
        guard placementId == placementID else {
            reportError(message: "\(String(describing: self)):registered an attempt by Vungle to show ad with a placement id <\(String(describing: placementID))> different than its own placement id <\(String(describing: placementId))>")
            return
        }
        
        if let d = delegate {
            d.interstitialWillLogImpression(self)
        }
    }
    
    func vungleWillCloseAd(with info: VungleViewInfo, placementID: String) {
        
        guard placementId == placementID else {
            reportError(message: "\(String(describing: self)): registered an attempt by Vungle to close an ad with a placement id <\(String(describing: placementID))> different than its own placement id <\(String(describing: placementId))>")
            return
        }
        
        if let d = delegate {
            d.interstitialDidClose(self)
        }
    }
    
    
    //MARK: Errors
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        if let d = delegate {
            let error = MAXClientError(message: message)
            d.interstitial(self, didFailWithError: error)
        }
    }
}

internal class MAXVungleInterstitialAdapterGenerator: MAXInterstitialAdapterGenerator {
    
    internal var identifier: String = vungleIdentifier
    
    internal func getInterstitialAdapter(fromResponse: MAXAdResponse) -> MAXInterstitialAdapter? {
        
        guard let placementID = fromResponse.partnerPlacementID else {
            MAXLogger.warn("\(String(describing: self)): Tried to load an interstitial ad for Vungle but couldn't find placement ID in the response")
            return nil
        }
        
        // NOTE: MAX does not need to supply a bid payload creative to Vungle. Vungle SDK will fetch and cache its own creatives. These creatives can then be retrived from the Vungle SDK by their placemnet id's.
        
        let adaptedInterstitial = MAXVungleInterstitialAdapter(placementId: placementID)
        return adaptedInterstitial
    }
}
