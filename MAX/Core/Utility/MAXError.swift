import Foundation
import AdSupport
import CoreTelephony
import UIKit

public class MAXClientError: NSError {
    
    @objc public private(set) var appId: NSNumber?
    @objc public private(set) var adUnitID: NSNumber?
    @objc public private(set) var adUnitType: String?
    @objc public private(set) var adSourceId: NSNumber?
    @objc public private(set) var createdAt: String
    @objc public private(set) var message: String

    private let MAXErrorDomain = "MAXErrorDomain"

    @objc public init(message: String) {
        self.message = message
        self.createdAt = Date().description
        // Use only error code 0 for now
        super.init(domain: MAXErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : message])
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public var ifa: String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }

    @objc public var lmt: Bool {
        return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? false : true
    }

    @objc public var vendorId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    @objc public var timeZone: String {
        return NSTimeZone.system.abbreviation() ?? ""
    }

    @objc public var locale: String {
        return Locale.current.identifier
    }

    @objc public var regionCode: String {
        return Locale.current.regionCode ?? ""
    }

    @objc public var orientation: String {
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            return "portrait"
        } else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            return "landscape"
        } else {
            return "none"
        }
    }

    @objc public var deviceWidth: CGFloat {
        return floor(UIScreen.main.bounds.size.width)
    }

    @objc public var deviceHeight: CGFloat {
        return floor(UIScreen.main.bounds.size.height)
    }

    @objc public var browserAgent: String {
        return MAXUserAgent.shared.value ?? ""
    }

    @objc public var connectivity: String {
        if MaxReachability.forInternetConnection().isReachableViaWiFi() {
            return "wifi"
        } else if MaxReachability.forInternetConnection().isReachableViaWWAN() {
            return "wwan"
        } else {
            return "none"
        }
    }

    @objc public var carrier: String {
        return CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""
    }

    @objc public var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    @objc public var data: Dictionary<String, Any> {
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

    @objc public var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self.data, options: [])
    }

    @objc public func asNSError() -> NSError {
        let userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
        let errorTemp = NSError(domain: MAXErrorDomain, code:0, userInfo:userInfo)
        return errorTemp
    }
}
