//
//  ViewController.swift
//  MAX
//

import UIKit
import MAX
import MoPub

// MAX account: jim@molabs.com
//
let MAX_FULLSCREEN_ADUNIT_ID = "ahFzfm1vYmlsZXZpZGVvZmVlZHITCxIGQWRVbml0GICAgIe30IwKDA"
let MAX_BANNER_ADUNIT_ID = "ahFzfm1vYmlsZXZpZGVvZmVlZHITCxIGQWRVbml0GICAgOO34YEKDA"

// MoPub account: muyexcellente@mailinator.com
//
let MOPUB_FULLSCREEN_ADUNIT_ID = "9033f69dca454f1fadb7f59ef0a24562"
let MOPUB_BANNER_ADUNIT_ID = "92cfc1c922f9490c8d7badf62ac8b33f"

class ViewController: UIViewController, MPAdViewDelegate {
    
    @IBOutlet private weak var fullScreenAdUnitTextField: UITextField!
    @IBOutlet private weak var bannerAdUnitTextField: UITextField!
    
    @IBOutlet private weak var resultsView : UIView!
    @IBOutlet private weak var showInterstitialButton : UIButton!

    @IBOutlet private weak var timeElapsedLabel: UILabel!
    @IBOutlet private weak var outputTextView: UITextView!
    
    private var adResponse : MAXAdResponse?
    private var adError : NSError?
    
    private var interstitialController : MPInterstitialAdController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullScreenAdUnitTextField.text = MAX_FULLSCREEN_ADUNIT_ID
        self.bannerAdUnitTextField.text = MAX_BANNER_ADUNIT_ID
    }
    
    func monitorAdRequest() {
        self.adResponse = nil
        self.adError = nil
        self.interstitialController = nil

        // Clear output
        self.outputTextView.text = "Loading..."
        self.timeElapsedLabel.text = ""
        self.showInterstitialButton.hidden = true
        for v in self.resultsView.subviews {
            if let adView = v as? MPAdView {
                adView.removeFromSuperview()
            }
        }

        
        // Start loading timer
        if #available(iOS 10.0, *) {
            let beginRequestDate = NSDate()
            NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.1), repeats: true) { (timer) in
                if let r = self.adResponse {
                    timer.invalidate()
                    dispatch_async(dispatch_get_main_queue(), {
                        self.timeElapsedLabel.text =
                            String.localizedStringWithFormat("%.3fs // %d bytes",
                                r.createdAt.timeIntervalSinceDate(beginRequestDate),
                                r.data.length)
                        self.outputTextView.text = "\(r.response)"
                    })

                } else if let error = self.adError {
                    timer.invalidate()
                    dispatch_async(dispatch_get_main_queue(), {
                        self.timeElapsedLabel.text = ""
                        self.outputTextView.text = "\(error.localizedDescription)"
                    })

                } else {
                    self.timeElapsedLabel.text =
                        String.localizedStringWithFormat("%.3fs",
                                                         -beginRequestDate.timeIntervalSinceNow)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func updateAdRequest(response: MAXAdResponse?, error: NSError?) {
        self.adResponse = response
        self.adError = error
    }
    
    // MARK: -- Pre-bid Fullscreen Interstitial
    
    @IBAction func tappedRequestFullScreenButton(sender: AnyObject) {
        guard let adUnitID = self.fullScreenAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()
        MAXAdRequest(adUnitID: adUnitID).requestAd() {(adResponse, error) in
            NSLog("adResponse: \(adResponse)")
        }
    }
    
    @IBAction func tappedPreBidFullScreenButtonWithSender(sender: AnyObject) {
        guard let adUnitID = self.fullScreenAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()
        MAXAdRequest.preBidWithMAXAdUnit(adUnitID) {(response, error) in
            dispatch_sync(dispatch_get_main_queue()) {
                self.updateAdRequest(response, error: error)

                // Requesting an ad normally here
                self.interstitialController = MPInterstitialAdController(forAdUnitId: MOPUB_FULLSCREEN_ADUNIT_ID)
                self.interstitialController!.keywords = response?.preBidKeywords ?? self.interstitialController!.keywords
                self.interstitialController!.loadAd()
            }
        }
    }
    
    @IBAction func tappedShowAdButtonWithSender(sender: AnyObject) {
        if let ic = self.interstitialController {
            if ic.ready {
                ic.showFromViewController(self)
                self.interstitialController = nil
            }
        }
    }
    
    // MARK: -- Pre-bid banners
    
    @IBAction func tappedPreBidBannerButtonWithSender(sender: AnyObject) {
        guard let adUnitID = self.bannerAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()

        // 1) Add the static banner view here as usual ...
        let banner = MPAdView(adUnitId: MOPUB_BANNER_ADUNIT_ID, size: CGSizeMake(320, 50))
        banner.frame = CGRect(origin: CGPointZero, size: banner.adContentViewSize())
        banner.delegate = self
        self.resultsView.addSubview(banner)
        
        // 2) Then use MAX to autorefresh periodically after prebid has completed
        banner.stopAutomaticallyRefreshingContents()
        let adManager = MAXAdRequestManager(adUnitID: adUnitID) {(response, error) in
            dispatch_sync(dispatch_get_main_queue()) {
                self.updateAdRequest(response, error: error)
                
                // Update the banner view's keywords and reload
                banner.keywords = response?.preBidKeywords ?? banner.keywords
                banner.loadAd()
            }
        }
        adManager.startRefresh()

    }
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return self
    }
    
}

