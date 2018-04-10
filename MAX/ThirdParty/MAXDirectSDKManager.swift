//
//  MAXDirectSDKManager.swift
//  MAX
//
//  Created by Bryan Boyko on 4/6/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

public class MAXDirectSDKManager: NSObject {
    
    // Note: This is hella hacky. The string associated with an SDK identifier must exactly match a .m implementaion file name from the corresponding SDK module (only hader files won't work because NSClassFromString returns nil)
    internal let possibleSDKs = [facebookIdentifier : "FBNativeAdView", vungleIdentifier : "VungleSDK"]
    // Indicates if an SDK has been integrated
    internal var integratedSDKs = [String : Bool]()
    @objc public let tokenRegistrar = MAXTokenRegistrar()
    
    internal override init() {
        super.init()
        assembleIntegratedSDKs()
    }
    
    private func assembleIntegratedSDKs() {
        for (sdkIdentifier, someSDKClassName) in possibleSDKs {
            integratedSDKs[sdkIdentifier] = NSClassFromString(someSDKClassName) != nil ? true : false
        }
    }
    
    // Checks to see if SDK's for direct buyers have been integrated but not initialized.
    // If one or more SDK's have been integrated and not initialized, an error will be returned indicating which SDK's have not been initialized
    @objc public func checkDirectIntegrationsInitialized() -> MAXClientError? {
        var sdksIntegratedAndNotInitialized = ""
        var error: MAXClientError? = nil
        for (sdkIdentifier, isIntegrated) in integratedSDKs {
            if isIntegrated && tokenRegistrar.tokens[sdkIdentifier] == nil {
                // Absence of token means SDK has not been initialized (tokens are registered on third party sdk initialization)
                sdksIntegratedAndNotInitialized += sdksIntegratedAndNotInitialized == "" ? sdkIdentifier : ", " + sdkIdentifier
            }
        }
        if sdksIntegratedAndNotInitialized != "" {
            error = MAXClientError(message: "The following SDK's are integrated but not initialized " + "<" + sdksIntegratedAndNotInitialized + ">" + " please see MAX integration docs for details on initializing direct buyer SDK's -> http://docs.maxads.io/documentation/ios/facebook/")
        }
        return error
    }
}
