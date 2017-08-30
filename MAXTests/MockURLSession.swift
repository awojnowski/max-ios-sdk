//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

typealias Completion = (Data?, URLResponse?, Error?) -> Void

class MockUploadTask: URLSessionUploadTask {
    var request: URLRequest
    var bodyData: Data?
    var completionHandler: Completion
    var mockResponse: URLResponse?
    var mockResponseData: Data?
    var mockError: Error?

    init(request:URLRequest, bodyData: Data?, completionHandler: @escaping Completion) {
        self.request = request
        self.bodyData = bodyData
        self.completionHandler = completionHandler
    }

    override func resume() {
        self.completionHandler(self.mockResponseData, self.mockResponse, self.mockError)
    }
}

class MockURLSession: URLSession {
    var mockedRequests: Dictionary<String, (URLResponse, Data?, Error?)> = [:]
    func onRequest(to url: URL, respondWith response: URLResponse, withData data: Data) {
        mockedRequests[url.absoluteString] = (response, data, nil)
    }

    func onRequest(to url: URL, respondWith response: URLResponse, withError error: Error) {
        mockedRequests[url.absoluteString] = (response, nil, error)
    }

    func clearMock(for url: URL) {
        mockedRequests.removeValue(forKey: url.absoluteString)
    }

    func clearMocks() {
        mockedRequests.removeAll()
    }

    override func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping Completion) -> URLSessionUploadTask {
        let task = MockUploadTask(request: request, bodyData: bodyData, completionHandler: completionHandler)
        if let mockResponse = mockedRequests[request.url!.absoluteString] {
            print("Found a mock response for \(request.url!.absoluteString)")
            task.mockResponse = mockResponse.0
            task.mockResponseData = mockResponse.1
            task.mockError = mockResponse.2
        }
        return task
    }
}

