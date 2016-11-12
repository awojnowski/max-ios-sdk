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
    @IBOutlet private weak var timeElapsedLabel: UILabel!

    @IBOutlet private weak var bannerAdUnitTextField: UITextField!
    @IBOutlet private weak var bannerAdView : UIView!

    @IBOutlet private weak var outputTextView: UITextView!
    
    private var adResponse : MAXAdResponse?
    private var adError : NSError?
    
    private var interstitialAd : MAXInterstitialAd?
    private var interstitialController : MPInterstitialAdController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullScreenAdUnitTextField.text = MAX_FULLSCREEN_ADUNIT_ID
        self.bannerAdUnitTextField.text = MAX_BANNER_ADUNIT_ID
    }
    
    func monitorAdRequest() {
        self.adResponse = nil
        self.adError = nil
        self.interstitialAd = nil
        self.interstitialController = nil

        // Clear output
        self.outputTextView.text = "Loading..."
        self.timeElapsedLabel.text = ""
        
        // Start loading timer
        if #available(iOS 10.0, *) {
            let beginRequestDate = NSDate()
            NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.1), repeats: true) { (timer) in
                if let r = self.adResponse {
                    timer.invalidate()
                    self.timeElapsedLabel.text =
                        String.localizedStringWithFormat("%.3f",
                                                         r.createdAt.timeIntervalSinceDate(beginRequestDate))
                    dispatch_async(dispatch_get_main_queue(), {
                        self.outputTextView.text = "\(r.response)"
                    })

                } else if let error = self.adError {
                    timer.invalidate()
                    self.timeElapsedLabel.text = ""
                    dispatch_async(dispatch_get_main_queue(), {
                        self.outputTextView.text = "\(error.localizedDescription)"
                    })

                } else {
                    self.timeElapsedLabel.text =
                        String.localizedStringWithFormat("%.3f",
                                                         -beginRequestDate.timeIntervalSinceNow)
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    // MARK: -- Pre-bid Fullscreen Interstitial
    
    @IBAction func tappedRequestFullScreenButton(sender: AnyObject) {
        self.monitorAdRequest()
        MAXAdRequest(adUnitID: self.fullScreenAdUnitTextField.text!).requestAd() {(adResponse, error) in
        }
    }
    
    @IBAction func tappedPreBidFullScreenButtonWithSender(sender: AnyObject) {
        self.monitorAdRequest()
        MAXAdRequest.preBidWithMAXAdUnit(self.fullScreenAdUnitTextField.text!) {(response, error) in
            dispatch_sync(dispatch_get_main_queue()) {
                if let response = response {
                    self.adResponse = response
                    
                    self.interstitialAd = MAXInterstitialAd(adResponse: response)
                    
                    self.interstitialController = MPInterstitialAdController(forAdUnitId: MOPUB_FULLSCREEN_ADUNIT_ID)
                    self.interstitialController!.keywords = response.preBidKeywords
                    self.interstitialController!.loadAd()
                } else if let error = error {
                    self.adError = error
                }
            }
        }
    }
    
    @IBAction func tappedShowAdButtonWithSender(sender: AnyObject) {
        if let ic = self.interstitialController {
            if ic.ready {
                ic.showFromViewController(self)
            }
        }
    }
    
    // MARK: -- Pre-bid banners
    
    @IBAction func tappedPreBidBannerButtonWithSender(sender: AnyObject) {
        
        self.monitorAdRequest()
        MAXAdRequest.preBidWithMAXAdUnit(self.bannerAdUnitTextField.text!) {(response, error) in
            
            dispatch_sync(dispatch_get_main_queue()) {
                if let response = response {
                    self.adResponse = response
                    
                    let banner = MPAdView(adUnitId: MOPUB_BANNER_ADUNIT_ID, size: CGSizeMake(320, 50))
                    banner.frame = CGRect(origin: CGPointZero, size: banner.adContentViewSize())
                    banner.delegate = self
                    banner.keywords = response.preBidKeywords
                    banner.loadAd()
                    
                    self.bannerAdView.addSubview(banner)
                } else if let error = error {
                    self.adError = error
                }
            }
        }

    }
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return self
    }
    

}

