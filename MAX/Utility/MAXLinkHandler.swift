
//
//  MAXLinkHandler.swift
//

import Foundation
import StoreKit

class MAXLinkHandler: NSObject, SKStoreProductViewControllerDelegate, URLSessionTaskDelegate {
    
    let USE_STORE_KIT = false
    
    var session : Foundation.URLSession? = nil
    var sessionLastURL : URL?
    
    override init() {
        super.init()
        self.session = Foundation.URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: self,
                                    delegateQueue: nil)
    }
    
    // Tracks redirections, allowing them to continue, but remembering the last one
    //
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        self.sessionLastURL = request.url
        
        MAXLog.debug("Redirecting to \(self.sessionLastURL)")
        completionHandler(request)
    }
    
    // Opens a URL. This method will detect if a URL redirects to an iTunes page, 
    // in which case it will open the URL using the system call in UIApplication.
    //
    func openURL(_ viewController: UIViewController?,
                        url: URL,
                        completion: (()->Void)?) {
        guard USE_STORE_KIT else {
            UIApplication.shared.openURL(url)
            completion?()
            return
        }
        
        let task = session?.dataTask(with: url, completionHandler: { (data, response, error) in
            MAXLog.debug("After redirects, last URL was \(self.sessionLastURL)")
            
            guard let viewController = viewController,
                let sessionLastURL = self.sessionLastURL,
                let _ = sessionLastURL.host?.range(of: "itunes.apple.com"),
                let match = sessionLastURL.path.range(of: "/id(\\d+)", options: .regularExpression) else {
                    UIApplication.shared.openURL(url)
                    return
            }

            let iTunesID = sessionLastURL.path[sessionLastURL.path.index(match.lowerBound, offsetBy: 3) ..< match.upperBound]
            self.presentStoreKit(viewController, storeKitIdentifier: iTunesID, completion: completion)
        }) 
        task?.resume()
    }
    
    func presentStoreKit(_ vc: UIViewController, storeKitIdentifier: String, completion: (()->Void)?) {
        // Open the AppStore that handles the URL scheme in question
        let store = SKStoreProductViewController()
        store.delegate = self
        store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier : storeKitIdentifier], completionBlock: { (result, error) -> Void in
            if let error = error {
                MAXLog.debug("\(error.localizedDescription)")
                completion?()
            } else {
                vc.present(store, animated: true, completion: completion)
                completion?()
            }
        })
    }
}
