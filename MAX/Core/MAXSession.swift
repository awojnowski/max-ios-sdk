import Foundation

/**
 * MAXSession tracks session information for the app. This includes the session depth,
 * which measures the number of ad requests that have been made since the app was opened.
 */
// TODO - Bryan: Consider if MAXSession should be internal or public
public class MAXSession: NSObject {

    public static let shared = MAXSession()

    /// After the user spends `sessionExpirationIntervalSeconds` seconds outside of the app, the session will reset.
    /// Initially set to 30 seconds. This value can be reset from the server.
    internal var sessionExpirationIntervalSeconds = 30.0

    /// `leftAppTimestamp` will be recorded when the user leaves the app
    private var leftAppTimestamp: Date?
    private var enterForegroundObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var notificationCenter: NotificationCenter?
    
    @objc public private(set) var sessionDepth = 0

    @objc public init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        MAXLog.debug("MAXSession initialized")
        self.notificationCenter = notificationCenter
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
                self.resetDepth()
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

    /// Session depth starts at 0 and is incremented after every ad request is fired, regardless of
    /// whether a response is received. The first ad request in the session should report a session
    /// depth of 0.
    @objc public func incrementDepth() {
        MAXLog.debug("MAXSession.incrementDepth")
        sessionDepth += 1
    }

    @objc public func resetDepth() {
        MAXLog.debug("MAXSession.resetDepth")
        sessionDepth = 0
    }
}
