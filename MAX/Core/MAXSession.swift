//
//  MAXSession.swift
//  MAX
//
//  Created by Bryan Boyko on 2/27/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

internal class MAXSession {
    
    internal var scores = [String : MAXAdUnitScore]()
    internal var sessionId: String
    
    internal init(sessionId: String) {
        self.sessionId = sessionId
    }
    
    internal var dict: Dictionary<String, Any> {
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
    
    internal var description: String {
        return "SessionId: \(sessionId)\n Scores: \(scores)"
    }
}
