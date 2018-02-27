import Quick
import Nimble
@testable import MAX


class MAXInterstitialAdapterStub: MAXInterstitialAdapter {
    override func loadAd() {
        self.delegate?.interstitialDidLoad(self)
    }
    
    var didShowAd = false
    override func showAd(fromRootViewController rvc: UIViewController?) {
        didShowAd = true
    }
}

class MAXInterstitialAdapterGeneratorStub: MAXInterstitialAdapterGenerator {
    var identifier: String = ""
    
    func getInterstitialAdapter(fromResponse: MAXAdResponse) -> MAXInterstitialAdapter? {
        return MAXInterstitialAdapterStub()
    }
    
}

class MAXInterstitialAdStub: MAXInterstitialAd {
   
    var didLoadUsingMRAID = false
    override func loadAdWithMRAIDRenderer() {
        didLoadUsingMRAID = true
    }
    
    var generator: MAXInterstitialAdapterGenerator?
    override internal func getGenerator(forPartner partner: String) -> MAXInterstitialAdapterGenerator? {
        return generator
    }
    
    var didLoadFromAdapter = false
    override func interstitialDidLoad(_ interstitial: MAXInterstitialAdapter) {
        didLoadFromAdapter = true
        super.interstitialDidLoad(interstitial)
    }
    
}

class MAXInterstitialAdSpec: QuickSpec {
    override func spec() {
        describe("MAXInterstitialAd") {
            let rvc = UIViewController()
            var response = MAXAdResponseStub()
            var ad = MAXInterstitialAdStub(adResponse: response)
            
            beforeEach {
                response = MAXAdResponseStub()
                ad = MAXInterstitialAdStub(adResponse: response)
            }
            
            it("should render using a third party renderer when the ad response has usePartnerRendering set to true") {
                response._usePartnerRendering = true
                response._partner = "test"
                ad.generator = MAXInterstitialAdapterGeneratorStub()
                ad.showAdFromRootViewController(rvc)
                expect(ad.didLoadFromAdapter).to(beTrue())
                expect(ad.didLoadUsingMRAID).to(beFalse())
            }
            
            it("should fall back to using the MRAID renderer if there's no partner defined on the ad response") {
                response._usePartnerRendering = true
                response._partner = nil
                ad.generator = MAXInterstitialAdapterGeneratorStub()
                ad.showAdFromRootViewController(rvc)
                expect(ad.didLoadFromAdapter).to(beFalse())
                expect(ad.didLoadUsingMRAID).to(beTrue())
            }
            
            it("should fall back to using the MRAID renderer if the third party renderer can't be generated") {
                response._usePartnerRendering = true
                response._partner = "test"
                ad.generator = nil
                ad.showAdFromRootViewController(rvc)
                expect(ad.didLoadFromAdapter).to(beFalse())
                expect(ad.didLoadUsingMRAID).to(beTrue())
            }
        }
    }
}
