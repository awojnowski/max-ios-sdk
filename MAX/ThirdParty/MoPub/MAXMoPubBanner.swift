//
//  MAXMoPubBanner.swift
//  MAX
//
//  Created by Bryan Boyko on 3/6/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation
import MoPub
import SnapKit

// NOTE: MAXMoPubBanner will display expanded ads in the parent view controller of the mpAdView injected in init

public class MAXMoPubBanner: UIView, MAXAdRequestManagerDelegate, MPAdViewDelegate, MAXBannerAdViewDelegate {
    
    private let mpAdView: MPAdView
    private let bannerController: MAXBannerController
    private let sessionManager: MAXSessionManager
    // TODO - Bryan: add Initialization helper
    
    @objc public var disableAutoRefresh: Bool {
        get {
            return bannerController.disableAutoRefresh
        }
        set (newValue) {
            bannerController.disableAutoRefresh = newValue
        }
    }
    @objc public var mpAdViewDelegate: MPAdViewDelegate?
    @objc public var maxBannerAdViewDelegate: MAXBannerAdViewDelegate?
    @objc public private(set) var mpAdUnitId: String?
    private var adResponse: MAXAdResponse?
    
    @objc public convenience init(mpAdView: MPAdView) {
        self.init(mpAdView: mpAdView, bannerController: MAXBannerController(bannerAdView: mpAdView), sessionManager: MAXSessionManager.shared)
    }
    
