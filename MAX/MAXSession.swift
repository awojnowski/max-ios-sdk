//
// Created by John Pena on 8/28/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

class MAXSession {

    static let sharedInstance = MAXSession()

    private init() {
        MAXLog.debug("MAXSession initialized")

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
                self,
                selector: #selector(resetDepth),
                name: Notification.Name.UIApplicationWillResignActive,
                object: nil
        )

        notificationCenter.addObserver(
                self,
                selector: #selector(resetDepth),
                name: Notification.Name.UIApplicationWillEnterForeground,
                object: nil
        )
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
    private func resetDepth() {
        MAXLog.debug("MAXSession.resetDepth")
        self._sessionDepth = 0
    }
}