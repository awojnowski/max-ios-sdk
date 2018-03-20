//
//  MAXBannerController.swift
//  MAX
//
//  Created by Bryan Boyko on 3/5/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//


import Quick
import Nimble
import MoPub
@testable import MAX

class MAXBannerControllerSpec: QuickSpec {
    
    override func spec() {
        describe("MAXBannerController") {
            let adUnitID = "1234"
            
            let bannerAdView = UIView()
            
            let response = MAXAdResponseStub()
            response.autoRefreshInterval = 1
            let requestManager = MAXAdRequestManagerMock()
            requestManager.response = response
            //TODO - BRYAN: having a minErrorRetrySeconds greater than 1 slows down testing. Make backoff work with values less than 1?
            requestManager.minErrorRetrySeconds = 1.1
            let bannerController = MAXBannerControllerMock(bannerAdView: bannerAdView, requestManager: requestManager, sessionManager: MAXSessionManager.shared)
            
            beforeEach {
                requestManager.error = nil
                requestManager.errorCount = 0
                requestManager.refreshTimerStarted = false
                bannerController.adShown = false
            }
            
            it("shows an ad after load is called") {
                expect(bannerController.adShown).to(beFalse())

                bannerController.load(adUnitId: adUnitID)

                // the manager should have received a call to refresh after the impression
                expect(bannerController.adShown).to(beTrue())
            }

            it("does not show an ad for a request failure") {
                let error = MAXClientError(message: "request error")
                requestManager.error = error

                bannerController.load(adUnitId: adUnitID)

                expect(bannerController.adShown).to(beFalse())
            }

            it("calls on its request manager to request another ad if the initial request failed") {
                expect(requestManager.refreshTimerStarted).to(beFalse())
                
                let error = MAXClientError(message: "request error")
                requestManager.error = error
                
                expect(requestManager.refreshTimerStarted).to(beFalse())

                bannerController.load(adUnitId: adUnitID)

                // MAXBannerController loadAd() calls requestAd(). refreshTimerStarted is only called by MAXBannerController after MAXAdRequestManager callbacks execute from an initial call to requestAd() via loadAd().
                expect(requestManager.refreshTimerStarted).to(beTrue())
            }

            it("retries after request errors with an exponential backoff") {
                expect(requestManager.refreshTimerStarted).to(beFalse())
                
                let error = MAXClientError(message: "request error")
                requestManager.error = error

                bannerController.load(adUnitId: adUnitID)

//                 MAXBannerController loadAd() calls requestAd(). refreshTimerStarted is only called by MAXBannerController after MAXAdRequestManager callbacks execute from an initial call to requestAd() via loadAd().
                expect(requestManager.refreshTimerStarted).to(beTrue())
                //TODO - Bryan: For some reason requestManager timer selector never fires for this test method. It does fire for the same test in MAXAdRequestManagerMock...
//                let backoffTime = requestManager.minErrorRetrySeconds + pow(requestManager.minErrorRetrySeconds, 2) + pow(requestManager.minErrorRetrySeconds, 3)
//                expect(requestManager.errorCount).toEventually(equal(3), timeout: backoffTime)
            }
        }
    }
}
