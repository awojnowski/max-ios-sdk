//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXRequestManagerTests: XCTestCase {

    let adUnitID = "1234"

    class TestableMAXAdRequestManager: MAXAdRequestManager {
        var response: MAXAdResponse? = nil
        var error: NSError? = nil
        var request: MAXAdRequest!

        override init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
            super.init(adUnitID: adUnitID, completion: completion)
            
            self.request = MAXAdRequest(adUnitID: adUnitID)
        }
        
        override func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
            print("TestableMAXAdRequestManager.runPrebid called")
            completion(response, error)
            return request
        }
    }

    func testRefresh() {
        let testCompletion = expectation(description: "MAXAdRequestManager completes normally")
        var manager = TestableMAXAdRequestManager(adUnitID: adUnitID) { (response, error) in
            testCompletion.fulfill()
        }

        var response = MAXAdResponse()
        response.autoRefreshInterval = 2
        manager.response = response
        manager._errorCount = 1

        manager.refresh()
        waitForExpectations(timeout: 0)

        XCTAssertEqual(manager._errorCount, 0)
    }

    func testRefreshWithError() {
        let testCompletion = expectation(description: "MAXAdRequestManager completes normally")
        var manager = TestableMAXAdRequestManager(adUnitID: adUnitID) { (response, error) in
            testCompletion.fulfill()
        }

        var error = NSError(domain: "ads.maxads.io", code: 400)
        manager.error = error
        manager.response = nil

        manager.refresh()
        waitForExpectations(timeout: 0)

        XCTAssertEqual(manager._errorCount, 1)
    }
}
