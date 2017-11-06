import Foundation

class MAXSessionStub: MAXSession {
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
