import Foundation

/**
 * MAXSession tracks session information for the app. This includes the session depth,
 * which measures the number of ad requests that have been made since the app was opened.
 */

public class MAXSessionManager: NSObject {
    
    @objc public static let shared = MAXSessionManager()
    
    internal var session: MAXSession

    /// After the user spends `sessionExpirationIntervalSeconds` seconds outside of the app, the session will reset.
    /// Initially set to 30 seconds. This value can be reset from the server.
    internal var sessionExpirationIntervalSeconds = 30.0
    
    // If an adUnitId is nil, we still increment the session depth
    internal let nilAdUnitIdKey = "WARNING: adUnitId is nil!"

    /// `leftAppTimestamp` will be recorded when the user leaves the app
    private var leftAppTimestamp: Date?
    private var enterForegroundObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var notificationCenter: NotificationCenter?
    
    
    //MARK: Methods

    @objc public init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.session = MAXSession(sessionId: MAXSessionManager.generateSessionId())
        super.init()
        self.addObservers()
        MAXLog.debug("\(String(describing: self)): session initialized")
    }
    
    private func addObservers() {
        
        self.enterForegroundObserver = self.notificationCenter?.addObserver(
            forName: Notification.Name.UIApplicationWillEnterForeground,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            if self.isExpired {
                self.reset()
            } else {
                MAXLog.debug("\(String(describing: self)): won't reset since user came back to app within \(self.sessionExpirationIntervalSeconds) seconds")
            }
        }
        
        self.willResignActiveObserver = self.notificationCenter?.addObserver(
            forName: Notification.Name.UIApplicationWillResignActive,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            self.leftAppTimestamp = Date()
            MAXLog.debug("\(String(describing: self)): recorded user leaving app at \(String(describing: self.leftAppTimestamp))")
        }
    }

    private var isExpired: Bool {
        if let timestamp = leftAppTimestamp {
            return abs(timestamp.timeIntervalSinceNow) > self.sessionExpirationIntervalSeconds
        }
        return true
    }

    private static func generateSessionId() -> String {
        let uuid = UUID().uuidString
        return uuid
    }
    
    //MARK session depth logic
    
    
    /// All session depths start at 0 and are incremented after an impression in the view layer.
    /// MAX tracks three different session depths:
    /// 1. MAX's own count of impressions, which is incremented each time an impression is tracked
    ///    by a MAX view
    /// 2. MAX's count of impressions that have been tracked by an SSP
    ///
    /// The first ad request in the session should report a session depth of 0. All session depths
    /// are reset at the same time.
    @objc public func incrementMaxSessionDepth(adUnitId: String?) {
        
        let id = adUnitId ?? nilAdUnitIdKey
        MAXLog.debug("\(String(describing: self)) incrementMaxSessionDepth for adUnitId: <\(id)>")
        
        if id == nilAdUnitIdKey {
            MAXLog.warn("\(String(describing: self)) incrementMaxSessionDepth for nil ad unit id")
        }
        
        var score = session.scores[id]
        if score == nil {
            score = MAXAdUnitScore(adUnitId: id)
            session.scores[id] = score
        }
        score!.maxSessionDepth = NSNumber(value: score!.maxSessionDepth.intValue + 1)
    }
    
    @objc public func incrementSSPSessionDepth(adUnitId: String?) {
        
        let id = adUnitId ?? nilAdUnitIdKey
        MAXLog.debug("\(String(describing: self)) incrementSSPSessionDepth for adUnitId: <\(id)>")
        
        if id == nilAdUnitIdKey {
            MAXLog.warn("\(String(describing: self)) incrementMaxSessionDepth for nil ad unit id")
        }
        
        var score = session.scores[id]
        if score == nil {
            score = MAXAdUnitScore(adUnitId: id)
            session.scores[id] = score
        }
        score!.sspSessionDepth = NSNumber(value: score!.sspSessionDepth.intValue + 1)
    }
    
    @objc public func sspDepthForAd(adUnitId: String) -> NSNumber {
        return session.scores[adUnitId]?.sspSessionDepth ?? 0
    }
    
    @objc public func maxDepthForAd(adUnitId: String) -> NSNumber {
        return session.scores[adUnitId]?.maxSessionDepth ?? 0
    }
    
    @objc public func combinedDepthForAd(adUnitId: String) -> NSNumber {
        let maxScore = session.scores[adUnitId]?.maxSessionDepth ?? 0
        let sspScore = session.scores[adUnitId]?.sspSessionDepth ?? 0
        return NSNumber(value: maxScore.intValue + sspScore.intValue)
    }
    
    @objc public func sspDepthForAllAds() -> NSNumber {
        var totalScore = 0
        for (_, adUnitScore) in session.scores {
            totalScore += adUnitScore.sspSessionDepth.intValue
        }
        return NSNumber(value: totalScore)
    }
    
    @objc public func maxDepthForAllAds() -> NSNumber {
        var totalScore = 0
        for (_, adUnitScore) in session.scores {
            totalScore += adUnitScore.maxSessionDepth.intValue
        }
        return NSNumber(value: totalScore)
    }
    
    @objc public func combinedDepthForAllAds() -> NSNumber {
        var totalScore = 0
        for (_, adUnitScore) in session.scores {
            totalScore += adUnitScore.maxSessionDepth.intValue
            totalScore += adUnitScore.sspSessionDepth.intValue
        }
        return NSNumber(value: totalScore)
    }
    
    @objc func reset() {
        MAXLog.debug("\(String(describing: self)) reset session")
        session = MAXSession(sessionId: MAXSessionManager.generateSessionId())
    }
}
