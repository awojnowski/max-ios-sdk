import Foundation
import UIKit

let MAX_SDK_VERSION = "0.8.1"

public class MAXConfiguration {

    public static let shared = MAXConfiguration()
    private init() {}

    /// Get the current version of the SDK. This is reported in ad requests.
    public func getSDKVersion() -> String {
        return MAX_SDK_VERSION
    }

    /*
     * Location Tracking
     *
     * Location tracking is disabled by default. Enable location tracking by
     * calling `MAXConfiguration.shared.enableLocationTracking()`.
     */

    private var _locationTrackingEnabled: Bool = false

    var locationTrackingEnabled: Bool {
        get {
            return _locationTrackingEnabled
        }
    }

    public func enableLocationTracking() {
        self._locationTrackingEnabled = true
    }

    public func disableLocationTracking() {
        self._locationTrackingEnabled = false
    }

    /*
     * Debug mode
     *
     * Enabling debug mode
     */
    private var _debugMode: Bool = false

    var debugModeEnabled: Bool {
        get {
            return _debugMode
        }
    }

    public func enableDebugMode() {
        self._debugMode = true
    }

    public func disableDebugMode() {
        self._debugMode = false
    }

    /*
     * Third party hooks
     */
    public var tokenRegistrar = MAXTokenRegistrar()
    
    private var partnerAdViewGenerators: Dictionary<String, MAXAdViewAdapterGenerator> = [:]
    public func registerAdViewGenerator(_ generator: MAXAdViewAdapterGenerator) {
        self.partnerAdViewGenerators[generator.identifier] = generator
    }
    
    public func getAdViewGenerator(forPartner: String) -> MAXAdViewAdapterGenerator? {
        return self.partnerAdViewGenerators[forPartner]
    }
    
    private var partnerInterstitialGenerators: Dictionary<String, MAXInterstitialAdapterGenerator> = [:]
    public func registerInterstitialGenerator(_ generator: MAXInterstitialAdapterGenerator) {
        self.partnerInterstitialGenerators[generator.identifier] = generator
    }
    
    public func getInterstitialGenerator(forPartner: String) -> MAXInterstitialAdapterGenerator? {
        return self.partnerInterstitialGenerators[forPartner]
    }
}
