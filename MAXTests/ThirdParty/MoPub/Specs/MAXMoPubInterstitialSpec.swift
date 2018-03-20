//
//  MAXMoPubInterstitialSpec.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
import MoPub
@testable import MAX


internal class MAXMoPubInterstitialSpec: QuickSpec {
    override func spec() {
        describe("MAXMoPubInterstitial") {
            
            let rvc = UIViewController()
            let adUnitId = "id"
            let mpAdUnitId = "idMP"
            // The secret agent will report back to mpInterstitialAdControllerSwizzleMock via swizzled methods
            let mpInterstitialControllerSecretAgent = MPInterstitialAdController(forAdUnitId: mpAdUnitId)
            // Swizzle mock exists as a wrapper for the secret agent. Mock functionality and state implemented in swizzle mock.
            _ = MPInterstitialAdControllerSwizzleMock(secretAgent: mpInterstitialControllerSecretAgent!)
            var response = MAXAdResponseStub()
            let requestManager = MAXAdRequestManagerMock()
            requestManager.response = response
            let sessionManager = MAXSessionManager.shared
            let maxInterstitial = MAXInterstitialAdMock(requestManager: requestManager, sessionManager: sessionManager)
            let maxMPInterstitial = MAXMoPubInterstitialMock(maxAdUnitId: adUnitId, mpInterstitial: mpInterstitialControllerSecretAgent!, maxInterstitial: maxInterstitial, sessionManager: sessionManager, rootViewController: rvc)
            
            beforeEach {
                mpInterstitialControllerSecretAgent!.keywords = nil
                MPInterstitialAdControllerSwizzleMock.loaded = false
                MPInterstitialAdControllerSwizzleMock.shown = false
                maxInterstitial.loaded = false
                maxInterstitial.shown = false
                response = MAXAdResponseStub()
                requestManager.response = response
                requestManager.error = nil
                sessionManager.reset()
            }
            
            it("if load() is called and an unreserved ad response is successfully requested, a MoPub interstitial will be loaded with MAX prebid keywords.") {

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(beNil())
                expect(maxInterstitial.loaded).to(beFalse())

                maxMPInterstitial.load()

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beTrue())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(equal(response.preBidKeywords))
                expect(maxInterstitial.loaded).to(beFalse())
            }

            it("if load() is called and a MAX reserved response is successfully requested, a MAX interstitial will be loaded") {

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(beNil())
                expect(maxInterstitial.loaded).to(beFalse())

                response._isReserved = true

                maxMPInterstitial.load()

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(beNil())
                expect(maxInterstitial.loaded).to(beTrue())
            }

            it("if load() is called and the corresponding request fails, a MoPub interstitial will be loaded with no prebid keywords") {
                
                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(beNil())
                expect(maxInterstitial.loaded).to(beFalse())

                let error = NSError(domain: "ads.maxads.io", code: 400)
                requestManager.error = error
                
                maxMPInterstitial.load()
                
                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beTrue())
                expect(mpInterstitialControllerSecretAgent!.keywords).to(beNil())
                expect(maxInterstitial.loaded).to(beFalse())
            }
        
            it("if show() is called for an unreserved response requested via load(), a MoPub interstitial will be shown") {

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(maxInterstitial.shown).to(beFalse())
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))
                expect(sessionManager.sspDepthForAd(adUnitId: mpAdUnitId).intValue).to(equal(0))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(0))

                maxMPInterstitial.load()
                maxMPInterstitial.show()

                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beTrue())
                expect(maxInterstitial.shown).to(beFalse())
                expect(sessionManager.sspDepthForAd(adUnitId: mpAdUnitId).intValue).to(equal(1))
                expect(sessionManager.sspDepthForAllAds().intValue).to(equal(1))
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(1))
            }
        
            it("if show() is called and a MAX reserved response had been successfully requested via calling load(), a MAX interstitial will be shown") {
                
                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(maxInterstitial.shown).to(beFalse())
                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(0))
                expect(sessionManager.maxDepthForAd(adUnitId: mpAdUnitId).intValue).to(equal(0))
                expect(sessionManager.maxDepthForAllAds().intValue).to(equal(0))
                
                response._isReserved = true
                
                maxMPInterstitial.load()
                maxMPInterstitial.show()
                
                expect(MPInterstitialAdControllerSwizzleMock.loaded).to(beFalse())
                expect(maxInterstitial.shown).to(beTrue())
                
                //TODO - Bryan: Need MAXInterstitialFactory to test -> factory mock will be injected into MAXInterstitialAd or MAXInterstitialController. It can provide MAXInterstitialMock instances to populate MAXInterstitialAd interstitial instances when showAd is called
//                expect(sessionManager.maxDepthForAd(adUnitId: mpAdUnitId).intValue).to(equal(1))
//                expect(sessionManager.maxDepthForAllAds().intValue).to(equal(1))
//                expect(sessionManager.combinedDepthForAllAds().intValue).to(equal(1))
            }
        }
    }
}
