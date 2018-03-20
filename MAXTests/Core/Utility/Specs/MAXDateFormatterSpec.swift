import Quick
import Nimble
@testable import MAX

class MAXDateFormatterSpec: QuickSpec {
    override func spec() {
        describe("MaxDateFormatter") {
            it("should format UTC strings correctly") {
                var dc = DateComponents()
                dc.year = 1987
                dc.month = 3
                dc.day = 8
                dc.hour = 14
                dc.minute = 34
                dc.second = 2
                dc.timeZone = TimeZone(abbreviation: "UTC")
                let date = Calendar.current.date(from: dc)
                expect(MaxDateFormatter.rfc3339DateTimeStringForDate(date!)).to(equal("1987-03-08T14:34:02Z"))
            }
            
            it("should format non-UTC strings correctly") {
                var dc = DateComponents()
                dc.year = 1987
                dc.month = 3
                dc.day = 8
                dc.hour = 14
                dc.minute = 34
                dc.second = 2
                dc.timeZone = TimeZone(abbreviation: "PST")
                let date = Calendar.current.date(from: dc)
                expect(MaxDateFormatter.rfc3339DateTimeStringForDate(date!)).to(equal("1987-03-08T22:34:02Z"))
            }
        }
    }
}
