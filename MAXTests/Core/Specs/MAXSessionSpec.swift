//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Quick
import Nimble
@testable import MAX


class MAXSessionManagerSpec: QuickSpec {
    override func spec() {
        describe("MAXSessionManager") {
            
            var sessionManager = MAXSessionManagerStub()
            
            beforeEach {
                sessionManager = MAXSessionManagerStub()
                sessionManager.sessionExpirationIntervalSeconds = 0.0
            }

            it("increments, decrements, and resets") {
                
                let adUnitId1 = "1"
                let adUnitId2 = "2"

                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))

                sessionManager.incrementMaxSessionDepth(adUnitId: adUnitId1)
                sessionManager.incrementSSPSessionDepth(adUnitId: adUnitId1)
                expect(sessionManager.combinedDepthForAd(adUnitId: adUnitId1).intValue).to(equal(2))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(2))

                sessionManager.incrementMaxSessionDepth(adUnitId: adUnitId2)
                sessionManager.incrementSSPSessionDepth(adUnitId: adUnitId2)
                expect(sessionManager.combinedDepthForAd(adUnitId: adUnitId1).intValue).to(equal(2))
                expect(sessionManager.combinedDepthForAd(adUnitId: adUnitId2).intValue).to(equal(2))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(4))

                sessionManager.reset()
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))
            }

            it("resets when the application is no longer active") {
                let adUnitId1 = "1"
                sessionManager.incrementMaxSessionDepth(adUnitId: adUnitId1)
                expect(sessionManager.combinedDepthForAllAds()).to(equal(1))
                let _ = sessionManager.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
                let _ = sessionManager.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
                expect(sessionManager.combinedDepthForAllAds()).to(equal(0))
            }

            it("won't reset if the session hasn't expired") {
                sessionManager.sessionExpirationIntervalSeconds = 1000.0
                let adUnitId1 = "1"
                sessionManager.incrementMaxSessionDepth(adUnitId: adUnitId1)
                expect(sessionManager.combinedDepthForAllAds()).to(equal(1))
                let _ = sessionManager.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
                let _ = sessionManager.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
                expect(sessionManager.combinedDepthForAllAds()).to(equal(1))
            }

            it("resets the session ID when reset() is called") {
                let id1 = sessionManager.session.sessionId
                sessionManager.reset()
                expect(sessionManager.session.sessionId).notTo(equal(id1))
            }
        }
    }
}

