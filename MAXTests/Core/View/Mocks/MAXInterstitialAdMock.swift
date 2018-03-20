//
//  MAXInterstitialAdMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

@testable import MAX

internal class MAXInterstitialAdMock: MAXInterstitialAd {
    
    internal var loaded = false
    internal var shown = false
    internal var didLoadUsingMRAID = false
    internal var didLoadUsingVAST = false
    internal var didLoadUsingAdapter = false
    
    override internal func loadInterstitial(creativeType: String) {
        loaded = true
        super.loadInterstitial(creativeType: creativeType)
    }
    
    override internal func loadAdWithMRAIDRenderer(creative: String) {
        didLoadUsingMRAID = true
    }
    
    override internal func loadAdWithVASTRenderer(creative: String) {
        didLoadUsingVAST = true
    }
    
    override internal func loadAdWithAdapter(adResponse: MAXAdResponse) {
        didLoadUsingAdapter = true
    }
    
    var generator: MAXInterstitialAdapterGenerator?
    override internal func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return generator
    }
    
    override public func showAdFromRootViewController(_ rootViewController: UIViewController) {
        shown = true
        super.showAdFromRootViewController(rootViewController)
    }
    
    override public func onRequestSuccess(adResponse: MAXAdResponse?) {
        // bypass main queue used in super class onRequestSuccess
        super.loadResponse(adResponse: adResponse!)
    }
}
