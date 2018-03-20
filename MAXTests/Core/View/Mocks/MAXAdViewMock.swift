//
//  MAXAdViewMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Quick
import Nimble
@testable import MAX

internal class MAXAdViewMockListener: NSObject, MAXAdViewDelegate {
    
    internal var viewDidLoad = false
    internal var viewWillLogImpression = false
    internal var viewDidClick = false
    internal var viewDidFinishHandlingClick = false
    internal var viewDidFail = false
    internal var failureError: NSError?

    func adViewDidLoad(_ adView: MAXAdView?) {
        viewDidLoad = true
    }
    
    func adViewWillLogImpression(_ adView: MAXAdView?) {
        viewDidLoad = true
    }
    
    func adViewDidClick(_ adView: MAXAdView?) {
        viewWillLogImpression = true
    }
    
    func adViewDidFinishHandlingClick(_ adView: MAXAdView?) {
        viewDidFinishHandlingClick = true
    }
    
    func adViewDidFailWithError(_ adView: MAXAdView?, error: NSError?) {
        viewDidFail = true
    }
    
    @objc func viewControllerForMaxPresentingModalView() -> UIViewController? {
        return UIApplication.shared.delegate!.window!!.rootViewController
    }
}

internal class MAXAdViewMock: MAXAdView {
    var didLoadUsingMRAID = false
    override internal func loadAdWithMRAIDRenderer(creative: String) {
        didLoadUsingMRAID = true
    }
    
    var generator: MAXAdViewAdapterGenerator?
    override internal func getGenerator(forPartner partner: String) -> MAXAdViewAdapterGenerator? {
        return generator
    }
    
    var didLoadAdWithAdapter = false
    override func addSubview(_ view: UIView) {
        // It's safe to assume this call came from the loadAdWithAdapter method since
        // the loadAdWithMRAIDRenderer is overridden and is the only other method that
        // calls addSubview
        didLoadAdWithAdapter = true
    }
}
