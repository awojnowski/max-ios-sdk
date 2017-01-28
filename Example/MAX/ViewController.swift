//
//  ViewController.swift
//  MAX
//

import UIKit
import MAX
import MoPub

// MAX account: jim@molabs.com
//
let MAX_FULLSCREEN_ADUNIT_ID = "ag9zfm1heGFkcy0xNTY1MTlyEwsSBkFkVW5pdBiAgICA2uOGCgw"
let MAX_BANNER_ADUNIT_ID = "ag9zfm1heGFkcy0xNTY1MTlyEwsSBkFkVW5pdBiAgICAvKGCCQw"

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
    
    private var adManager : MAXAdRequestManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullScreenAdUnitTextField.text = MAX_FULLSCREEN_ADUNIT_ID
        self.bannerAdUnitTextField.text = MAX_BANNER_ADUNIT_ID
    }
    
    func monitorAdRequest() {
        self.adResponse = nil
        self.adError = nil
        self.interstitialController = nil
        
        // If banner refresh logic currently exists, stop it 
        self.adManager?.stopRefresh()
        self.adManager = nil

        // Clear output
        self.outputTextView.text = "Loading..."
        self.timeElapsedLabel.text = ""
        self.showInterstitialButton.isHidden = true
        for v in self.resultsView.subviews {
            if let adView = v as? MPAdView {
                adView.removeFromSuperview()
            }
        }

        
        // Start loading timer
        if #available(iOS 10.0, *) {
            let beginRequestDate = Date()
            Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true) { (timer) in
                if let r = self.adResponse {
                    timer.invalidate()
                    DispatchQueue.main.async(execute: {
                        self.timeElapsedLabel.text =
                            String.localizedStringWithFormat("%.3fs",
                                r.createdAt.timeIntervalSince(beginRequestDate))
                        self.outputTextView.text = "\(r.response!)"
                    })

                } else if let error = self.adError {
                    timer.invalidate()
                    DispatchQueue.main.async(execute: {
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
    
    func updateAdRequest(_ response: MAXAdResponse?, error: NSError?) {
        self.adResponse = response
        self.adError = error
    }
    
    // MARK: -- Pre-bid Fullscreen Interstitial
    
    @IBAction func tappedRequestFullScreenButton(_ sender: AnyObject) {
        guard let adUnitID = self.fullScreenAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()
        MAXAdRequest(adUnitID: adUnitID).requestAd() {(adResponse, error) in
            NSLog("adResponse: \(adResponse!)")
        }
    }
    
    @IBAction func tappedPreBidFullScreenButtonWithSender(_ sender: AnyObject) {
        guard let adUnitID = self.fullScreenAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()
        MAXAdRequest.preBidWithMAXAdUnit(adUnitID) {(response, error) in
            DispatchQueue.main.sync {
                self.updateAdRequest(response, error: error)

                // Requesting an ad normally here
                self.interstitialController = MPInterstitialAdController(forAdUnitId: MOPUB_FULLSCREEN_ADUNIT_ID)
                self.interstitialController!.keywords = response?.preBidKeywords ?? self.interstitialController!.keywords
                self.interstitialController!.loadAd()
                
                // Give the user a button to click
                self.showInterstitialButton.isHidden = false
            }
        }
    }
    
    @IBAction func tappedShowAdButtonWithSender(_ sender: AnyObject) {
        if let ic = self.interstitialController {
            if ic.ready {
                ic.show(from: self)
                self.interstitialController = nil
            }
        }
    }
    
    // MARK: -- Pre-bid banners
    
    @IBAction func tappedPreBidBannerButtonWithSender(_ sender: AnyObject) {
        guard let adUnitID = self.bannerAdUnitTextField.text else {
            return
        }
        
        self.monitorAdRequest()

        // 1) Add the static banner view here as usual ...
        guard let banner = MPAdView(adUnitId: MOPUB_BANNER_ADUNIT_ID, size: CGSize(width: 320, height: 50)) else {
            return
        }
        banner.frame = CGRect(origin: CGPoint.zero, size: banner.adContentViewSize())
        banner.delegate = self
        self.resultsView.addSubview(banner)
        
        // 2) Then use MAX to autorefresh periodically after prebid has completed
        // NOTE: this overrides the standard auto-refresh logic, so we disable auto-refresh here.
        banner.stopAutomaticallyRefreshingContents()
        self.adManager = MAXAdRequestManager(adUnitID: adUnitID) {(response, error) in
            DispatchQueue.main.sync {
                self.updateAdRequest(response, error: error)
                
                // Update the banner view's keywords and reload
                banner.keywords = response?.preBidKeywords ?? banner.keywords
                banner.loadAd()
            }
        }
        adManager?.startRefresh()

    }
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        return self
    }
    
}

