//
//  MAXAdRequest.swift
//  Pods
//
//

import Foundation
import AdSupport
import CoreTelephony
import UIKit
import CoreLocation
import SKFramework

public typealias MAXResponseCompletion = (MAXAdResponse?, NSError?) -> Void

public class MAXAdRequest {
    public static let ADS_DOMAIN = "ads.maxads.io"
    public static let API_VERSION = "1"

    public var adUnitID: String!
    public var adResponse: MAXAdResponse?
    public var adError: NSError?

    public init(adUnitID: String) {
        self.adUnitID = adUnitID
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

    var latitude: String {
        get {
            guard CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways else {
                return ""
            }

            if let location = CLLocationManager().location {
                return String(location.coordinate.latitude)
            }

            return ""
        }
    }

    var longitude: String {
        get {
            guard CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                          CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways else {
                return ""
            }

            if let location = CLLocationManager().location {
                return String(location.coordinate.longitude)
            }

            return ""
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

    // All interesting things about this particular device
    var dict: Dictionary<String, Any> {
        get {
            return [
                "v": MAXAdRequest.API_VERSION,
                "ifa": self.ifa,
                "lmt": self.lmt,
                "vendor_id": self.vendorId,
                "tz": self.timeZone,
                "locale": self.locale,
                "orientation": self.orientation,
                "w": self.deviceWidth,
                "h": self.deviceHeight,
                "browser_agent": self.browserAgent,
                "model": self.model,
                "connectivity": self.connectivity,
                "carrier": self.carrier,
                "latitude": self.latitude,
                "longitude": self.longitude,
                "session_depth": MAXSession.sharedInstance.sessionDepth
            ]
        }
    }

    var asJSONObject: Data? {
        get {
            let data = try? JSONSerialization.data(withJSONObject: self.dict, options: [])
            return data
        }
    }

    func getSession() -> URLSession {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        return session
    }


    //
    // Conducts a pre-bid for a given MAX AdUnit. When the pre-bid has completed,
    // the callback function provided is invoked and the pre-bid ad response is made available
    // through that callback. Timeouts and other errors are also returned through the callback.
    //
    public class func preBidWithMAXAdUnit(_ adUnitID: String, completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        let adr = MAXAdRequest(adUnitID: adUnitID)
        adr.requestAd() {(response, error) in
            MAXPreBid.receivedPreBid(adUnitID: adUnitID, response: response, error: error)
            completion(response, error)
        }
        return adr
    }

    // 
    // Begin the ad flow by calling requestAd(), which conducts various server side 
    // auctions and other ad logic to determine the ad plan. 
    // 
    // The delegate is called with the ad plan when it is ready, after which point, the
    // plan can be executed whenever an ad needs to be shown. Once the ad is shown, 
    // the ad request should be discarded. 
    //
    public func requestAd(_ completion: @escaping MAXResponseCompletion) {
        // Setup POST
        let url = URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)/ads/req/\(self.adUnitID!)")!
        let session = getSession()
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"

        do {
            session.uploadTask(with: request as URLRequest, from: self.asJSONObject, completionHandler: { (_data, _response, _error) in
                do {
                    guard let data = _data,
                        let response = _response as? HTTPURLResponse,
                        _error == nil else {
                        throw _error!
                    }
                    
                    if response.statusCode == 200 {
                        self.adResponse = try MAXAdResponse(data: data)
                        completion(self.adResponse, nil)
                    } else if response.statusCode == 204 {
                        self.adResponse = MAXAdResponse()
                        completion(self.adResponse, nil)
                    } else {
                        throw NSError(domain: MAXAdRequest.ADS_DOMAIN,
                            code: response.statusCode,
                            userInfo: nil)
                    }
                } catch let error as NSError {
                    self.adError = error
                    completion(nil, error)
                }
            }).resume()
            
        } catch let error as NSError {
            self.adError = error
            completion(nil, error)
        }
    }
}
