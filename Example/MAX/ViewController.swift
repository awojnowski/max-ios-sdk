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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.adUnitTextField.text = "5637245446914048"
    }
    
    @IBAction func tappedRequestAdButton(sender: AnyObject) {
        // Do any additional setup after loading the view, typically from a nib.
        let adr = MAXAdRequest(adUnitID: self.adUnitTextField.text!)
        adr.delegate = self
        adr.requestAd()
        
    }
    
    @IBAction func tappedShowAdButton(sender: AnyObject) {
        let ad = MAXInterstitialAd(adResponse: self.adResponse)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adRequestDidLoad(adRequest: MAXAdRequest) {
        NSLog("adRequestDidLoad(\(adRequest))")
        self.adResponse = adRequest.adResponse
        dispatch_async(dispatch_get_main_queue(), {
            self.outputTextView.text = "\(self.adResponse?.response)"
        })
    }
    
    func adRequestDidFailWithError(adRequest: MAXAdRequest, error: NSError) {
        NSLog("adRequestDidFailWithError(\(adRequest), \(error))")
        dispatch_async(dispatch_get_main_queue(), {
            self.outputTextView.text = "\(error.localizedDescription)"
        })
    }

}

