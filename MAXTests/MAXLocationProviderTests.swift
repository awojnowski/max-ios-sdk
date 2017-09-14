//
// Created by John Pena on 9/12/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import CoreLocation
import XCTest
@testable import MAX

class MAXLocationProviderTests: XCTestCase {

    class TestableMAXLocationProvider: MAXLocationProvider {
        var _locationTrackingEnabled: Bool = true
        var _locationTrackingAuthorized: Bool = true

        override func locationTrackingEnabled() -> Bool {
            return self._locationTrackingEnabled
        }

        override func locationTrackingAuthorized() -> Bool {
            return self._locationTrackingAuthorized
        }
    }

    var provider: MAXLocationProvider = TestableMAXLocationProvider()
    let location: CLLocation = CLLocation(
            latitude: 37.792781,
            longitude:-122.405174
    )

    override func setUp() {
        provider = TestableMAXLocationProvider()
    }

    func testLocationTrackingAvailability() {
        let provider = TestableMAXLocationProvider()
        XCTAssertEqual(provider.locationTrackingAvailability(), "enabled")

        provider._locationTrackingAuthorized = false
        XCTAssertEqual(provider.locationTrackingAvailability(), "unauthorized")

        provider._locationTrackingEnabled = false
        XCTAssertEqual(provider.locationTrackingAvailability(), "disabled")
    }

    func testLocationManagerUpdate() {
        let provider = TestableMAXLocationProvider()

        XCTAssertNil(provider.getLocation())
        XCTAssertNil(provider.getLocationUpdateTimestamp())
        XCTAssertNil(provider.getLocationHorizontalAccuracy())
        XCTAssertNil(provider.getLocationVerticalAccuracy())

        provider.locationManager(CLLocationManager(), didUpdateLocations: [location])

        XCTAssertNotNil(provider.getLocationUpdateTimestamp())
        XCTAssertNotNil(provider.getLocationHorizontalAccuracy())
        XCTAssertNotNil(provider.getLocationVerticalAccuracy())
        XCTAssertEqual(provider.lastLocation, location)
    }

    func testLocationAccessControls() {
        let provider = TestableMAXLocationProvider()
        provider.lastLocation = location
        provider._locationTrackingEnabled = false

        XCTAssertNil(provider.getLocation())
        XCTAssertNil(provider.getLocationUpdateTimestamp())
        XCTAssertNil(provider.getLocationHorizontalAccuracy())
        XCTAssertNil(provider.getLocationVerticalAccuracy())
    }
}
