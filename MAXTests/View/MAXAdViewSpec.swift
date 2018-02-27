import Quick
import Nimble
@testable import MAX

class MAXAdViewAdapterStub: MAXAdViewAdapter {
    var didLoadAd = false
    override func loadAd() {
        self.adView = UIView()
        didLoadAd = true
        self.delegate?.adViewDidLoad(self)
    }
}

class MAXAdViewAdapterGeneratorStub: MAXAdViewAdapterGenerator {
    var identifier: String = ""
    func getAdViewAdapter(fromResponse: MAXAdResponse,
                          withSize: CGSize,
                          rootViewController: UIViewController?) -> MAXAdViewAdapter? {
        return MAXAdViewAdapterStub()
    }
}

class MAXAdViewStub: MAXAdView {
    var didLoadUsingMRAID = false
    override internal func loadAdWithMRAIDRenderer() {
        didLoadUsingMRAID = true
    }
    
    var generator: MAXAdViewAdapterGenerator?
    override internal func getGenerator(forPartner partner: String) -> MAXAdViewAdapterGenerator? {
        return generator
    }
    
    var didLoadAdWithAdapter = false
    override func addSubview(_ view: UIView) {
        // It's safe to assume this call came from the loadAdWithAdapter method since
        // the loadAdWithMRAIDRenderer is overridden and is the only other method that
        // calls addSubview
        didLoadAdWithAdapter = true
    }
}

class MAXAdViewSpec: QuickSpec {
    override func spec() {
        describe("MAXAdView") {
            
//            let rvc = UIViewController()
            let size320x50 = CGSize(width: 320, height: 50)
            var response = MAXAdResponseStub()
            var ad = MAXAdViewStub(adResponse: response, size: size320x50)

            beforeEach {
                response = MAXAdResponseStub()
                ad = MAXAdViewStub(adResponse: response, size: size320x50)
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
