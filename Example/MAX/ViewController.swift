//
//  ViewController.swift
//  MAX
//
//  Copyright (c) 2016 Jim Payne. All rights reserved.
//

import UIKit
import MAX

class ViewController: UIViewController, MAXAdRequestDelegate {
    
    @IBOutlet private weak var adUnitTextField: UITextField!
    @IBOutlet private weak var outputTextView: UITextView!
    
    private var adResponse : MAXAdResponse?
    private var interstitialAd : MAXInterstitialAd?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.adUnitTextField.text = "5637245446914048"
    }
    
    @IBAction func tappedRequestAdButton(sender: AnyObject) {
        // Do any additional setup after loading the view, typically from a nib.
        let adr = MAXAdRequest(adUnitID: self.adUnitTextField.text!)
        adr.delegate = self
        adr.requestAd()
        
        // Clear output
        self.outputTextView.text = "Loading..."
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
    
    func adRequestDidLoad(adRequest: MAXAdRequest) {
        NSLog("adRequestDidLoad(\(adRequest))")
        self.adResponse = adRequest.adResponse
        dispatch_async(dispatch_get_main_queue(), {
            if let adResponse = self.adResponse {
                self.outputTextView.text = "\(adResponse.response)"
            }
        })
    }
    
    func adRequestDidFailWithError(adRequest: MAXAdRequest, error: NSError) {
        NSLog("adRequestDidFailWithError(\(adRequest), \(error))")
        dispatch_async(dispatch_get_main_queue(), {
            self.outputTextView.text = "\(error.localizedDescription)"
        })
    }

}

