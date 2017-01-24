//
//  MAXAdRequest.swift
//  Pods
//
//

import Foundation
import AdSupport
import CoreTelephony
import UIKit

var MAXPreBids : [String : MAXAdResponse] = [:]
var MAXPreBidErrors : [String : NSError] = [:]

public class MAXAdRequest {
    public static let ADS_DOMAIN = "ads.maxads.io"

    // 
    // Conducts a pre-bid for a given MAX AdUnit. When the pre-bid has compelted, 
    // the callback function provided is invoked and the pre-bid ad response is made available
    // through that callback. Timeouts and other errors are also returned through the callback.
    //
    public class func preBidWithMAXAdUnit(_ adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) -> MAXAdRequest {
        let adr = MAXAdRequest(adUnitID: adUnitID)
        adr.requestAd() {(response, error) in
            MAXPreBids[adr.adUnitID] = response
            MAXPreBidErrors[adr.adUnitID] = error
            completion(response, error)
        }
        return adr
    }

    public var adUnitID: String!
    
    public var adResponse: MAXAdResponse?
    public var adError: NSError?
    
    //
    // Initialize a new ad request
    // 
    public init(adUnitID: String) {
        self.adUnitID = adUnitID
    }
        
    // 
    // Begin the ad flow by calling requestAd(), which conducts various server side 
    // auctions and other ad logic to determine the ad plan. 
    // 
    // The delegate is called with the ad plan when it is ready, after which point, the
    // plan can be executed whenever an ad needs to be shown. Once the ad is shown, 
    // the ad request should be discarded. 
    //
    public func requestAd(_ completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        // All interesting things about this particular device
        let dict : NSDictionary = [
            "ifa": ASIdentifierManager.shared().advertisingIdentifier.uuidString,
            "lmt": ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? false : true,
            "vendor_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "tz": NSTimeZone.system.abbreviation() ?? "",
            "locale": Locale.current.identifier ?? "",
            "orientation": UIDeviceOrientationIsPortrait(UIDevice.current.orientation) ? "portrait" :
                (UIDeviceOrientationIsLandscape(UIDevice.current.orientation) ? "landscape" : "none"),
            "w": floor(UIScreen.main.bounds.size.width),
            "h": floor(UIScreen.main.bounds.size.height),
            "browser_agent": UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? "",
            "model": self.model(),
            "connectivity": SKReachability.forInternetConnection().isReachableViaWiFi() ? "wifi" :
                SKReachability.forInternetConnection().isReachableViaWWAN() ? "wwan" : "none",
            "carrier": CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""]
        
        // Setup POST
        let url = URL(string: "https://\(MAXAdRequest.ADS_DOMAIN)/ads/req/\(self.adUnitID!)")!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            session.uploadTask(with: request as URLRequest, from: data, completionHandler: { (_data, _response, _error) in
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
    
    private func model() -> String {
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
