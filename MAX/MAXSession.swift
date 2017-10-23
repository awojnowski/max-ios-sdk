import Foundation

/**
 * MAXSession tracks session information for the app. This includes the session depth,
 * which measures the number of ad requests that have been made since the app was opened.
 */
class MAXSession {

    static let shared = MAXSession()

    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        MAXLog.debug("MAXSession initialized")

        notificationCenter.addObserver(forName: Notification.Name.UIApplicationWillEnterForeground, object: nil, queue: OperationQueue.main) {
            notification in self.resetDepth()
        }

        notificationCenter.addObserver(forName: Notification.Name.UIApplicationWillResignActive, object: nil, queue: OperationQueue.main) {
            notification in self.resetDepth()
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
