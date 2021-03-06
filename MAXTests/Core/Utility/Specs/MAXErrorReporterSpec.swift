import Quick
import Nimble
@testable import MAX

class MAXErrorReporterSpec: QuickSpec {
    override func spec() {

        describe("MAXErrorReporter") {
            it("initializes derived properties") {
                let clientError = MAXClientError(message: "Something went wrong")

                expect(clientError.ifa).notTo(beNil())
                expect(clientError.lmt).notTo(beNil())
                expect(clientError.vendorId).notTo(beNil())
                expect(clientError.timeZone).notTo(beNil())
                expect(clientError.locale).notTo(beNil())
                expect(clientError.regionCode).notTo(beNil())
                expect(clientError.orientation).notTo(beNil())
                expect(clientError.deviceWidth).notTo(beNil())
                expect(clientError.deviceHeight).notTo(beNil())
                expect(clientError.browserAgent).notTo(beNil())
                expect(clientError.carrier).notTo(beNil())
            }

            it("properly serializes data") {
                let url = URL(string: "TEST_URL")
                let recorder = MAXErrorReporterStub(errorUrl: url!)
                recorder.reportError(message: "Something broke")

                expect({
                    guard let _ = recorder.data else {
                        return .failed(reason: "Recorder didn't generate any data")
                    }

                    return .succeeded
                }).to(succeed())
            }
        }
    }
}

