import Foundation

class MAXLocationProviderStub: MAXLocationProvider {
    var _locationTrackingEnabled: Bool = true
    var _locationTrackingAuthorized: Bool = true
    
    override func locationTrackingEnabled() -> Bool {
        return self._locationTrackingEnabled
    }
    
    override func locationTrackingAuthorized() -> Bool {
        return self._locationTrackingAuthorized
    }
}
