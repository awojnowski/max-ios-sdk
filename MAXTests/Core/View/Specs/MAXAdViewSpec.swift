import Quick
import Nimble
@testable import MAX

class MAXAdViewSpec: QuickSpec {
    override func spec() {
        describe("MAXAdView") {
            
            let size320x50 = CGSize(width: 320, height: 50)
            var response = MAXAdResponseStub()
            var ad = MAXAdViewMock(adResponse: response, size: size320x50)

            beforeEach {
                response = MAXAdResponseStub()
                ad = MAXAdViewMock(adResponse: response, size: size320x50)
            }
            
            it("should render using MRAID when the ad response has usePartnerRendering set to false") {
                response._usePartnerRendering = false
                ad.loadAd()
                expect(ad.didLoadUsingMRAID).to(beTrue())
                expect(ad.didLoadAdWithAdapter).to(beFalse())
            }
            
            it("should render using an adapter when the ad response has usePartnerRendering set to true") {
                response._usePartnerRendering = true
                response._partner = "test"
                ad.generator = MAXAdViewAdapterGeneratorStub()
                ad.loadAd()
                expect(ad.didLoadUsingMRAID).to(beFalse())
                expect(ad.didLoadAdWithAdapter).to(beTrue())
            }
            
            it("should fall back to using the MRAID renderer if there is no partner defined on the ad response") {
                response._usePartnerRendering = true
                response._partner = nil
                ad.generator = MAXAdViewAdapterGeneratorStub()
                ad.loadAd()
                expect(ad.didLoadUsingMRAID).to(beTrue())
                expect(ad.didLoadAdWithAdapter).to(beFalse())
            }
            
            it("should fall back to using the MRAID renderer if the adapter can't be generated") {
                response._usePartnerRendering = true
                response._partner = "test"
                ad.generator = nil
                ad.loadAd()
                expect(ad.didLoadUsingMRAID).to(beTrue())
                expect(ad.didLoadAdWithAdapter).to(beFalse())
            }
        }
    }
}
