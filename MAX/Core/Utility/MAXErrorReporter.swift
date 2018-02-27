import Foundation
import AdSupport
import CoreTelephony
import UIKit

public class MAXErrorReporter: NSObject {

    @objc public static let shared = MAXErrorReporter()
    private static let defaultErrorUrl = URL(string: "https://ads.maxads.io/events/client-error")!
    private var errorUrl: URL

    @objc public override init() {
        self.errorUrl = MAXErrorReporter.defaultErrorUrl
    }

    @objc public init(errorUrl: URL) {
        self.errorUrl = errorUrl
    }

    @objc public func setUrl(url: URL) {
        self.errorUrl = url
    }

    @objc public func logError(error: Error) {
        self.logError(message: error.localizedDescription)
    }

    @objc public func logError(message: String) {
        let clientError = MAXClientError(message: message)
        if let data = clientError.jsonData {
            self.record(data: data)
        }
    }

    @objc public func record(data: Data) {
        let request = NSMutableURLRequest(url: self.errorUrl)
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        urlSession.uploadTask(with: request as URLRequest, from: data)
    }
}
