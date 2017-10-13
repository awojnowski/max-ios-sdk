//
// Created by John Pena on 8/24/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import AdSupport
import CoreTelephony
import UIKit

public class MAXErrorReporter {

    static let shared = MAXErrorReporter()
    static let defaultErrorUrl = URL(string: "https://ads.maxads.io/events/client-error")!
    var errorUrl: URL

    public init(errorUrl: URL = MAXErrorReporter.defaultErrorUrl) {
        self.errorUrl = errorUrl
    }

    public func setUrl(url: URL) {
        self.errorUrl = url
    }

    public func logError(error: Error) {
        self.logError(message: error.localizedDescription)
    }

    public func logError(message: String) {
        let clientError = MAXClientError(message: message)
        if let data = clientError.jsonData {
            self.record(data: data)
        }
    }

    func record(data: Data) {
        let request = NSMutableURLRequest(url: self.errorUrl)
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        urlSession.uploadTask(with: request as URLRequest, from: data)
    }
}
