//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import XCTest
@testable import MAX

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

        self.response

        self.completionHandler = completionHandler
    }

    override func resume() {
        self.completionHandler(self.mockResponseData, self.mockResponse, self.mockError)
    }
}

class MockURLSession: URLSession {
    var mockedRequests: Dictionary<String, Data> = [:]
    func onRequest(to request: URLRequest, respondWith data: Data) {
        mockedRequests[request.url!.absoluteString] = data
    }

    override func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping Completion) -> URLSessionUploadTask {
        let task = MockUploadTask(request: request, bodyData: bodyData, completionHandler: completionHandler)
        if let data = mockedRequests[request.url!.absoluteString] {
            task.mockResponse
        }
        return task
    }
}

class MAXAdRequestTests: XCTestCase {

    class TestableMAXAdRequest: MAXAdRequest {
        override func getSession() -> URLSession {
            return MockURLSession()
        }
    }

    func testSerialization() {
        let adRequest = MAXAdRequest(adUnitID: "1234")
        let reqDict = adRequest.dict

        XCTAssertNotNil(reqDict["v"])
        XCTAssertNotNil(reqDict["ifa"])
        XCTAssertNotNil(reqDict["lmt"])
        XCTAssertNotNil(reqDict["vendor_id"])
        XCTAssertNotNil(reqDict["tz"])
        XCTAssertNotNil(reqDict["locale"])
        XCTAssertNotNil(reqDict["orientation"])
        XCTAssertNotNil(reqDict["w"])
        XCTAssertNotNil(reqDict["h"])
        XCTAssertNotNil(reqDict["browser_agent"])
        XCTAssertNotNil(reqDict["model"])
        XCTAssertNotNil(reqDict["connectivity"])
        XCTAssertNotNil(reqDict["carrier"])
        XCTAssertNotNil(reqDict["longitude"])
        XCTAssertNotNil(reqDict["latitude"])
        XCTAssertNotNil(reqDict["session_depth"])
    }

    func testRequestAd() {
        let adRequest = TestableMAXAdRequest(adUnitID: "1234")
        adRequest.requestAd { (response, error) in
            print(response)
            XCTAssertNotNil(nil)
        }
    }
}
