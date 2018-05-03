//
//  MAXVungleInterstitialAdapter.swift
//  MAX
//
//  Created by Bryan Boyko on 3/23/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

// NOTE: Vungle is imported via MAX-Bridging-Header.h
import Foundation

internal class MAXVungleInterstitialAdapter: MAXInterstitialAdapter, MAXObjCVungleInterstitialAdapterDelegate {

    let objcVungleInterstitialAdapter: MAXObjCVungleInterstitialAdapter
    
    internal init(placementId: String) {
        objcVungleInterstitialAdapter = MAXObjCVungleInterstitialAdapter(placementId: placementId)
        super.init()
        objcVungleInterstitialAdapter.delegate = self
    }
    
    override internal func loadAd() {
        objcVungleInterstitialAdapter.loadAd()
    }
    
    override internal func showAd(fromRootViewController rvc: UIViewController?) {
        objcVungleInterstitialAdapter.showAd(fromRootViewController: rvc)
    }
    
    
    //MARK: MAXObjCVungleInterstitialAdapterDelegate
    // Since MAXObjCVungleInterstitialAdapter cannot subclass MAXInterstitialAdapter because it is a swift class, leave MAXVungleInterstitialAdapter as a passthrough from MAXObjCVungleInterstitialAdapter to Swift code
    
    func interstitialDidLoad(_ interstitialAdapter: MAXObjCVungleInterstitialAdapter!) {
        if let d = delegate {
            d.interstitialDidLoad(self)
        }
    }
    
    func interstitialWillLogImpression(_ interstitialAdapter: MAXObjCVungleInterstitialAdapter!) {
        if let d = delegate {
            d.interstitialWillLogImpression(self)
        }
    }
    
    func interstitialDidClose(_ interstitialAdapter: MAXObjCVungleInterstitialAdapter!) {
        if let d = delegate {
            d.interstitialDidClose(self)
        }
    }
    
    func vungleError(_ errorMessage: String!) {
        MAXLogger.error(errorMessage!)
        if let d = delegate {
            let error = MAXClientError(message: errorMessage!)
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
