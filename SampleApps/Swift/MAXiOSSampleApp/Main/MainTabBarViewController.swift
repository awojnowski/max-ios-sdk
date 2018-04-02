//
//  MainTabBarViewController.swift
//  MAXiOSSampleApp
//
//  Created by Bryan Boyko on 1/23/18.
//  Copyright © 2018 MAXAds. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        
        // Add Controllers
        let formatsController = FormatsController()
        let formatsNavController = UINavigationController(rootViewController: formatsController)
        let loadAdsImage = UIImage(named: "first")
        formatsController.tabBarItem = UITabBarItem(title: "Load Ads", image: loadAdsImage, tag: 0)
        let creativesController = CreativesController()
        let creativesNavController = UINavigationController(rootViewController: creativesController)
        creativesNavController.navigationBar.tintColor = UIColor.gray
        creativesNavController.navigationBar.topItem?.title = "Creatives"
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.gray]
        let creativesImage = UIImage(named: "second")
        creativesController.tabBarItem = UITabBarItem(title: "Creatives", image: creativesImage, tag: 1)
        let tabBarList = [formatsNavController, creativesNavController]
        viewControllers = tabBarList
    }
    
}
