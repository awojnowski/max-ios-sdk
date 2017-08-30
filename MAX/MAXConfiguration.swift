//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

class MAXConfiguration {

    static let shared = MAXConfiguration()
    private init() {}

    private var _locationTrackingEnabled: Bool = false

    var locationTrackingEnabled: Bool {
        get {
            return _locationTrackingEnabled
        }
    }

    public func enableLocationTracking() {
        self._locationTrackingEnabled = true
    }
}