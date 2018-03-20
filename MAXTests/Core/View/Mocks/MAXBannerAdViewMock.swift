//
//  MAXBannerAdViewMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

internal class MAXBannerAdViewListenerMock: NSObject, MAXBannerAdViewDelegate {
    
    internal var bannerLoaded = false
    internal var bannerClicked = false
    internal var bannerErrored = false
    internal var bannerError: MAXClientError?
    
    @objc func onBannerLoaded(banner: MAXBannerAdView?) {
        bannerLoaded = true
    }
    
    @objc func onBannerClicked(banner: MAXBannerAdView?) {
        bannerClicked = true
    }
    
    @objc func onBannerError(banner: MAXBannerAdView?, error: MAXClientError) {
        bannerErrored = true
        bannerError = error
    }
}

internal class MAXBannerAdViewMock: MAXBannerAdView {
    
}


