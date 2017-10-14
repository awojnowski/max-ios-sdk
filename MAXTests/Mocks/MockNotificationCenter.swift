//
// Created by John Pena on 8/30/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation

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