    internal init(mpAdView: MPAdView, bannerController: MAXBannerController, sessionManager: MAXSessionManager) {
        self.mpAdView = mpAdView
        self.bannerController = bannerController
        self.sessionManager = sessionManager
        super.init(frame: self.mpAdView.frame)
        self.mpAdView.delegate = self
        self.addSubview(self.mpAdView)
        self.mpAdView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        self.mpAdView.stopAutomaticallyRefreshingContents()
        self.bannerController.delegate = self
        self.bannerController.hijackRequestManagerDelegate(maxRequestManagerDelegate: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // NOTE: Loading will also show an ad (For interstitials, show must be called separately)
    @objc public func load(maxAdUnitId: String, mpAdUnitId: String) {

        // must check for nil since this method can be called from ObjC
        guard maxAdUnitId != nil else {
            reportError(message: "\(String(describing: self)) load called with nil MAX ad unit id")
            return
        }
        
        // must check for nil since this method can be called from ObjC
        guard mpAdUnitId != nil else {
            reportError(message: "\(String(describing: self)) load called with nil MoPub ad unit id")
            return
        }
        
        self.mpAdUnitId = mpAdUnitId
        // Note that normally bannerController.load() will request an ad, load it, and show it. In this case, bannerController.load() requests an ad and MAXMoPubBanner handles the request callbacks (Because it hijacked the request manager delegate from banner controller)
        bannerController.load(adUnitId: maxAdUnitId)
    }
    
    internal func startRefreshTimer(adResponse: MAXAdResponse?) {
        let delay = adResponse != nil ? adResponse?.autoRefreshInterval?.intValue : MAXAdRequestManager.defaultRefreshTimeSeconds
        bannerController.startRefreshTimer(delay: delay!)
    }
    
    internal func loadResponse(adResponse: MAXAdResponse) {
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        if adResponse.isReserved {
            MAXLogger.debug("\(String(describing: self)): Ad is eligible for auction rounds, loading ad through MAX SDK")
            // Make call to bannerController in opposite direction of normal callbacks (up dependency chain) because we hijacked vbannerController.requestManager callbacks
            self.bannerController.onRequestSuccess(adResponse: adResponse)
        } else {
            MAXLogger.debug("\(String(describing: self)): Ad is not eligible for auction rounds, loading ad through MoPub SDK")
            adResponse.trackHandoff()
            // DANGER: If load() is called once and then again before a request returns for the first call, mpAdUnitId will have changed by the time this code is executed. It seems unlikely that a pub would call load() rapidly on the same instance of MAXMoPubBanner, but, if one did, our reporting of which ads are being shown would be inaccurate.
            self.mpAdView.adUnitId = self.mpAdUnitId
            self.mpAdView.keywords = adResponse.preBidKeywords
            self.mpAdView.loadAd()
        }
    }
    
    internal func loadVanillaMoPub() {
        
        guard Thread.isMainThread else {
            reportError(message: "\(String(describing: self)) \(String(describing: #function)) was not called on the main thread. Since calling it will render UI, it should be called on the main thread")
            return
        }
        
        self.mpAdView.adUnitId = self.mpAdUnitId
        self.mpAdView.loadAd()
    }
    
    
    //MARK: MAXAdRequestManagerDelegate
    // NOTE This class will hijack the MAXAdRequestManagerDelegate of the BannerController instance it owns to intercept BannerController.requestManager callbacks.
    
    public func onRequestSuccess(adResponse: MAXAdResponse?) {
        MAXLogger.debug("\(String(describing: self)).requestAd() succeeded for adUnit:\(String(describing: adResponse?.adUnitId))")
        
        guard adResponse != nil else {
            MAXLogger.debug("\(String(describing: self)).requestAd() succeeded but the ad response was nil")
            return
        }
        
        DispatchQueue.main.async {
            self.loadResponse(adResponse: adResponse!)
        }
    }
    
    public func onRequestFailed(error: NSError?) {
        MAXLogger.debug("\(String(describing: self)).requestAd() failed with error: \(String(describing: error?.localizedDescription)). Will try to load an ad from the MoPub SDK.")
        
        DispatchQueue.main.async {
            // Fall back on MoPub if MAX ad request fails
            self.loadVanillaMoPub()
        }
    }
    
    
    //MARK: MPAdViewDelegate
    // Called when a MoPub line item won in the MoPub waterfall
    
    public func viewControllerForPresentingModalView() -> UIViewController! {
        if let d = mpAdViewDelegate {
            return d.viewControllerForPresentingModalView()
        }
        return nil
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {

        // A banner loaded because a non-MAX line item in the MoPub waterfall was selected
        sessionManager.incrementSSPSessionDepth(adUnitId: view.adUnitId)
        
        startRefreshTimer(adResponse: adResponse)
        
        if let d = mpAdViewDelegate {
            d.adViewDidLoadAd?(view)
        }
    }
    
    public func adViewDidFail(toLoadAd view: MPAdView!) {
        
        startRefreshTimer(adResponse: adResponse)
        reportError(message: "\(String(describing: self)): MPAdViewDelegate - adViewDidFail")
    }
    
    public func willPresentModalView(forAd view: MPAdView!) {
        if let d = mpAdViewDelegate {
            d.willPresentModalView?(forAd: view)
        }
    }
    
    public func didDismissModalView(forAd view: MPAdView!) {
        if let d = mpAdViewDelegate {
            d.didDismissModalView?(forAd: view)
        }
    }
    
    public func willLeaveApplication(fromAd view: MPAdView!) {
        if let d = mpAdViewDelegate {
            d.willLeaveApplication?(fromAd: view)
        }
    }
    
    
    //MARK: MAXBannerAdViewDelegate
    // NOTE: These callbacks will only happen for MAX reserved ads
    
    public func onBannerLoaded(banner: MAXBannerAdView?) {
        if let d = maxBannerAdViewDelegate {
            d.onBannerLoaded(banner: banner)
        }
    }
    
    public func onBannerClicked(banner: MAXBannerAdView?) {
        if let d = maxBannerAdViewDelegate {
            d.onBannerClicked(banner: banner)
        }
    }
    
    public func onBannerError(banner: MAXBannerAdView?, error: MAXClientError) {
        reportError(message: error.message)
    }
    
    
    //MARK: Overrides
    
    public override var description: String {
        return "\(super.description)\n --- \nmpAdUnitId: \(String(describing: mpAdUnitId))\n adResponse: \(String(describing: adResponse))"
    }
    
    //MARK: Errors
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        
        guard let adR = adResponse else {
            return
        }
        
        if adR.isReserved {
            let error = MAXClientError(message: message)
            if let maxDelegate = maxBannerAdViewDelegate {
                maxDelegate.onBannerError(banner: bannerController.getBannerAdView(), error: error)
            }
        } else {
            if let mpDelegate = mpAdViewDelegate {
                mpDelegate.adViewDidFail?(toLoadAd: mpAdView)
            }
        }
    }
}
