//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Quick
import Nimble
@testable import MAX


class MAXSessionSpec: QuickSpec {
    override func spec() {
        describe("MAXSession") {
            
            var session = MAXSessionStub()
            
            beforeEach {
                session = MAXSessionStub()
                session.sessionExpirationIntervalSeconds = 0.0
            }

            it("increments, decrements, and resets") {
                
                expect(session.sessionDepth).to(equal(0))

                session.incrementDepth()
                session.incrementDepth()
                session.incrementDepth()
                expect(session.sessionDepth).to(equal(3))

                session.resetDepth()
                expect(session.sessionDepth).to(equal(0))
            }

            it("resets when the application is no longer active") {
                session.incrementDepth()
                expect(session.sessionDepth).to(equal(1))
                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
                expect(session.sessionDepth).to(equal(0))
            }
            
            it("won't reset if the session hasn't expired") {
                session.sessionExpirationIntervalSeconds = 1000.0
                session.incrementDepth()
                expect(session.sessionDepth).to(equal(1))
                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
                let _ = session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
                expect(session.sessionDepth).to(equal(1))
            }
        }
    }
}

