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
    private var placementID: String!
    private var adPlanData: NSData?
    private var adValid: Bool = false
    
    public var delegate: MAXAdRequestDelegate?
    
    public init(placementID: String) {
        self.placementID = placementID
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
        // Detect connection characteristics
        /*
         bool wifi = [[SKReachability reachabilityForInternetConnection] isReachableViaWiFi];
         bool wwan = [[SKReachability reachabilityForInternetConnection] isReachableViaWWAN];
         CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
         */
        
        // Setup POST
        var url = NSURL(string: "https://sprl.com/ads/req/\(self.placementID)")!
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        var session = NSURLSession(configuration: config)
        
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        var dict : NSDictionary = [
            "ifa": ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString,
            "lmt": ASIdentifierManager.sharedManager().advertisingTrackingEnabled ? false : true,
            "vendor_id": UIDevice.currentDevice().identifierForVendor?.UUIDString ?? "",
            "tz": NSTimeZone.systemTimeZone().abbreviation ?? "",
            "locale": NSLocale.systemLocale().localeIdentifier ?? "",
            "orientation": UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) ? "portrait" :
                (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) ? "landscape" : "none"),
            "w": floor(UIScreen.mainScreen().bounds.size.width),
            "h": floor(UIScreen.mainScreen().bounds.size.height),
            "carrier": CTTelephonyNetworkInfo.init().subscriberCellularProvider?.carrierName ?? ""]
    

        do {
            var data = try NSJSONSerialization.dataWithJSONObject(dict, options: [])
            
            session.uploadTaskWithRequest(request, fromData: data, completionHandler: { (data, response, error) in
                guard let adPlanData = data else {
                    self.adPlanData = nil
                    self.adValid = false
                    if let error = error {
                        self.delegate?.adRequestDidFailWithError(self, error: error)
                    }
                    return
                }
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.adPlanData = adPlanData
                        self.adValid = true
                        self.delegate?.adRequestDidLoad(self)
                    } else {
                        self.adPlanData = nil
                        self.adValid = false
                        self.delegate?.adRequestDidFailWithError(self, error: NSError(domain: "sprl.com",
                            code: httpResponse.statusCode,
                            userInfo: nil))
                    }
                }
            }).resume()
            
        } catch var error as NSError {
            self.adPlanData = nil
            self.adValid = false
            self.delegate?.adRequestDidFailWithError(self, error: error)
        }
        
    }
}