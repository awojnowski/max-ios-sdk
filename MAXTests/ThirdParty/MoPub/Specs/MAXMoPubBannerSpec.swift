//
//  MAXMoPubBannerSpec.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
import MoPub
@testable import MAX


internal class MAXMoPubBannerSpec: QuickSpec {
    
    override func spec() {
        describe("MAXMoPubBannerSpec") {
            let maxAdUnitId = "1234MAX"
            let moPubAdUnitId = "1234MoPub"
            
            let bannerAdView = UIView()
            
            let response = MAXAdResponseStub()
            response.autoRefreshInterval = 1
            let requestManager = MAXAdRequestManagerMock()
            requestManager.response = response
            let sessionManager = MAXSessionManager.shared
            let bannerController = MAXBannerControllerMock(bannerAdView: bannerAdView, requestManager: requestManager, sessionManager: sessionManager)
            let mpAdView = MPAdViewMock(adUnitId: "nothing", size: CGSize(width: 0, height: 0))
            let moPubBanner = MAXMoPubBannerMock(mpAdView: mpAdView!, bannerController: bannerController, sessionManager: sessionManager)
            
            beforeEach {
                moPubBanner.disableAutoRefresh = true
                mpAdView!.loadCalled = false
                mpAdView!.keywords = nil
                mpAdView!.adUnitId = nil
                response._isReserved = false
                requestManager.error = nil
                requestManager.errorCount = 0
                requestManager.refreshTimerStarted = false
                bannerController.adShown = false
                sessionManager.reset()
            }
            
            it("loads an MPAdView ad for injected ad unit id and pre bid keywords after load() is called for a non-reserved ad response. SSP session depth incremented") {
                expect(response.isReserved).to(beFalse())
                expect(bannerController.adShown).to(beFalse())
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))
                expect(sessionManager.sspDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(0))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(0))

                moPubBanner.load(maxAdUnitId: maxAdUnitId, mpAdUnitId: moPubAdUnitId)

                expect(mpAdView!.loadCalled).to(beTrue())
                expect(mpAdView!.keywords).to(equal(response.preBidKeywords))
                expect(mpAdView!.adUnitId).to(equal(moPubAdUnitId))
                expect(bannerController.adShown).to(beFalse())
                expect(sessionManager.sspDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(1))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(1))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(1))
            }
            
            it("shows a MAXAdView after load() is called for a reserved ad response. MAX session depth incremented") {
                expect(mpAdView!.loadCalled).to(beFalse())
                expect(bannerController.adShown).to(beFalse())
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))
                expect(sessionManager.maxDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(0))
                expect(sessionManager.maxDepthForAllAds().intValue).to(equal(0))
                
                response._isReserved = true

                moPubBanner.load(maxAdUnitId: maxAdUnitId, mpAdUnitId: moPubAdUnitId)

                expect(mpAdView!.loadCalled).to(beFalse())
                expect(bannerController.adShown).to(beTrue())
                
                //TODO - Bryan: Need MAXAdViewFactory to test -> factory mock will be injected into banner controller. It can provide MAXAdViewMock instances to populate nextAdView instances when showAd is called
//                expect(sessionManager.maxDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(1))
//                expect(sessionManager.maxDepthForAllAds().intValue).to(equal(1))
//                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(1))
            }

            it("loads an MPAdView ad without pre bid keywords after load() is called and there is a request error. SSP session depth incremented") {
                expect(mpAdView!.loadCalled).to(beFalse())
                expect(bannerController.adShown).to(beFalse())
                expect(sessionManager.sspDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(0))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(0))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))

                let error = MAXClientError(message: "request error")
                requestManager.error = error
                
                moPubBanner.load(maxAdUnitId: maxAdUnitId, mpAdUnitId: moPubAdUnitId)

                expect(mpAdView!.loadCalled).to(beTrue())
                expect(mpAdView!.keywords).to(beNil())
                expect(mpAdView!.adUnitId).to(equal(moPubAdUnitId))
                expect(bannerController.adShown).to(beFalse())
                expect(sessionManager.sspDepthForAd(adUnitId: moPubAdUnitId).intValue).to(equal(1))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(1))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(1))
            }

            it("starts a new refresh after an MPAdView loaded") {
                expect(mpAdView!.loadCalled).to(beFalse())
                expect(bannerController.adShown).to(beFalse())
                expect(requestManager.refreshTimerStarted).to(beFalse())

                moPubBanner.disableAutoRefresh = false
                moPubBanner.load(maxAdUnitId: maxAdUnitId, mpAdUnitId: moPubAdUnitId)

                expect(mpAdView!.loadCalled).to(beTrue())
                expect(bannerController.adShown).to(beFalse())
                expect(requestManager.refreshTimerStarted).to(beTrue())
            }
        }
    }
}
