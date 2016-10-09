//
//  MAXAdRequest.swift
//  Pods
//
//

import Foundation
import AdSupport
import CoreTelephony
import UIKit

public protocol MAXAdRequestDelegate {
    func adRequestDidLoad(adRequest: MAXAdRequest)
    func adRequestDidFailWithError(adRequest: MAXAdRequest, error: NSError)
}

public class MAXAdRequest {
    public var adUnitID: String!
    public var delegate: MAXAdRequestDelegate?
    
    private var responseURL: NSURL?

    public var adResponse: MAXAdResponse?
    
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
    public func requestAd() {
        // All interesting things about this particular device
        let dict : NSDictionary = [
            "ifa": ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString,
            "lmt": ASIdentifierManager.sharedManager().advertisingTrackingEnabled ? false : true,
            "vendor_id": UIDevice.currentDevice().identifierForVendor?.UUIDString ?? "",
            "tz": NSTimeZone.systemTimeZone().abbreviation ?? "",
            "locale": NSLocale.systemLocale().localeIdentifier ?? "",
            "orientation": UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) ? "portrait" :
                (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? "landscape" : "none"),
            "w": floor(UIScreen.mainScreen().bounds.size.width),
            "h": floor(UIScreen.mainScreen().bounds.size.height),
            "browser_agent": UIWebView().stringByEvaluatingJavaScriptFromString("navigator.userAgent") ?? "",
            "model": self.model(),
            "connectivity": SKReachability.reachabilityForInternetConnection().isReachableViaWiFi() ? "wifi" :
                SKReachability.reachabilityForInternetConnection().isReachableViaWWAN() ? "wwan" : "none",
            "carrier": CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""]
        
        // Setup POST
        let url = NSURL(string: "https://sprl.com/ads/req/\(self.adUnitID)")!
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"

        do {
            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: [])
            
            session.uploadTaskWithRequest(request, fromData: data, completionHandler: { (_data, _response, _error) in
                do {
                    guard let data = _data,
                        response = _response as? NSHTTPURLResponse where
                        _error == nil else {
                        throw _error!
                    }
                    
                    if response.statusCode == 200 {
                        self.adResponse = try MAXAdResponse(data: data)
                        self.delegate?.adRequestDidLoad(self)
                    } else {
                        throw NSError(domain: "sprl.com",
                            code: response.statusCode,
                            userInfo: nil)
                    }
                } catch let error as NSError {
                    self.delegate?.adRequestDidFailWithError(self, error: error)
                }
            }).resume()
            
        } catch let error as NSError {
            self.delegate?.adRequestDidFailWithError(self, error: error)
        }
        
    }
    
    private func model() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
