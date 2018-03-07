import Foundation

/**
 * MAXSession tracks session information for the app. This includes the session depth,
 * which measures the number of ad requests that have been made since the app was opened.
 */
// TODO - Bryan: Consider if MAXSession should be internal or public
public class MAXSessionManager: NSObject {
    
    @objc public static let shared = MAXSessionManager()
    
    @objc public var session: MAXSession

    /// After the user spends `sessionExpirationIntervalSeconds` seconds outside of the app, the session will reset.
    /// Initially set to 30 seconds. This value can be reset from the server.
    internal var sessionExpirationIntervalSeconds = 30.0

    /// `leftAppTimestamp` will be recorded when the user leaves the app
    private var leftAppTimestamp: Date?
    private var enterForegroundObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var notificationCenter: NotificationCenter?
    
    
    //MARK: Methods

    @objc public init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        MAXLog.debug("MAXSession initialized")
        self.notificationCenter = notificationCenter
        self.session = MAXSession(sessionId: MAXSessionManager.generateSessionId())
        super.init()
        self.addObservers()
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
                MAXLog.debug("MAXSession won't reset since user came back to app within \(self.sessionExpirationIntervalSeconds) seconds")
            }
        }
        
        self.willResignActiveObserver = self.notificationCenter?.addObserver(
            forName: Notification.Name.UIApplicationWillResignActive,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            self.leftAppTimestamp = Date()
            MAXLog.debug("MAXSession recorded user leaving app at \(String(describing: self.leftAppTimestamp))")
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
    @objc public func incrementMaxSessionDepth(adUnitId: String) {
        MAXLog.debug("\(String(describing: self)) incrementMaxSessionDepth for adUnitId: <\(adUnitId)>")
        session.incrementMaxSessionDepth(adUnitId: adUnitId)
    }
    
    @objc public func incrementSSPSessionDepth(adUnitId: String) {
        MAXLog.debug("\(String(describing: self)) incrementSSPSessionDepth for adUnitId: <\(adUnitId)>")
        session.incrementSSPSessionDepth(adUnitId: adUnitId)
    }
    
    @objc func reset() {
        MAXLog.debug("\(String(describing: self)) reset session")
        session = MAXSession(sessionId: MAXSessionManager.generateSessionId())
    }
}
