//
// Created by John Pena on 8/29/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import XCTest
@testable import MAX

struct MockObserver {
    var name: NSNotification.Name
    var object: Any?
    var using: (Notification) -> Void
}

class MockNotificationCenter: NotificationCenter {
    var registeredObservers: Dictionary<NSNotification.Name, MockObserver>
    override init() {
        self.registeredObservers = [:]
    }

    override func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        guard let notificationName = name else {
            print("MockNotificationCenter.addObserver called without a defined name, which is unsupported in testing")
            return "" as NSString
        }
        self.registeredObservers[notificationName] = MockObserver(name: notificationName, object: obj, using: block)
        return name! as NSString
    }

    func trigger(name: NSNotification.Name) -> Bool {
        guard let observer = registeredObservers[name] else {
            print("MockNotificationCenter.trigger called with a name (\(name)) that did not have a registered observer")
            return false
        }

        observer.using(Notification.init(name: name))
        return true
    }

}

class MAXSessionTests: XCTestCase {

    class TestableMAXSession: MAXSession {
        var notificationCenter: MockNotificationCenter
        init() {
            self.notificationCenter = MockNotificationCenter()
            super.init(notificationCenter: self.notificationCenter)
        }

        @objc
        override func resetDepth() {
            super.resetDepth()
        }
    }

    func testSessionDepth() {
        let session = TestableMAXSession()
        XCTAssertEqual(session.sessionDepth, 0)

        session.incrementDepth()
        session.incrementDepth()
        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 3)

        session.resetDepth()
        XCTAssertEqual(session.sessionDepth, 0)
    }

    func testObservers() {
        let session = TestableMAXSession()

        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 1)

        session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillResignActive)
        XCTAssertEqual(session.sessionDepth, 0)

        session.incrementDepth()
        session.incrementDepth()
        XCTAssertEqual(session.sessionDepth, 2)

        session.notificationCenter.trigger(name: Notification.Name.UIApplicationWillEnterForeground)
        XCTAssertEqual(session.sessionDepth, 0)
    }
}
