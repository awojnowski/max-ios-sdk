import Foundation
import UIKit
import VungleSDK
import VungleSDKHeaderBidding

let maxSDKVersion = "1.0.0"


// configuration relating to the below third parties is implemented in MAXConfiguration extensions in the corresponding third party adapter classes
internal let facebookIdentifier = "facebook"
internal let vungleIdentifier = "vungle"

public class MAXConfiguration: NSObject {

    @objc public static let shared = MAXConfiguration(directSDKManager: MAXDirectSDKManager())
    @objc public let directSDKManager: MAXDirectSDKManager
    
    private init(directSDKManager: MAXDirectSDKManager) {
        self.directSDKManager = directSDKManager
        MAXLogger.info("You are using MAX iOS SDK version \(maxSDKVersion)")
        super.init()
    }

    /// Get the current version of the SDK. This is reported in ad requests.
    @objc public func getSDKVersion() -> String {
        return maxSDKVersion
    }
    
    //MARK: Location tracking
    // Location tracking is disabled by default. Enable location tracking by
    // calling `MAXConfiguration.shared.enableLocationTracking()`.

    private var _locationTrackingEnabled: Bool = false

    @objc public var locationTrackingEnabled: Bool {
        return _locationTrackingEnabled
    }

    @objc public func enableLocationTracking() {
        self._locationTrackingEnabled = true
    }

   @objc public func disableLocationTracking() {
        self._locationTrackingEnabled = false
    }

    
    //MARK: Third party hooks

    private var partnerAdViewGenerators: Dictionary<String, MAXAdViewAdapterGenerator> = [:]
    
    @objc public func registerAdViewGenerator(_ generator: MAXAdViewAdapterGenerator) {
        self.partnerAdViewGenerators[generator.identifier] = generator
    }

    @objc public func getAdViewGenerator(forPartner: String) -> MAXAdViewAdapterGenerator? {
        return self.partnerAdViewGenerators[forPartner]
    }

    private var partnerInterstitialGenerators: Dictionary<String, MAXInterstitialAdapterGenerator> = [:]
    @objc public func registerInterstitialGenerator(_ generator: MAXInterstitialAdapterGenerator) {
        self.partnerInterstitialGenerators[generator.identifier] = generator
    }

    @objc public func getInterstitialGenerator(forPartner: String) -> MAXInterstitialAdapterGenerator? {
        return self.partnerInterstitialGenerators[forPartner]
    }
}
