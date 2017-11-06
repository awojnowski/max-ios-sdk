import CoreLocation
import Quick
import Nimble
@testable import MAX


class MAXLocationProviderSpec: QuickSpec {
    override func spec() {
        describe("MAXLocationProvider") {

            var provider: MAXLocationProviderStub?
            let location: CLLocation = CLLocation(
                latitude: 37.792781,
                longitude:-122.405174
            )

            beforeEach {
                provider = MAXLocationProviderStub()
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

