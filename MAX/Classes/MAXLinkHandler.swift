
//
//  MAXLinkHandler.swift
//  MoVideo
//
//  Created by Edison Wang on 12/4/15.
//  Copyright © 2015 MoLabs Inc. All rights reserved.
//

import Foundation
import StoreKit

class MAXLinkHandler: NSObject, SKStoreProductViewControllerDelegate, NSURLSessionTaskDelegate {
    
    var session : NSURLSession? = nil
    var sessionLastURL : NSURL?
    
    public override init() {
        super.init()
        self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                                    delegate: self,
                                    delegateQueue: nil)
    }
    
    // Tracks redirections, allowing them to continue, but remembering the last one
    //
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        self.sessionLastURL = request.URL
        
        NSLog("Redirecting to \(sessionLastURL)")
        completionHandler(request)
    }
    
    // Opens a URL. This method will detect if a URL redirects to an iTunes page, 
    // in which case it will open the URL using the system call in UIApplication.
    //
    public func openURL(viewController: UIViewController?,
                        url: NSURL,
                        completion: (()->Void)?) {
        let task = session?.dataTaskWithURL(url) { (data, response, error) in
            NSLog("After redirects, last URL was \(self.sessionLastURL)")
            
            guard let viewController = viewController,
                let sessionLastURL = self.sessionLastURL,
                let iTunesHost = sessionLastURL.host?.rangeOfString("itunes.apple.com"),
                let match = sessionLastURL.path?.rangeOfString("/id(\\d+)", options: .RegularExpressionSearch),
                let iTunesID = sessionLastURL.path?[match.startIndex.advancedBy(3) ..< match.endIndex] else {
                    UIApplication.sharedApplication().openURL(url)
                    return
            }
            
            self.presentStoreKit(viewController, storeKitIdentifier: iTunesID, completion: completion)
        }
        task?.resume()
    }
    
    func presentStoreKit(vc: UIViewController, storeKitIdentifier: String, completion: (()->Void)?) -> Bool {
        // Open the AppStore that handles the URL scheme in question
        let store = SKStoreProductViewController()
        store.delegate = self
        store.loadProductWithParameters([SKStoreProductParameterITunesItemIdentifier : storeKitIdentifier], completionBlock: { (result, error) -> Void in
            if let error = error {
                NSLog("\(error.localizedDescription)")
                completion?()
            } else {
                vc.presentViewController(store, animated: true, completion: completion)
                completion?()
            }
        })
        return true
    }
}
