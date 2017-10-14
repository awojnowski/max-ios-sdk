//
// Created by John Pena on 9/12/17.
// Copyright (c) 2017 MAX. All rights reserved.
//

import CoreLocation
import Quick
import Nimble
@testable import MAX

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

class MAXLocationProviderSpec: QuickSpec {
    override func spec() {
        describe("MAXLocationProvider") {

            var provider: TestableMAXLocationProvider?
            let location: CLLocation = CLLocation(
                latitude: 37.792781,
                longitude:-122.405174
            )

            beforeEach {
                provider = TestableMAXLocationProvider()
            }

            it("reports the location tracking availability") {
                expect(provider!.locationTrackingAvailability()).to(equal("enabled"))

                provider!._locationTrackingAuthorized = false
                expect(provider!.locationTrackingAvailability()).to(equal("unauthorized"))

                provider!._locationTrackingEnabled = false
                expect(provider!.locationTrackingAvailability()).to(equal("disabled"))
            }

            it("tracks location updates and provides a last known location") {
                expect(provider!.getLocation()).to(beNil())
                expect(provider!.getLocationUpdateTimestamp()).to(beNil())
                expect(provider!.getLocationHorizontalAccuracy()).to(beNil())
                expect(provider!.getLocationVerticalAccuracy()).to(beNil())

                provider!.locationManager(CLLocationManager(), didUpdateLocations: [location])

                expect(provider!.getLocationUpdateTimestamp()).notTo(beNil())
                expect(provider!.getLocationHorizontalAccuracy()).notTo(beNil())
                expect(provider!.getLocationVerticalAccuracy()).notTo(beNil())
                expect(provider!.lastLocation).to(equal(location))
            }

            it("returns a nil location when location tracking updates are off") {
                provider!.lastLocation = location
                provider!._locationTrackingEnabled = false

                expect(provider!.getLocation()).to(beNil())
                expect(provider!.getLocationUpdateTimestamp()).to(beNil())
                expect(provider!.getLocationHorizontalAccuracy()).to(beNil())
                expect(provider!.getLocationVerticalAccuracy()).to(beNil())
            }
        }
    }
}

