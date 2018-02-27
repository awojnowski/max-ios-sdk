import Foundation
@testable import MAX

class MAXAdResponseStub: MAXAdResponse {
    let mockSession = MockURLSession()
    override func getSession() -> URLSession {
        return mockSession
    }
    
    var _autoRefreshInterval: NSNumber? = nil
    override var autoRefreshInterval: NSNumber? {
        get {
            return _autoRefreshInterval
        }
        set {
            _autoRefreshInterval = newValue
        }
    }
    
    var _expirationIntervalSeconds: Double? = nil
    override var expirationIntervalSeconds: Double {
        get {
            if let e = _expirationIntervalSeconds {
                return e
            }
            return super.expirationIntervalSeconds
        }
        set {
            _expirationIntervalSeconds = newValue
        }
    }
    
    var _partner: String? = nil
    override var partnerName: String? {
        get {
            return _partner
        }
    }
    
    var _usePartnerRendering = false
    override var usePartnerRendering: Bool {
        get {
            return _usePartnerRendering
        }
    }
    
    var _creativeType = "html"
    override var creativeType: String {
        get {
            return _creativeType
        }
    }
}
