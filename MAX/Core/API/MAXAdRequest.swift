import Foundation
import AdSupport
import CoreTelephony
import UIKit
import CoreLocation

/// `MAXAdRequest`s will call a callback upon ad request completion. The callback function will be passed the
/// result of the ad request, either a response of type MAXAdResponse, or an error of type NSError. Both are
/// optionals, but only one will be defined, the response xor the error.
public typealias MAXResponseCompletion = (MAXAdResponse?, NSError?) -> Void

/// `MAXAdRequest.requestAd` will pass an error to the completion function in
public enum MAXRequestError: Error {
    case invalidResponse(response: URLResponse?, data: Data?)
    case requestFailed(domain: String, statusCode: Int, userInfo: Data?)
}

/// Core API type that packages all of the parameters needed to request a MAX bid.
/// Contains utility functions for making requests to the MAX ad server.
public class MAXAdRequest: NSObject {

    /// MAX's ad server domain, ads.maxads.io
    @objc public static let adsDomain = "ads.maxads.io"

    /// The current version of the MAX API
    @objc public static let apiVersion = "1"

    /// The MAX ad unit ID. This string can be found in the MAX UI.
    @objc public var adUnitID: String!

    /// If `MAXAdRequest.requestAd` completes successfully, `adResponse` will be defined as the response value
    @objc public var adResponse: MAXAdResponse?

    /// If `MAXAdRequest.requestAd` completes with an error, `adError` will be defined as the error returned.
    @objc public var adError: NSError?

    /// - Parameter adUnitID: the MAX ad unit ID. This string can be found in the MAX UI.
    @objc public init(adUnitID: String) {
        self.adUnitID = adUnitID
    }

