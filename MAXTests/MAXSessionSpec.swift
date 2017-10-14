//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

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

class MAXSessionSpec: QuickSpec {
    override func spec() {
        describe("MAXSession") {
            it("increments, decrements, and resets") {
                let session = TestableMAXSession()
                expect(session.sessionDepth).to(equal(0))

                session.incrementDepth()
                session.incrementDepth()
                session.incrementDepth()
                expect(session.sessionDepth).to(equal(3))

                session.resetDepth()
                expect(session.sessionDepth).to(equal(0))
            }

            it("resets when the application is no longer active") {
                let session = TestableMAXSession()

                session.incrementDepth()
                expect(session.sessionDepth).to(equal(1))

                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
                expect(session.sessionDepth).to(equal(0))

                session.incrementDepth()
                session.incrementDepth()
                expect(session.sessionDepth).to(equal(2))

                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
                expect(session.sessionDepth).to(equal(0))
            }
        }
    }
}

