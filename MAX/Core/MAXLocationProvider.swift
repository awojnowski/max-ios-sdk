import Foundation
import CoreLocation

/**
 * MAXLocationProvider
 *
 * Provides access to the device's latitude and longitude.
 *
 * This functionality must be enabled by the SDK user by calling `MAXConfiguration.shared.enableLocationTracking()` and
 * can be disabled by calling `MAXConfiguration.shared.disableLocationTracking()`. Once enabled, latitude, longitude,
 * location granularity, and location availability will be provided in ad requests.
 *
 * The location granularity can be updated via the MAX ad-server.
 *
 * The app must explicitly ask for authorization by the user to access their location -- MAX will
 * not ask for permission on it's own.
 */
class MAXLocationProvider: NSObject, CLLocationManagerDelegate {

    public static let shared = MAXLocationProvider()

    internal var lastLocation: CLLocation?
    
    private var locationManager = CLLocationManager()
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?

    override init() {
        super.init()

        self.locationManager.delegate = self
        // This value represents the distance in meters the device needs to move in order to receive a location
        // update. This is set to a fairly fine grained value so as to track hyper-local location changes.
        // Note that locationManager.desiredAccuracy is set to the best accuracy by default, so we don't need
        // to set it manually (we have the option if there are battery issues in the future).
        self.locationManager.distanceFilter = 10.0

        // Stop observing location updates when the app moves to the background
        self.backgroundObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.UIApplicationDidEnterBackground,
                object: nil,
                queue: OperationQueue.main
        ) {
            _ in self.stopLocationUpdates()
        }

        // Restart location updates when the app moves into the foreground
        self.foregroundObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.UIApplicationWillEnterForeground,
                object: nil,
                queue: OperationQueue.main
        ) {
            _ in self.startLocationUpdates()
        }

        self.startLocationUpdates()
    }

    deinit {
        if let foreground = self.foregroundObserver {
            NotificationCenter.default.removeObserver(foreground)
        }
        if let background = self.backgroundObserver {
            NotificationCenter.default.removeObserver(background)
        }
        self.stopLocationUpdates()
    }

    @objc public func locationTrackingEnabled() -> Bool {
        return MAXConfiguration.shared.locationTrackingEnabled
    }

    @objc public func locationTrackingAuthorized() -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        return authorizationStatus == .authorizedWhenInUse ||
               authorizationStatus == .authorizedAlways
    }

    @objc public func locationTrackingAvailability() -> String {
        if !self.locationTrackingEnabled() {
            return "disabled"
        } else if !self.locationTrackingAuthorized() {
            return "unauthorized"
        } else {
            return "enabled"
        }
    }

    @objc public func startLocationUpdates() {
        guard self.locationTrackingEnabled() else {
            MAXLogger.debug("Location tracking disabled in MAXConfiguration, skipping location updates")
            return
        }

        guard self.locationTrackingAuthorized() else {
            MAXLogger.debug("Location tracking not enabled by the user for this app, skipping location updates")
            return
        }

        MAXLogger.debug("MAXLocationProvider will start updating it's location.")
        self.locationManager.startUpdatingLocation()
    }

    @objc public func stopLocationUpdates() {
        MAXLogger.debug("MAXLocationProvider will stop updating it's location.")
        self.locationManager.stopUpdatingLocation()
    }

    @objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MAXLogger.debug("MAXLocationProvider updated with new location")
        let location = locations.last!

        self.lastLocation = location
    }

    @objc public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MAXLogger.error("MAXLocationProvider failed to update location")
    }

    @objc public func setDistanceFilter(_ distanceFilter: Double) {
        MAXLogger.debug("MAXLocationProvider distance filter updated from \(self.locationManager.distanceFilter) to \(distanceFilter)")
        self.locationManager.distanceFilter = distanceFilter
        self.stopLocationUpdates()
        self.startLocationUpdates()
    }

    @objc public func getLocation() -> CLLocation? {
        guard self.locationTrackingEnabled() else {
            MAXLogger.warn("MAXLocationProvider getLocation called but location tracking is disabled")
            return nil
        }
        return self.lastLocation
    }

    @objc public func getLocationUpdateTimestamp() -> Date? {
        guard self.locationTrackingEnabled() else {
            MAXLogger.warn("MAXLocationProvider getLastLocationUpdateTimestamp called but location tracking is disabled.")
            return nil
        }

        if let location = self.lastLocation {
            return location.timestamp
        }

        MAXLogger.warn("MAXLocationProvider getLastLocationUpdateTimestamp called before any locations were tracked.")
        return nil
    }

    // TODO - Bryan: 'Method cannot be marked @objc because its result type cannot be represented in Objective-C'
    public func getLocationHorizontalAccuracy() -> CLLocationAccuracy? {
        guard self.locationTrackingEnabled() else {
            MAXLogger.warn("MAXLocationProvider getLocationHorizontalAccuracy called but location tracking is disabled")
            return nil
        }

        if let location = self.lastLocation {
            return location.horizontalAccuracy
        }

        MAXLogger.warn("MAXLocationProvider getLocationHorizontalAccuracy called before any locations were tracked.")
        return nil
    }

    // TODO - Bryan: 'Method cannot be marked @objc because its result type cannot be represented in Objective-C'
    public func getLocationVerticalAccuracy() -> CLLocationAccuracy? {
        guard self.locationTrackingEnabled() else {
            MAXLogger.warn("MAXLocationProvider getLocationVerticalAccuracy called but location tracking is disabled")
            return nil
        }

        if let location = self.lastLocation {
            return location.verticalAccuracy
        }

        MAXLogger.warn("MAXLocationProvider getLocationVerticalAccuracy called before any locations were tracked.")
        return nil
    }
}
