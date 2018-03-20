import Foundation

class MAXSessionManagerStub: MAXSessionManager {
    var notificationCenter: MockNotificationCenter
    init() {
        self.notificationCenter = MockNotificationCenter()
        super.init(notificationCenter: self.notificationCenter)
    }
    
    override func reset() {
        super.reset()
    }
}
