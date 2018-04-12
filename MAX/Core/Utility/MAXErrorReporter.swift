import Foundation
import AdSupport
import CoreTelephony
import UIKit

public class MAXErrorReporter: NSObject, URLSessionTaskDelegate {
    
    @objc public static let shared = MAXErrorReporter(errorUrl: MAXErrorReporter.defaultErrorUrl)
    private static let defaultErrorUrl = URL(string: "https://ads.maxads.io/events/client-error")!
    //    private static let defaultErrorUrl = URL(string: "http://staging.ads.maxads.io/events/client-error")!
    private var errorUrl: URL
    
    @objc public init(errorUrl: URL) {
        self.errorUrl = errorUrl
        super.init()
    }
    
    @objc public func setUrl(url: URL) {
        self.errorUrl = url
    }
    
    @objc public func reportError(error: Error) {
        self.reportError(message: error.localizedDescription)
    }
    
    @objc public func reportError(message: String) {
        let clientError = MAXClientError(message: message)
        if let data = clientError.jsonData {
            self.record(data: data)
        }
    }
    
    @objc public func record(data: Data) {
        let request = NSMutableURLRequest(url: self.errorUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = data
        let session = getSession()
        session.uploadTask(with: request as URLRequest, from: data, completionHandler: { (respData, resp, err) in
            do {
                if let error = err {
                    self.logConsoleMessage(message: "failed to report an error <\(String(describing: error.localizedDescription))>")
                }
                
                guard let response = resp as? HTTPURLResponse else {
                    self.logConsoleMessage(message: "reported an error with a successful POST, but was returned an invalid response")
                    return
                }
                
                if response.statusCode == 200 {
                    self.logConsoleMessage(message: "successfully reported an error")
                } else {
                    self.logConsoleMessage(message: "failed to report due to status code - \(String(describing: response.statusCode))")
                }
            }
            // No need to catch and return an erorr. Error messages logged to console in 'do' block just above.
        }).resume()
    }
    
    private func getSession() -> URLSession {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        return session
    }
    
    // Do not use MAXLogger because it calls into this class.
    private func logConsoleMessage(message: String) {
        print("MAX [\(String(describing: self))] \(String(message))")
    }
}
