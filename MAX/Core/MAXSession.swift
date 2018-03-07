//
//  MAXSession.swift
//  MAX
//
//  Created by Bryan Boyko on 2/27/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

// TODO - Bryan: Consider making either/both and all/some MAXSession and MAXAdUnitScore internal. It may be more harm than help to have these classes avialable to third parties.

public class MAXSession: NSObject {
    
    @objc public internal(set) var scores = [String : MAXAdUnitScore]()
    @objc public internal(set) var sessionId: String
    
    internal init(sessionId: String) {
        self.sessionId = sessionId
        super.init()
    }
    
    @objc public func incrementMaxSessionDepth(adUnitId: String) {
        var score = scores[adUnitId]
        if score == nil {
            score = MAXAdUnitScore(adUnitId: adUnitId)
            scores[adUnitId] = score
        }
        score!.maxSessionDepth = NSNumber(value: score!.maxSessionDepth.intValue + 1)
    }
    
    @objc public func incrementSSPSessionDepth(adUnitId: String) {
        var score = scores[adUnitId]
        if score == nil {
            score = MAXAdUnitScore(adUnitId: adUnitId)
            scores[adUnitId] = score
        }
        score!.sspSessionDepth = NSNumber(value: score!.sspSessionDepth.intValue + 1)
    }
    
    @objc public func combinedDepthForAd(adUnitId: String) -> NSNumber {
        let maxScore = scores[adUnitId]?.maxSessionDepth ?? 0
        let sspScore = scores[adUnitId]?.sspSessionDepth ?? 0
        return NSNumber(value: maxScore.intValue + sspScore.intValue)
    }
    
    @objc public func combinedDepthForAllAds() -> NSNumber {
        var totalScore = 0
        for (_, adUnitScore) in scores {
            totalScore += adUnitScore.maxSessionDepth.intValue
            totalScore += adUnitScore.sspSessionDepth.intValue
        }
        return NSNumber(value: totalScore)
    }
    
    @objc public var dict: Dictionary<String, Any> {
        let d: Dictionary<String, Any> = [
            "id" : sessionId,
            "scores" : scoresDict
        ]
        return d
    }
    
    private var scoresDict: [String: Dictionary<String, Any>] {
        var scoresDict = [String: Dictionary<String, Any>]()
        for (adUnitId, adUnitScore) in scores {
            scoresDict[adUnitId] = adUnitScore.dict
        }
        return scoresDict
    }
    
    
    //MARK: Overrides
    
    public override var description: String {
        return "SessionId: \(sessionId)\n Scores: \(scores)"
    }
}
