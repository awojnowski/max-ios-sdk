//
//  ViewController.swift
//  MAX
//
//  Created by Jim Payne on 10/05/2016.
//  Copyright (c) 2016 Jim Payne. All rights reserved.
//

import UIKit
import MAX

class ViewController: UIViewController, MAXAdRequestDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let adr = MAXAdRequest(placementID: "5637245446914048")
        adr.delegate = self
        adr.requestAd()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adRequestDidLoad(adRequest: MAXAdRequest) {
        NSLog("adRequestDidLoad(\(adRequest))")
    }
    
    func adRequestDidFailWithError(adRequest: MAXAdRequest, error: NSError) {
        NSLog("adRequestDidFailWithError(\(adRequest), \(error))")
    }

}