    @objc public var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return unknownAppVersionIdentifier
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
            return MAXDeviceOrientation.Portrait
        } else if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            return MAXDeviceOrientation.Landscape
        } else {
            return MAXDeviceOrientation.None
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
            return MAXConnectivity.Wifi
        } else if MaxReachability.forInternetConnection().isReachableViaWWAN() {
            return MAXConnectivity.Wwan
        } else {
            return MAXConnectivity.None
        }
    }

    @objc public var carrier: String {
        return CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""
    }

    @objc public var latitude: NSNumber? {
        if let location = MAXLocationProvider.shared.getLocation() {
            return NSNumber(value: location.coordinate.latitude)
        }
        return nil
    }

    @objc public var longitude: NSNumber? {
        if let location = MAXLocationProvider.shared.getLocation() {
            return NSNumber(value: location.coordinate.longitude)
        }

        return nil
    }

    @objc public var locationTrackingAvailability: String {
        return MAXLocationProvider.shared.locationTrackingAvailability()
    }

    @objc public var sdkVersion: String {
        return MAXConfiguration.shared.getSDKVersion()
    }

    @objc public var locationHorizontalAccuracy: NSNumber? {
        return NSNumber(value: MAXLocationProvider.shared.getLocationHorizontalAccuracy() ?? 0)
    }

    @objc public var locationVerticalAccuracy: NSNumber? {
        return NSNumber(value: MAXLocationProvider.shared.getLocationVerticalAccuracy() ?? 0)
    }

    @objc public var locationTrackingTimestamp: String? {
        if let dt = MAXLocationProvider.shared.getLocationUpdateTimestamp() {
            return MaxDateFormatter.rfc3339DateTimeStringForDate(dt)
        } else {
            return nil
        }
    }

    @objc public var locationData: Dictionary<String, Any> {
        var locationData: Dictionary<String, Any> = [:]

        if let latitude = self.latitude {
            locationData["latitude"] = latitude
        }

        if let longitude = self.longitude {
            locationData["longitude"] = longitude
        }

        if let vAccuracy = self.locationVerticalAccuracy {
            locationData["vertical_accuracy"] = vAccuracy
        }

        if let hAccuracy = self.locationHorizontalAccuracy {
            locationData["horizontal_accuracy"] = hAccuracy
        }

        if let locationTimestamp = self.locationTrackingTimestamp {
            locationData["timestamp"] = locationTimestamp
        }

        return locationData
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

    @objc public var tokens: Dictionary<String, String> {
        var tokenData: Dictionary<String, String> = [:]

        for (_, tokenProvider) in MAXConfiguration.shared.directSDKManager.tokenRegistrar.tokens {
            tokenData[tokenProvider.identifier] = tokenProvider.generateToken()
        }

        return tokenData
    }

    @objc public var dict: Dictionary<String, Any> {
        let d: Dictionary<String, Any> = [
            "v": MAXAdRequest.apiVersion,
            "sdk_v": self.sdkVersion,
            "app_v": self.appVersion,
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
            "session_depth": MAXSessionManager.shared.combinedDepthForAllAds().intValue,
            "session": MAXSessionManager.shared.session.dict,
            "location_tracking": self.locationTrackingAvailability,
            "location": self.locationData,
            "tokens": self.tokens,
        ]

        MAXLogger.debug(d.description)
        return d
    }

    @objc public var asJSONObject: Data? {
        let data = try? JSONSerialization.data(withJSONObject: self.dict, options: [])
        return data
    }

    @objc public func getUrl() -> URL {
        return URL(string: "https://\(MAXAdRequest.adsDomain)/ads/req/\(self.adUnitID!)")!
    }

    @objc public func getSession() -> URLSession {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        return session
    }

    /// Conducts a pre-bid request for a given MAX AdUnit. When the pre-bid has completed,
    /// the callback function provided is invoked and the pre-bid ad response is made available
    /// through that callback. Timeouts and other errors are also returned through the callback.
    /// - Parameter adUnitID: the MAX ad unit ID string
    /// - Parameter completion: a callback function that will be executed when the response has completed or errored
    /// - Returns: the MAXAdRequest object representing the request being made
    @objc public class func preBidWithMAXAdUnit(_ adUnitID: String, completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        let adr = MAXAdRequest(adUnitID: adUnitID)
        adr.requestAd(adUnitId: adUnitID, {(response, error) in
            
            // only cache ad responses that may be displayed if MAX wins in the MoPub waterfall
            if response?.isReserved == false {
                MAXAds.receivedPreBid(adUnitID: adUnitID, response: response, error: error)
            }
            
            completion(response, error)
        })
        return adr
    }

    /// Begin the ad flow by calling `requestAd()`, which conducts various server side
    /// auctions and other ad logic to determine the ad plan.
    ///
    /// The delegate is called with the ad plan when it is ready, after which point, the
    /// plan can be executed whenever an ad needs to be shown. Once the ad is shown,
    /// the ad request should be discarded.
    /// - Parameter completion: a `MAXResponseCompletion` callback to be called when the request completes.
    @objc public func requestAd(adUnitId: String, _ completion: @escaping MAXResponseCompletion) {
        MAXLogger.debug("\(String(describing: self)): request ad with id - \(adUnitId)")
        
        // Setup POST
        let url = self.getUrl()
        let session = getSession()
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"

        session.uploadTask(with: request as URLRequest, from: self.asJSONObject, completionHandler: { (respData, resp, err) in
            do {
                guard let data = respData, let response = resp as? HTTPURLResponse else {
                    if let error = err {
                        throw error
                    } else {
                        throw MAXRequestError.invalidResponse(response: resp, data: respData)
                    }
                }

                if response.statusCode == 200 {
                    self.adResponse = try MAXAdResponse(adUnitId: adUnitId, data: data)
                    completion(self.adResponse, nil)
                } else if response.statusCode == 204 {
                    print("\(String(describing: MAXAdRequest.self)) returned with statusCode = 204, which means nobody bid on this request - adUnitId: \(self.adUnitID)")
                    self.adResponse = MAXAdResponse()
                    completion(self.adResponse, nil)
                } else {
                    throw MAXRequestError.requestFailed(
                            domain: MAXAdRequest.adsDomain,
                            statusCode: response.statusCode,
                            userInfo: nil
                    )
                }
            } catch let error as NSError {
                self.adError = error
                completion(nil, error)
            }
        }).resume()
    }
}
