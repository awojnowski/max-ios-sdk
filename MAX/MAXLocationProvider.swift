//
// Created by John Pena on 9/5/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import CoreLocation

/*
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
class MAXLocationProvider: CLLocationManagerDelegate {

    static let shared = MAXLocationProvider()

    var locationManager = CLLocationManager()
    var foregroundObserver: NSObjectProtocol
    var backgroundObserver: NSObjectProtocol

    var lastRecordedLocation: CLLocation? = nil
    var lastLocationUpdate: Date? = nil

    init() {
        self.locationManager.delegate = self
        // This value represents the distance in meters the device needs to move in order to receive a location
        // update. This is set to a fairly fine grained value so as to track hyper-local location changes.
        self.locationManager.distanceFilter = 10.0

        // Stop observing location updates when the app moves to the background
        self.backgroundObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.UIApplicationDidEnterBackground,
                object: nil,
                queue: OperationQueue.main
        ) {
            notification in self.stopLocationUpdates()
        }

        // Restart location updates when the app moves into the foreground
        self.foregroundObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name.UIApplicationWillEnterForeground,
                object: nil,
                queue: OperationQueue.main
        ) {
            notification in self.startLocationUpdates()
        }

        self.startLocationUpdates()
    }

    deinit {
        NotificationCenter.default.removeObserver(self.foregroundObserver)
        NotificationCenter.default.removeObserver(self.backgroundObserver)
        self.stopLocationUpdates()
    }

    func locationTrackingEnabled() -> Bool {
        return MAXConfiguration.shared.locationTrackingEnabled
    }

    func locationTrackingAuthorized() -> Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
    }

    func locationTrackingAvailability() -> String {
        if !self.locationTrackingEnabled() {
            return "disabled"
        } else if !self.locationTrackingAuthorized() {
            return "unauthorized"
        } else {
            return "enabled"
        }
    }

    func startLocationUpdates() {
        guard self.locationTrackingEnabled() else {
            MAXLog.debug("Location tracking disabled in MAXConfiguration, skipping location updates")
            return
        }

        guard self.locationTrackingAuthorized() else {
            MAXLog.debug("Location tracking not enabled by the user for this app, skipping location updates")
            return
        }

        MAXLog.debug("MAXLocationProvider will start updating it's location.")
        self.locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        MAXLog.debug("MAXLocationProvider will stop updating it's location.")
        self.locationManager.stopUpdatingLocation()
    }

    @objc func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MAXLog.debug("MAXLocationProvider updated with new location")
        let location = locations.last!

        self.lastRecordedLocation = location
        self.lastLocationUpdate = Date()
    }

    @objc func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MAXLog.error("MAXLocationProvider failed to update location")
    }

    public func setDistanceFilter(_ distanceFilter: Double) {
        MAXLog.debug("MAXLocationProvider distance filter updated from \(self.locationManager.distanceFilter) to \(distanceFilter)")
        self.locationManager.distanceFilter = distanceFilter
        self.stopLocationUpdates()
        self.startLocationUpdates()
    }

    func getLocation() -> CLLocation? {
        guard self.locationTrackingEnabled() else {
            MAXLog.error("MAXLocationProvider getLocation called but location tracking is disabled")
            return nil
        }
        return self.lastRecordedLocation
    }
}