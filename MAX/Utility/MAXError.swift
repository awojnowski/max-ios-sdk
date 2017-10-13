//
// Created by John Pena on 8/25/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import AdSupport
import CoreTelephony
import UIKit
import MRAID

class MAXClientError {
    var appId: Int64?
    var adUnitID: Int64?
    var adUnitType: String?
    var adSourceId: Int64?
    var createdAt: String
    var message: String

    init(message: String) {
        self.message = message
        self.createdAt = Date().description
    }

    var ifa: String {
        get {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
    }

    var lmt: Bool {
        get {
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? false : true
        }
    }

    var vendorId: String {
        get {
            return UIDevice.current.identifierForVendor?.uuidString ?? ""
        }
    }

    var timeZone: String {
        get {
            return NSTimeZone.system.abbreviation() ?? ""
        }
    }

    var locale: String {
        get {
            return Locale.current.identifier
        }
    }

    var regionCode: String {
        get {
            return Locale.current.regionCode ?? ""
        }
    }

    var orientation: String {
        get {
            if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
                return "portrait"
            } else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
                return "landscape"
            } else {
                return "none"
            }
        }
    }

    var deviceWidth: CGFloat {
        get {
            return floor(UIScreen.main.bounds.size.width)
        }
    }

    var deviceHeight: CGFloat {
        get {
            return floor(UIScreen.main.bounds.size.height)
        }
    }

    var browserAgent: String {
        get {
            return UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? ""
        }
    }

    var connectivity: String {
        get {
            if SKReachability.forInternetConnection().isReachableViaWiFi() {
                return "wifi"
            } else if SKReachability.forInternetConnection().isReachableViaWWAN() {
                return "wwan"
            } else {
                return "none"
            }
        }
    }

    var carrier: String {
        get {
            return CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""
        }
    }

    var model: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        }
    }

    var data: Dictionary<String, Any> {
        return [
            "message": self.message,
            "lmt": self.lmt,
            "ifa": self.ifa,
            "vendor_id": self.vendorId,
            "tz": self.timeZone,
            "locale": self.locale,
            "orientation": self.orientation,
            "w": self.deviceWidth,
            "h": self.deviceHeight,
            "browser_agent": self.browserAgent,
            "connectivity": self.connectivity,
            "carrier": self.carrier,
            "model": self.model
        ]
    }

    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self.data, options: [])
    }
}
