//
//  MAXVungleAdapter.swift
//  MAX
//
//  Created by Bryan Boyko on 3/23/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

// NOTE: VungleSDK must be imported via MAX-Bridging-Header.h because it is bundled as a framework (Open the VungleSDK pod to see its contents)
import VungleSDK
import VungleSDKHeaderBidding

internal class MAXVungleTokenProvider: MAXTokenProvider {
    
    internal let placementIds: [String]
    internal let bidToken: String
    
    
    internal init(placementIds: [String], bidToken: String) {
        self.placementIds = placementIds
        self.bidToken = bidToken
    }
    
    
    //MARK: MAXTokenProvider protocol
    
    @objc public let identifier: String = vungleIdentifier
    
    @objc public func generateToken() -> String {
        let json = [
            "placement_ids" : placementIds,
            "bid_token" : bidToken,
            "sdk_version" : VungleSDKVersion]
            as [String : Any]
        return String.jsonToString(json: json)
    }
}



extension MAXConfiguration: VungleSDKHeaderBidding, VungleSDKDelegate {
    
    // It sucks that placementIds needs to be static. Issue -> MAXConfiguration is an extenstion, which can't
    // hold state. Also, VungleSDK doesn't make the placementID's it's initialized with available
    // either from the shared SDK instance or in the vungleSDKDidInitialize
    // callback..
    // We could fix this by making MAXConfiguration subclasses for each direct SDK instead of making extensions. (Subclasses would all be injected with the same instance of MAXDirectSDKManager)
    private static var placementIds = [String]()
    
    @objc public func initializeVungleSDK(appId: String, placementIds: Array<String>, enableLogging: Bool) {
        
        MAXLogger.debug("\(String(describing: self)): Initializing Vungle integration")
        
        MAXConfiguration.placementIds = placementIds

        let sdk = VungleSDK.shared()
        sdk.setLoggingEnabled(enableLogging)
        // Note that as soon as an interstitial is requested, the VungleSDK delegate will be tranferred to an instance of MAXVungleInterstitialAdapter. We do this since both SDK initialization and interstitial related callbacks are combined in the VungleSDKDelegate protocol
        sdk.delegate = self
        sdk.headerBiddingDelegate = self
        sdk.setLoggingEnabled(true)
        
        do {
            try sdk.start(withAppId: appId, placements: placementIds)
        }
        catch let error as NSError {
            MAXLogger.error("Error while starting VungleSDK - domain: <\(error.domain)> description: <\(error.localizedDescription)>")
            return;
        }
        
        self.registerInterstitialGenerator(MAXVungleInterstitialAdapterGenerator())
    }
    
    
    //MARK: Vungle SDK Delegate
    
    // Once the SDK finishes caching an ad for a placement, the following callback method is called:
    public func vungleAdPlayabilityUpdate(_ isAdPlayable: Bool, placementID: String?, error: Error?) {
        
        MAXLogger.debug("\(String(describing: self)): VungleSDKDelegate - vungleAdPlayabilityUpdate for placementId: <\(String(describing: placementID))> is playable: \(String(describing: isAdPlayable))")
        
        guard error == nil else {
            MAXLogger.error("\(String(describing: self)): vungle ad playability error - \(String(describing: error))")
            return
        }
    }
    
    public func vungleSDKDidInitialize() {
        MAXLogger.debug("\(String(describing: self)): VungleSDKDelegate - vungleSDKDidInitialize")
        
        let sdk = VungleSDK.shared()
        for placementId in MAXConfiguration.placementIds {
            do {
                // NOTE: loadPlacement must be called after vungleSDKDidInitialize callback
                // NOTE: loadPlacement method does not need to be called to play an ad that is auto cached when VungleSDK is initialized. It does need to be called for VungleSDKHeaderBidding. If 'loadPlacement' isn't callend, the 'placementPrepared' VungleSDKHeaderBidding delegate callback will not happen.
                try sdk.loadPlacement(withID: placementId)
            }
            catch let error as NSError {
                MAXLogger.error("Error while starting VungleSDK - domain: <\(error.domain)> description: <\(error.localizedDescription)>")
                return;
            }
        }
    }
    
    public func vungleSDKFailedToInitializeWithError(_ error: Error) {
        MAXLogger.error("\(String(describing: self)): vungleSDKFailedToInitializeWithError - \(String(describing: error.localizedDescription))")
    }
    
    
    //MARK: VungleSDKHeaderBidding delegate
    
    // NOTE: Vungle will not be able to bid on ad requests until this callback occurs
    public func placementPrepared(_ placement: String, withBidToken bidToken: String) {
        MAXLogger.debug("\(String(describing: self)): Vungle SDK prepared a placement <\(String(describing: placement))> with bid token <\(String(describing: bidToken))>")
        self.directSDKManager.tokenRegistrar.registerTokenProvider(MAXVungleTokenProvider(placementIds: [placement], bidToken: bidToken))
    }
}


