//
//  MAXBannerAdView.swift
//  MAX
//
//  Created by Bryan Boyko on 3/7/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

// A public facing facade that obfuscates BannerController, MAXAdView, and MAXAdRequestManager logic

@objc public protocol MAXBannerAdViewDelegate {
    @objc func onBannerLoaded(banner: MAXBannerAdView?)
    @objc func onBannerClicked(banner: MAXBannerAdView?)
    @objc func onBannerError(banner: MAXBannerAdView?, error: MAXClientError)
}

public class MAXBannerAdView: UIView {
    
    // Since MAXBannerAdView is just a facade for BannerController and the banners it manages,
    @objc public weak var delegate: MAXBannerAdViewDelegate? {
        get {
            return bannerController?.delegate
        }
        set {
            bannerController?.delegate = newValue
        }
    }
    
    // NOTE: bannerController cannot be declared as 'let' because MAXBannerAdView needs to pass an instance of itself into MAXBannerController initializer
    private var bannerController: MAXBannerController?
    
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        self.bannerController = MAXBannerController(bannerAdView: self, requestManager: MAXAdRequestManager(), sessionManager: MAXSessionManager.shared)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func load(adUnitId: String) {
        bannerController?.load(adUnitId: adUnitId)
    }
}
