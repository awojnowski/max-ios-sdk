import UIKit
import MAX
 

class CreativeController: BaseViewController, MAXAdViewDelegate, MAXInterstitialAdDelegate {

    var showInterstitialButton : UIButton!
    var resultsView : UIView!
    
    var creative: Creative!
    var interstitialAd: MAXInterstitialAd!
    
    override func setupViews() {
        super.setupViews()
        
        view.backgroundColor = UIColor.white
        
        // create views
        
        showInterstitialButton = UIButton()
        showInterstitialButton.titleLabel?.textAlignment = NSTextAlignment.center
        showInterstitialButton.setTitleColor(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3), for: UIControlState.normal)
        showInterstitialButton.setTitle("Show Interstitial", for: UIControlState.normal)
        showInterstitialButton.addTarget(self, action: #selector(tappedShowAdButtonWithSender(_:)), for: .touchUpInside)
        view.addSubview(showInterstitialButton)
        
        resultsView = UITextField()
        view.addSubview(resultsView)

        // add constraints
        
        showInterstitialButton.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(200)
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(self.view.snp.top).offset(120)
            make.height.equalTo(50)
        }

        resultsView.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(self.view.snp.width).multipliedBy(0.9)
            make.height.equalTo(self.view.snp.height).multipliedBy(0.6)
            make.bottom.equalTo(self.view.snp.bottom).offset(40)
            make.centerX.equalTo(self.view.snp.centerX)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show creative in viewDidAppear so resultsView has been laid out (Not yet laid out in viewWillAppear)
        self.showCreative()
    }
    
    
    //MARK: Controller creative logic
    
    func showCreative() {
        print("Loading \(creative.name) (\(creative.format))")
        print(creative.adMarkup)
        
        switch creative.format {
        case "banner":
            let adViewSize = CGSize(width: UIScreen.main.bounds.width*0.8, height: 50)
            // Our API will be simpler if MAXAdView is not exposed to third parties. Unfortuntately MAXAdResponse's can't be injected directly into MAXBannerAdView's, which is what we need to have happen here..
            let adView = MAXAdView(adResponse: creative.response, size: adViewSize)
            let leftX = (resultsView.bounds.width - adViewSize.width)/2
            adView.frame = CGRect(origin: CGPoint(x: leftX, y: 0), size: adViewSize)
            adView.delegate = self
            adView.loadAd()
            resultsView.addSubview(adView)
        case "interstitial":
            let interstitial = MAXInterstitialAd()
            interstitial.delegate = self
            // Sneak the response into MAXInterstitialAd via RequestManager delegate. Likely these delegate methods should not be exposed. Do we want to allow pubs to inject their own ad responses to be shown as interstitials?
            interstitial.onRequestSuccess(adResponse: creative.response)
            interstitialAd = interstitial
        case "vast":
            let interstitial = MAXInterstitialAd()
            interstitial.delegate = self
            // Sneak the response into MAXInterstitialAd via RequestManager delegate. Likely these delegate methods should not be exposed. Do we want to allow pubs to inject their own ad responses to be shown as interstitials?
            interstitial.onRequestSuccess(adResponse: creative.response)
            interstitialAd = interstitial
        default:
            print("\(CreativeController.self) - Couldn't load ad with format: \(creative.format)")
        }
    }
    
    
    //MARK: Button actions
    
    @objc func tappedShowAdButtonWithSender(_ sender: AnyObject) {
        if let ic = interstitialAd {
            ic.showAdFromRootViewController(self)
        }
    }
    
    
    //MARK: MAXAdViewDelegate
    
    public func adViewDidLoad(_ adView: MAXAdView?) {
        print("\(CreativeController.self) - MAXAdViewDelegate - adViewDidLoad")
    }
    
    public func adViewDidFailWithError(_ adView: MAXAdView?, error: NSError?) {
        print("\(CreativeController.self) - MAXAdViewDelegate - adViewDidFailWithError: \(String(describing: error?.localizedDescription))")
    }
    
    public func adViewDidClick(_ adView: MAXAdView?) {
        print("\(CreativeController.self) - MAXAdViewDelegate - adViewDidClick")
    }
    
    public func adViewDidFinishHandlingClick(_ adView: MAXAdView?) {
        print("\(CreativeController.self) - MAXAdViewDelegate - adViewDidFinishHandlingClick")
    }
    
    public func adViewWillLogImpression(_ adView: MAXAdView?) {
        print("\(CreativeController.self) - MAXAdViewDelegate - adViewWillLogImpression")
    }
    
    public func viewControllerForMaxPresentingModalView() -> UIViewController? {
        return self
    }
   
    
    //MARK: MAXInterstitialAdDelegate
    
    func interstitialAdDidLoad(_ interstitialAd: MAXInterstitialAd) {
        print("\(CreativeController.self) - MAXInterstitialAdDelegate - interstitialAdDidLoad")
        showInterstitialButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
    }
    
    func interstitialAdDidClick(_ interstitialAd: MAXInterstitialAd) {
        print("\(CreativeController.self) - MAXInterstitialAdDelegate - interstitialAdDidClick")
    }
    
    func interstitialAdWillClose(_ interstitialAd: MAXInterstitialAd) {
        print("\(CreativeController.self) - MAXInterstitialAdDelegate - interstitialAdWillClose")
    }
    
    func interstitialAdDidClose(_ interstitialAd: MAXInterstitialAd) {
        print("\(CreativeController.self) - MAXInterstitialAdDelegate - interstitialAdDidClose")
    }
    
    func interstitial(_ interstitialAd: MAXInterstitialAd?, didFailWithError error: MAXClientError) {
        print("\(CreativeController.self) - MAXInterstitialAdDelegate - didFailWithError: \(error.message)")
    }
}
