//
//  ViewController.swift
//  MAX
//

import UIKit
import MAX

class ViewController: UIViewController {
    
    @IBOutlet private weak var adUnitTextField: UITextField!
    @IBOutlet private weak var outputTextView: UITextView!
    @IBOutlet private weak var timeElapsedLabel: UILabel!
    
    private var adResponse : MAXAdResponse?
    private var interstitialAd : MAXInterstitialAd?
    private var bannerAdView : MAXAdView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.adUnitTextField.text = "ahFzfm1vYmlsZXZpZGVvZmVlZHITCxIGQWRVbml0GICAgOO34YEKDA"
    }
    
    @IBAction func tappedRequestAdButton(sender: AnyObject) {
        self.adResponse = nil
        self.interstitialAd = nil
        
        // Do any additional setup after loading the view, typically from a nib.
        let adr = MAXAdRequest(adUnitID: self.adUnitTextField.text!)
        adr.requestAd() {(adResponse, error) in
            if let adResponse = adResponse {
                NSLog("adRequestDidLoad(\(adr))")
                self.adResponse = adResponse
                dispatch_async(dispatch_get_main_queue(), {
                    self.outputTextView.text = "\(adResponse.response)"
                })
            } else if let error = error {
                NSLog("adRequestDidFailWithError(\(adr), \(error))")
                dispatch_async(dispatch_get_main_queue(), {
                    self.outputTextView.text = "\(error.localizedDescription)"
                })
            }
        }
        
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
    
    @IBAction func tappedShowAdButton(sender: AnyObject) {
        if let adResponse = self.adResponse {
            let ad = MAXInterstitialAd(adResponse: adResponse)
            self.interstitialAd = ad
            ad.showAdFromRootViewController(self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

