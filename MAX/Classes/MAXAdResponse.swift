//
//  MAXAdResponse.swift
//  Pods
//
//

import Foundation
import StoreKit

let MAXAdResponseURLSession = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("MAXAdResponse"))

public class MAXAdResponse {
    public var createdAt : NSDate!
    public var data : NSData!
    public var response : NSDictionary!
    
    private var winner : NSDictionary?
    
    public var preBidKeywords : String! = ""

    public var creativeType : String! = "empty"
    public var creative : String? = ""
    
    public init() {
        self.createdAt = NSDate()
        self.data = NSData()
        self.response = [:]
    }
    
    public init(data: NSData) throws {
        self.createdAt = NSDate()
        self.data = data
        self.response = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! NSDictionary
        
        self.winner = self.response["ad_source_response"] as? NSDictionary
        self.preBidKeywords = self.response["prebid_keywords"] as? String ?? ""
        
        if let winner = self.winner {
            self.creativeType = winner["creative_type"] as? String ?? "empty"
            self.creative = winner["creative"] as? String
        }
    }
    
    // 
    // Fires an impression tracking event for this AdResponse
    //
    public func trackImpression() {
        if let trackingUrl = self.response["impression_url"] as? String,
            url = NSURL(string: trackingUrl) {
            self.track(url)
        }
    }

    //
    // Fires a click tracking event for this AdResponse
    //
    public func trackClick() {
        if let trackingUrl = self.response["click_url"] as? String,
            url = NSURL(string: trackingUrl) {
            self.track(url)
        }
        
    }
    
    // 
    // Handles a click out by opening the platform browser and also
    // tracking the click event
    //
    public func handleClick(viewController: UIViewController, url: NSURL) {
        self.trackClick()
        
        // Open StoreKit
        //
        LinkHandler { (vc) in
            
            
        }.openURL(viewController, url: url)
    }

    private func track(url: NSURL) {
        NSLog("MAXAdResponse.track() => \(url)")        
        MAXAdResponseURLSession.dataTaskWithURL(url).resume()
    }
    
}

//
//  StoreLinker.swift
//  MoVideo
//
//  Created by Edison Wang on 12/4/15.
//  Copyright © 2015 MoLabs Inc. All rights reserved.
//

class LinkHandler: NSObject, SKStoreProductViewControllerDelegate, NSURLSessionTaskDelegate {
    
    let productViewControllerDidFinish:(SKStoreProductViewController) -> Void
    
    var session : NSURLSession? = nil
    var sessionLastURL : NSURL?
    
    init(onFinish:(SKStoreProductViewController) -> Void) {
        productViewControllerDidFinish = onFinish
        super.init()
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                    delegate: self,
                                    delegateQueue: nil)
    }
    
    func productViewControllerDidFinish(vc: SKStoreProductViewController) {
        productViewControllerDidFinish(vc)
    }
    
    // Tracks redirections, allowing them to continue, but remembering the last one
    //
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        self.sessionLastURL = request.URL
        
        NSLog("Redirecting to \(sessionLastURL)")
        completionHandler(request)
    }
    
    func openURL(viewController: UIViewController, url: NSURL) {
        let task = session?.dataTaskWithURL(url) { (data, response, error) in
            NSLog("After redirects, last URL was \(self.sessionLastURL)")
            if let sessionLastURL = self.sessionLastURL {
                if sessionLastURL.host == "itunes.apple.com" {
                    if let match = sessionLastURL.path?.rangeOfString("/id(\\d+)", options: .RegularExpressionSearch) {
                        let iTunesID = sessionLastURL.path?[match.startIndex.advancedBy(3) ..< match.endIndex]
                        self.present(viewController, deepLinkURL: nil, storeKitIdentifier: iTunesID)
                    }
                } else {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        task?.resume()
    }
    
    func present(vc: UIViewController, deepLinkURL: NSURL?, storeKitIdentifier: String?) -> Bool {
        // Ecosystem connections here
        if let deepLinkURL = deepLinkURL where UIApplication.sharedApplication().canOpenURL(deepLinkURL) {
            // Open the URL in the relevant app
            UIApplication.sharedApplication().openURL(deepLinkURL)
            return true
        } else if let storeKitIdentifier = storeKitIdentifier {
            // Open the AppStore that handles the URL scheme in question
            let store = SKStoreProductViewController()
            store.delegate = self
            store.loadProductWithParameters([SKStoreProductParameterITunesItemIdentifier : storeKitIdentifier], completionBlock: { (result, error) -> Void in
                if let error = error {
                    NSLog("\(error.localizedDescription)")
                } else {
                    vc.presentViewController(store, animated: true, completion: nil)
                }
            })
            return true
        }
        return false
    }
}
