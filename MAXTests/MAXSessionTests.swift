//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

class MAXSessionTests: XCTestCase {

    class TestableMAXSession: MAXSession {
        var notificationCenter: MockNotificationCenter
        init() {
            self.notificationCenter = MockNotificationCenter()
            super.init(notificationCenter: self.notificationCenter)
        }

        @objc
        override func resetDepth() {
            super.resetDepth()
        }
    }

    func testSessionDepth() {
        let session = TestableMAXSession()
        XCTAssertEqual(session.sessionDepth, 0)

        session.incrementDepth()
        session.incrementDepth()
        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 3)

        session.resetDepth()
        XCTAssertEqual(session.sessionDepth, 0)
    }

    func testObservers() {
        let session = TestableMAXSession()

        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 1)

        let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
        XCTAssertEqual(session.sessionDepth, 0)

        session.incrementDepth()
        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 2)

        let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
        XCTAssertEqual(session.sessionDepth, 0)
    }
}
