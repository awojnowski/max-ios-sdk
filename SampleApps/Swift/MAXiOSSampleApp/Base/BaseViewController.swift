//
//  BaseViewController.swift
//  MAXiOSSampleApp
//
//  Created by Bryan Boyko on 1/23/18.
//  Copyright © 2018 MAXAds. All rights reserved.
//

import UIKit
import SnapKit

class BaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
    }
    
    func setupViews() {
        // Do view setup in subclasses
    }
}
