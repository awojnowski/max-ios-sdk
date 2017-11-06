import Foundation

class MAXAdRequestStub: MAXAdRequest {
    let mockSession = MockURLSession()
    override func getSession() -> URLSession {
        return mockSession
    }
    
    var locationTrackingEnabled = false
    
    override var latitude: Double? {
        if self.locationTrackingEnabled {
            return 10.01
        }
        return nil
    }
    override var longitude: Double? {
        if self.locationTrackingEnabled {
            return 11.02
        }
        return nil
    }
    
    override var locationHorizontalAccuracy: Double? {
        if self.locationTrackingEnabled {
            return 3.4
        }
        return nil
    }
    
    override var locationVerticalAccuracy: Double? {
        if self.locationTrackingEnabled {
            return 4.5
        }
        return nil
    }
    
    override var locationTrackingTimestamp: String? {
        if self.locationTrackingEnabled {
            return "pretty recently"
        }
        return nil
    }
}
