import UIKit
import Foundation

/// Safely determine the device's webview user-agent string.
/// UIKit calls, e.g. initializing a UIView, must happen on the
/// main thread or can crash the app.
class MAXUserAgent {
    var value: String?
    
    public static let shared = MAXUserAgent()
    private init() {
        MAXLog.debug("MAXUserAgent will set the user agent for the app's lifetime")
        self.value = MAXUserAgent.getUserAgent()
    }
    
    private static func getUserAgent() -> String? {
        guard Thread.current.isMainThread else {
            MAXLog.warn("MAXUserAgent init was called off the main thread and could not be set.")
            return nil
        }
        
        let webView = UIWebView()
        guard let webViewUserAgent = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") else {
            return nil
        }
        
        return webViewUserAgent
    }
}
