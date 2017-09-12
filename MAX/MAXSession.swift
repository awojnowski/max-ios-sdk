//
// Created by John Pena on 8/28/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

class MAXSession {

    static let sharedInstance = MAXSession()

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
    public var sessionDepth: Int {
        get {
            return self._sessionDepth
        }
    }

    public func incrementDepth() {
        MAXLog.debug("MAXSession.incrementDepth")
        self._sessionDepth += 1
    }

    @objc
    func resetDepth() {
        MAXLog.debug("MAXSession.resetDepth")
        self._sessionDepth = 0
    }
}