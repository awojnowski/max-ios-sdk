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
    
    override internal func loadInterstitial() {
        loaded = true
        super.loadInterstitial()
    }
    
    override internal func loadAdWithMRAIDRenderer() {
        didLoadUsingMRAID = true
    }
    
    override internal func loadAdWithVASTRenderer() {
        didLoadUsingVAST = true
    }
    
    override internal func loadAdWithAdapter() {
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
