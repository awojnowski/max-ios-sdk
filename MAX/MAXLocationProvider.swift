//
// Created by John Pena on 9/5/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import Foundation
import CoreLocation

class MAXLocationProvider: CLLocationManagerDelegate {

    static let shared = MAXLocationProvider()

    var distanceFilter = 100.0
    var locationManager = CLLocationManager()
    var foregroundObserver: NSObjectProtocol
    var backgroundObserver: NSObjectProtocol

    var lastRecordedLocation: CLLocation? = nil
    var lastLocationUpdate: Date? = nil

    init() {
        self.locationManager.delegate = self

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

    func locationUpdatesAvailable() -> Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
    }

    func startLocationUpdates() {
        guard self.locationTrackingEnabled() else {
            MAXLog.debug("Location tracking disabled in MAXConfiguration, skipping location updates")
            return
        }

        guard self.locationUpdatesAvailable() else {
            MAXLog.debug("Location tracking not enabled by the user for this app, skipping location updates")
            return
        }

        self.locationManager.startMonitoringSignificantLocationChanges()
    }

    func stopLocationUpdates() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MAXLog.debug("MAXLocationProvider updated with new location")
        let location = locations.last!

        self.lastRecordedLocation = location
        self.lastLocationUpdate = Date()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MAXLog.error("MAXLocationProvider failed to update location")
    }

    func getLocation() -> CLLocation? {
        guard self.locationTrackingEnabled() else {
            return nil
        }
        return self.lastRecordedLocation
    }
}