import Foundation
import UIKit

let maxSDKVersion = "0.9.0"

public class MAXConfiguration: NSObject {

    @objc public static let shared = MAXConfiguration()
    
    private override init() {
        MAXLogger.info("You are using MAX iOS SDK version \(maxSDKVersion)")
    }

    /// Get the current version of the SDK. This is reported in ad requests.
    @objc public func getSDKVersion() -> String {
        return maxSDKVersion
    }

    /*
     * Location Tracking
     *
     * Location tracking is disabled by default. Enable location tracking by
     * calling `MAXConfiguration.shared.enableLocationTracking()`.
     */

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

    /*
     * Third party hooks
     */
    @objc public var tokenRegistrar = MAXTokenRegistrar()

    private var partnerAdViewGenerators: Dictionary<String, MAXAdViewAdapterGenerator> = [:]
    
    @objc public func registerAdViewGenerator(_ generator: MAXAdViewAdapterGenerator) {
        self.partnerAdViewGenerators[generator.identifier] = generator
    }

    @objc public func getAdViewGenerator(forPartner: String) -> MAXAdViewAdapterGenerator? {
        return self.partnerAdViewGenerators[forPartner]
    }

    private var partnerInterstitialGenerators: Dictionary<String, MAXInterstitialAdapterGenerator> = [:]
    public func registerInterstitialGenerator(_ generator: MAXInterstitialAdapterGenerator) {
        self.partnerInterstitialGenerators[generator.identifier] = generator
    }

    @objc public func getInterstitialGenerator(forPartner: String) -> MAXInterstitialAdapterGenerator? {
        return self.partnerInterstitialGenerators[forPartner]
    }
}
