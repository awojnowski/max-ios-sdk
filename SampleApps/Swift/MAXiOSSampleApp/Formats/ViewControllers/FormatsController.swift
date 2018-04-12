import UIKit
import MoPub
import MAX

class FormatsController: BaseViewController, MPAdViewDelegate, MAXBannerAdViewDelegate,  MPInterstitialAdControllerDelegate, MAXInterstitialAdDelegate {
    
    private var interstitialAdUnitTextField: UITextField!
    private var bannerAdUnitTextField: UITextField!
    private var mrectAdUnitTextField: UITextField!
    private var loadInterstitialButton : UIButton!
    private var loadBannerButton : UIButton!
    private var loadMRectButton : UIButton!
    private var resultsView : UIView!
    private var showInterstitialButton : UIButton!
    private var timeElapsedLabel: UILabel!

    private var adError: NSError?
    private var maxMoPubInterstitial: MAXMoPubInterstitial?
    private var maxMoPubBanner: MAXMoPubBanner?
    private var locationManager: CLLocationManager?
    private var loadingComplete = false
    
    private let bannerAd = AdInfo(maxId: "ag9zfm1heGFkcy0xNTY1MTlyEwsSBkFkVW5pdBiAgICAvKGCCQw", mopubId:  "75fac5e613f54ae5b3087f18becaf395", size: CGSize(width: 320, height: 50))
    private let mRectAd = AdInfo(maxId:"olejRw96yej", mopubId: "8ec1244b60d64917b9304c1dbbdf7814", size: CGSize(width: 300, height: 250))
    private let interstitialAd = AdInfo(maxId:"olej28v2vej", mopubId:  "afa7b8256ba841edbb7d10c43d3614e2", size: CGSize(width: 0, height: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interstitialAdUnitTextField.text = interstitialAd.maxId
        bannerAdUnitTextField.text = bannerAd.maxId
        mrectAdUnitTextField.text = mRectAd.maxId
        
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        MAXLogger.setLogLevelDebug()
        MAXConfiguration.shared.enableLocationTracking()
        MAXConfiguration.shared.initializeFacebookIntegration()
//        MAXConfiguration.shared.initializeVungleSDK(appId: "5ab569a2b87c80213861cc67", placementIds: ["DEFAULT-4333142"], enableLogging: true)
    }
    
    override func setupViews() {
        super.setupViews()
        
        navigationController?.isNavigationBarHidden = true
        
        // create views
        
        let size = CGSize(width: 320, height: 50)
        let mpBanner = MPAdView(adUnitId: "some_ad_id", size: size)
        maxMoPubBanner = MAXMoPubBanner(mpAdView: mpBanner!)
        maxMoPubBanner?.mpAdViewDelegate = self
        maxMoPubBanner?.maxBannerAdViewDelegate = self
        view.addSubview(maxMoPubBanner!)
        
        bannerAdUnitTextField = UITextField()
        view.addSubview(bannerAdUnitTextField)
        
        mrectAdUnitTextField = UITextField()
        view.addSubview(mrectAdUnitTextField)
        
        interstitialAdUnitTextField = UITextField()
        view.addSubview(interstitialAdUnitTextField)
        
        loadBannerButton = UIButton()
        loadBannerButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        loadBannerButton.setTitle("Load Banner", for: UIControlState.normal)
        loadBannerButton.contentHorizontalAlignment = .right
        loadBannerButton.addTarget(self, action: #selector(tappedPreBidBannerButtonWithSender(_:)), for: .touchUpInside)
        view.addSubview(loadBannerButton)
        
        loadMRectButton = UIButton()
        loadMRectButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        loadMRectButton.setTitle("Load MRect", for: UIControlState.normal)
        loadMRectButton.contentHorizontalAlignment = .right
        loadMRectButton.addTarget(self, action: #selector(tappedPreBidMRectButtonWithSender(_:)), for: .touchUpInside)
        view.addSubview(loadMRectButton)
        
        loadInterstitialButton = UIButton()
        loadInterstitialButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        loadInterstitialButton.setTitle("Load Interstitial", for: UIControlState.normal)
        loadInterstitialButton.contentHorizontalAlignment = .right
        loadInterstitialButton.addTarget(self, action: #selector(tappedPreBidInterstitialButtonWithSender(_:)), for: .touchUpInside)
        view.addSubview(loadInterstitialButton)
        
        timeElapsedLabel = UILabel()
        timeElapsedLabel.textColor = UIColor.darkGray
        timeElapsedLabel.textAlignment = NSTextAlignment.center
        view.addSubview(timeElapsedLabel)
        
        showInterstitialButton = UIButton()
        showInterstitialButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        showInterstitialButton.setTitle("Show Interstitial", for: UIControlState.normal)
        showInterstitialButton.contentHorizontalAlignment = .center
        showInterstitialButton.isHidden = true
        showInterstitialButton.addTarget(self, action: #selector(tappedShowAdButtonWithSender(_:)), for: .touchUpInside)
        view.addSubview(showInterstitialButton)
        
        resultsView = UIView()
        view.addSubview(resultsView)
        
        // add constraints
        
        bannerAdUnitTextField.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.left.equalTo(view.snp.left).offset(15)
            make.top.equalTo(view.snp.top).offset(40)
            make.height.equalTo(60)
        }
    
        mrectAdUnitTextField.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.left.equalTo(view.snp.left).offset(15)
            make.top.equalTo(bannerAdUnitTextField.snp.bottom).offset(15)
            make.height.equalTo(60)
        }
        
        interstitialAdUnitTextField.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.left.equalTo(view.snp.left).offset(15)
            make.top.equalTo(mrectAdUnitTextField.snp.bottom).offset(15)
            make.height.equalTo(60)
        }
        
        loadBannerButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.right.equalTo(view.snp.right).offset(-15)
            make.top.equalTo(view.snp.top).offset(40)
            make.height.equalTo(60)
        }
        
        loadMRectButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.right.equalTo(view.snp.right).offset(-15)
            make.top.equalTo(loadBannerButton.snp.bottom).offset(15)
            make.height.equalTo(60)
        }
        
        loadInterstitialButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.4)
            make.right.equalTo(view.snp.right).offset(-15)
            make.top.equalTo(loadMRectButton.snp.bottom).offset(15)
            make.height.equalTo(60)
        }
        
        timeElapsedLabel.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(200)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(showInterstitialButton.snp.top)
            make.height.equalTo(60)
        }
        
        showInterstitialButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(200)
            make.centerX.equalTo(view.snp.centerX)
            make.bottom.equalTo(resultsView.snp.top)
            make.height.equalTo(60)
        }
        
        resultsView.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(view.snp.width).multipliedBy(0.9)
            make.height.equalTo(view.snp.height).multipliedBy(0.5)
            make.bottom.equalTo(view.snp.bottom).offset(20)
            make.centerX.equalTo(view.snp.centerX)
        }
        
        maxMoPubBanner?.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(bannerAd.size.width)
            make.height.equalTo(bannerAd.size.height)
            make.top.equalTo(resultsView.snp.top)
            make.centerX.equalTo(resultsView.snp.centerX)
        }
    }
    
    func monitorAdRequest() {
        loadingComplete = false
        adError = nil
        
        // Clear output
        timeElapsedLabel.text = ""
        showInterstitialButton.isHidden = true
        for v in resultsView.subviews {
            if let adView = v as? MPAdView {
                adView.removeFromSuperview()
            }
        }
        
        // Start loading timer
        if #available(iOS 10.0, *) {
            let beginRequestDate = Date()
            Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true) { (timer) in
                if self.loadingComplete {
                    timer.invalidate()
                    DispatchQueue.main.async(execute: {
                        self.timeElapsedLabel.text =
                            String.localizedStringWithFormat("%.3fs", Date().timeIntervalSince(beginRequestDate))
                    })
                    
                } else if let _ = self.adError {
                    timer.invalidate()
                    DispatchQueue.main.async(execute: {
                        self.timeElapsedLabel.text = "Ad response error"
                    })
                    
                } else {
                    self.timeElapsedLabel.text =
                        String.localizedStringWithFormat("%.3fs", -beginRequestDate.timeIntervalSinceNow)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    //MARK: Button actions
    
    @objc func tappedPreBidBannerButtonWithSender(_ sender: AnyObject) {
        print("\(FormatsController.self): load banner button pressed")
        
        monitorAdRequest()
        
        guard let adUnitID = bannerAdUnitTextField.text else {
            return
        }
        
        // NOTE: Each instance of MAXMoPubBanner may be reloaded for multiple sets of max and mopub adunit id's
        maxMoPubBanner?.load(maxAdUnitId: adUnitID, mpAdUnitId: bannerAd.mopubId)
    }
    
    @objc func tappedPreBidMRectButtonWithSender(_ sender: AnyObject) {
        print("\(FormatsController.self): load mrect button pressed")
        
        monitorAdRequest()
        
        guard let adUnitID = mrectAdUnitTextField.text else {
            return
        }
        
        // NOTE: Each instance of MAXMoPubBanner may be reloaded for multiple sets of max and mopub adunit id's
        maxMoPubBanner?.load(maxAdUnitId: adUnitID, mpAdUnitId: mRectAd.mopubId)
    }
    
    @objc func tappedPreBidInterstitialButtonWithSender(_ sender: AnyObject) {
        print("\(FormatsController.self): load interstitial button pressed")
        
        monitorAdRequest()
        
        guard let adUnitID = interstitialAdUnitTextField.text else {
            return
        }
        
        // Requesting an ad normally here
        guard let mpInterstitialController = MPInterstitialAdController(forAdUnitId: interstitialAd.mopubId) else {
            return
        }
        
        // NOTE: Each instance of MAXMoPubInterstitial may only be loaded for the ad unit id's it's initialized with. A new instance of MAXMoPubInterstitial needs to be instantiated in order for new ad unit id's to be loaded.
        maxMoPubInterstitial = MAXMoPubInterstitial(maxAdUnitId: adUnitID, mpInterstitial: mpInterstitialController, rootViewController: self)
        maxMoPubInterstitial?.mpInterstitialDelegate = self
        maxMoPubInterstitial?.maxInterstitialDelegate = self
        maxMoPubInterstitial?.load()
    }
    
    @objc func tappedShowAdButtonWithSender(_ sender: AnyObject) {
        print("\(FormatsController.self): show interstitial button pressed")
        maxMoPubInterstitial?.show()
        self.showInterstitialButton.isHidden = true
    }

    
    //MARK: MPAdViewDelegate
    // NOTE: Callbacks for banner creatives rendered by both MAX and MoPub will happen here
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return self
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {
        print("\(FormatsController.self): MAXMoPubBanner - MPAdViewDelegate - adViewDidLoadAd")
        loadingComplete = true
    }
    
    public func adViewDidFail(toLoadAd view: MPAdView!) {
        print("\(FormatsController.self): MAXMoPubBanner - MPAdViewDelegate - adViewDidFail")
        // No errors passed back from MoPub? Wtf bro??
        self.adError = NSError(domain:"", code:1, userInfo:[:])
    }
    
    public func willPresentModalView(forAd view: MPAdView!) {
        print("\(FormatsController.self): MAXMoPubBanner - MPAdViewDelegate - willPresentModalView")
    }
    
    public func didDismissModalView(forAd view: MPAdView!) {
        print("\(FormatsController.self): MAXMoPubBanner - MPAdViewDelegate - didDismissModalView")
    }
    
    public func willLeaveApplication(fromAd view: MPAdView!) {
        print("\(FormatsController.self): MAXMoPubBanner - MPAdViewDelegate - willLeaveApplication")
    }
    
    
    //MARK: MAXBannerAdViewDelegate
    // NOTE: These callbacks will only happen for MAX reserved ads
    
    public func onBannerLoaded(banner: MAXBannerAdView?) {
        print("\(FormatsController.self): MAXMoPubBanner - MAXBannerAdViewDelegate - onBannerLoaded")
        loadingComplete = true
    }
    
    public func onBannerClicked(banner: MAXBannerAdView?) {
        print("\(FormatsController.self): MAXMoPubBanner - MAXBannerAdViewDelegate - onBannerClicked")
    }
    
    public func onBannerError(banner: MAXBannerAdView?, error: MAXClientError) {
        print("\(FormatsController.self): MAXMoPubBanner - MAXBannerAdViewDelegate - onBannerError: \(String(describing: error.message))")
    }
    
    //MARK: MPInterstitialAdControllerDelegate
    
    public func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidLoadAd")
        loadingComplete = true
        showInterstitialButton.isHidden = false
    }
    
    public func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidFail")
        // No errors passed back from MoPub? Wtf bro??
        self.adError = NSError(domain:"", code:1, userInfo:[:])
    }
    
    public func interstitialWillAppear(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialWillAppear")
    }
    
    public func interstitialDidAppear(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidAppear")
    }
    
    public func interstitialWillDisappear(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialWillDisappear")
    }
    
    public func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidDisappear")
    }
    
    public func interstitialDidExpire(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidExpire")
    }
    
    public func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MPInterstitialAdController - interstitialDidReceiveTapEvent")
    }
    
    //MARK: MAXInterstitialAdDelegate
    //NOTE: Called only for reserved == true ad responses
    
    public func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MAXInterstitialAd - interstitialAdDidLoad")
        loadingComplete = true
        showInterstitialButton.isHidden = false
    }
    
    public func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MAXInterstitialAd - interstitialAdDidClick")
    }
    
    public func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MAXInterstitialAd - interstitialAdWillClose")
    }
    
    public func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MAXInterstitialAd - interstitialAdDidClose")
    }
    
    public func interstitial(_ interstitialAd: MAXInterstitialAd?, didFailWithError error: MAXClientError) {
        print("\(FormatsController.self): MAXMoPubInterstitial - MAXInterstitialAd - didFailWithError:\(String(describing: error.message))")
        self.adError = error
    }
}
