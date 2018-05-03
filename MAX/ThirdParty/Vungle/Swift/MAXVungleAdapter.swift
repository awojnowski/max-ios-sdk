//
//  MAXVungleAdapter.swift
//  MAX
//
//  Created by Bryan Boyko on 3/23/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

// NOTE: VungleSDK must be imported via MAX-Bridging-Header.h because it is bundled as a framework (Open the VungleSDK pod to see its contents)
import Foundation

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
            "sdk_version" : MAXObjCVungleConfiguration.shared().vungleSDKVersion()]
            as [String : Any]
        return String.jsonToString(json: json)
    }
}


// NOTE: For ObjC rewrite, It will likely make sense to create a MAXConfguration+Vungle category to replace MAXConfiguration extension

extension MAXConfiguration: MAXObjCVungleConfigurationDelegate {

    // It sucks that placementIds needs to be static. Issue -> MAXConfiguration is an extenstion, which can't
    // hold state. Also, VungleSDK doesn't make the placementID's it's initialized with available
    // either from the shared SDK instance or in the vungleSDKDidInitialize
    // callback..
    // We could fix this by making MAXConfiguration subclasses for each direct SDK instead of making extensions. (Subclasses would all be injected with the same instance of MAXDirectSDKManager)
    private static var placementIds = [String]()

    @objc public func initializeVungleSDK(appId: String, placementIds: Array<String>, enableLogging: Bool) {

        MAXObjCVungleConfiguration.shared().delegate = self
        
        MAXObjCVungleConfiguration.shared().initializeVungleSDK(withAppId: appId, placementIds: placementIds, enabledLogging: enableLogging)

        self.registerInterstitialGenerator(MAXVungleInterstitialAdapterGenerator())
    }
    
    
    //MARK: MAXObjCVungleConfigurationDelegate
    
    @objc public func vungleError(_ error: Error!) {
        MAXLogger.error("\(String(describing: self)): \(String(describing: error))")
    }
}


