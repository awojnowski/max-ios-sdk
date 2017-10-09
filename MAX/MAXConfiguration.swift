//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

let MAX_SDK_VERSION = "0.6.0"

public class MAXConfiguration {

    public static let shared = MAXConfiguration()
    private init() {}

    /*
     * SDK Version
     */

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
}
