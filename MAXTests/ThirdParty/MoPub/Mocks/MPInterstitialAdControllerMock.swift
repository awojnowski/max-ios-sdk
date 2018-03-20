//
//  MPInterstitialAdControllerMock.swift
//  MAXTests
//
//  Created by Bryan Boyko on 3/9/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import MoPub

internal class MPInterstitialAdControllerSwizzleMock: NSObject {
    
    // Some MPInterstitialAdController methods have been swizzled with methods from this class. Since MPInterstialAdController can't be subclassed and mocked due to it having a static initializer, secretAgent is injected into methods in place of a proper mock.
    private static var secretAgent = MPInterstitialAdController(forAdUnitId: "")
    
    // We would only like to swizzle once. Swizzling will set static variables, so lets do it before its possible for an external source to set the variables.
    private static var swizzled = false
    
    internal static var loaded = false
    internal static var shown = false
    
    internal init(secretAgent: MPInterstitialAdController) {
        MPInterstitialAdControllerSwizzleMock.swizzle()
        MPInterstitialAdControllerSwizzleMock.secretAgent = secretAgent
        super.init()
    }
    
    internal static func swizzle() {
        if MPInterstitialAdControllerSwizzleMock.swizzled == false {
            MPInterstitialAdControllerSwizzleMock.swizzled = true
            _ = MPInterstitialAdControllerSwizzleMock.swizzleLoad
            _ = MPInterstitialAdControllerSwizzleMock.swizzleShow
        }
    }
    
    @objc internal func myLoadAd() {
        // For some reason accessing 'self' inside a swizzled method causes a bad access crash. Make state static as a workaround..
        MPInterstitialAdControllerSwizzleMock.loaded = true
        // Bypass ordinary MoPub logic to get delegate functionality
        MPInterstitialAdControllerSwizzleMock.secretAgent?.delegate?.interstitialDidLoadAd?(MPInterstitialAdControllerSwizzleMock.secretAgent)
    }
    
    @objc internal func myShow(from controller: UIViewController!) {
        // For some reason accessing 'self' inside a swizzled method causes a bad access crash. Make state static as a workaround..
        MPInterstitialAdControllerSwizzleMock.shown = true
        // Bypass ordinary MoPub logic to get delegate functionality
        MPInterstitialAdControllerSwizzleMock.secretAgent?.delegate?.interstitialWillAppear?(MPInterstitialAdControllerSwizzleMock.secretAgent)
    }
    
    
    //MARK: Swizzlers
    
    //TODO - Bryan: Can't figure out how to fix below warnings
    // make static so swizzle can only happen once
    private static let swizzleLoad: Void = {
        let instance = MPInterstitialAdController(forAdUnitId: "whatever")
        let mpControllerClass: AnyClass! = object_getClass(instance)
        let myInstance = MPInterstitialAdControllerSwizzleMock(secretAgent: instance!)
        let myClass: AnyClass! = object_getClass(myInstance)
        let originalMethod = class_getInstanceMethod(mpControllerClass, #selector(MPInterstitialAdController.loadAd))
        let swizzledMethod = class_getInstanceMethod(myClass, #selector(MPInterstitialAdControllerSwizzleMock.myLoadAd))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()

    // make static so swizzle can only happen once
    private static let swizzleShow: Void = {
        let instance = MPInterstitialAdController(forAdUnitId: "whatever")
        let mpControllerClass: AnyClass! = object_getClass(instance)
        let myInstance = MPInterstitialAdControllerSwizzleMock(secretAgent: instance!)
        let myClass: AnyClass! = object_getClass(myInstance)
        let originalMethod = class_getInstanceMethod(mpControllerClass, #selector(MPInterstitialAdController.show(from:)))
        let swizzledMethod = class_getInstanceMethod(myClass, #selector(MPInterstitialAdControllerSwizzleMock.myShow(from:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
}
