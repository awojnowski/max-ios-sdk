import Foundation

/**
 * MAXSession tracks session information for the app. This includes the session depth,
 * which measures the number of ad requests that have been made since the app was opened.
 */
class MAXSession {

    static let shared = MAXSession()
    
    /// After the user spends `sessionExpirationIntervalSeconds` seconds outside of the app, the session will reset.
    /// Initially set to 30 seconds. This value can be reset from the server.
    var sessionExpirationIntervalSeconds = 30.0
    
    /// `leftAppTimestamp` will be recorded when the user leaves the app
    private var leftAppTimestamp: Date?

    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        MAXLog.debug("MAXSession initialized")

        notificationCenter.addObserver(
            forName: Notification.Name.UIApplicationWillEnterForeground,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            if (self.isExpired) {
                self.resetDepth()
            } else {
                MAXLog.debug("MAXSession won't reset since user came back to app within \(self.sessionExpirationIntervalSeconds) seconds")
            }
        }

        notificationCenter.addObserver(
            forName: Notification.Name.UIApplicationWillResignActive,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            self.leftAppTimestamp = Date()
            MAXLog.debug("MAXSession recorded user leaving app at \(String(describing: self.leftAppTimestamp))")
        }
    }
    
    private var isExpired: Bool {
        get {
            if let timestamp = leftAppTimestamp {
                return abs(timestamp.timeIntervalSinceNow) > self.sessionExpirationIntervalSeconds
            }
            return true
        }
    }

    private var _sessionDepth = 0
    
    /// Session depth starts at 0 and is incremented after every ad request is fired, regardless of
    /// whether a response is received. The first ad request in the session should report a session
    /// depth of 0.
    public var sessionDepth: Int {
        get {
            return self._sessionDepth
        }
    }

    func incrementDepth() {
        MAXLog.debug("MAXSession.incrementDepth")
        self._sessionDepth += 1
    }

    @objc
    func resetDepth() {
        MAXLog.debug("MAXSession.resetDepth")
        self._sessionDepth = 0
    }
}
