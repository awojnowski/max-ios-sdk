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

// TODO - Bryan: MAXInterestitialAd isn't completely tested because the all routes from load() to MAXInterstitialAdDelegate callbacks aren't added here. It's not straightforward to test these routes until there's a MAXInterstitialFactoryStub that can be injected into MAXInterstitialAd. MAXInterstitialFactoryStub will stub MRAID, VAST, and partner adapter after a common interface has been created that they can all inherit from or conform to.
class MAXInterstitialAdSpec: QuickSpec {
    override func spec() {
        describe("MAXInterstitialAd") {
            let adUnitId = "whatever"
            let response = MAXAdResponseStub()
            let requestManager = MAXAdRequestManagerMock()
            requestManager.response = response
            let sessionManager = MAXSessionManager.shared
            let ad = MAXInterstitialAdMock(requestManager: requestManager, sessionManager: sessionManager)
            
            beforeEach {
                response._usePartnerRendering = false
                response._partner = nil
                response._creativeType = MAXInterstitialCreativeType.empty.rawValue
                ad.loaded = false
                ad.shown = false
                ad.didLoadUsingMRAID = false
                ad.didLoadUsingVAST = false
                ad.didLoadUsingAdapter = false
            }
            
            it("should load interstitials with VAST for responses with creativeType 'vast3'") {
                response._creativeType = MAXInterstitialCreativeType.VAST.rawValue
                ad.generator = nil
                ad.load(adUnitId: adUnitId)
                expect(ad.didLoadUsingAdapter).to(beFalse())
                expect(ad.didLoadUsingMRAID).to(beFalse())
                expect(ad.didLoadUsingVAST).to(beTrue())
            }
            
            it("should load interstitials with MRAID for responses with creativeType 'html'") {
                response._creativeType = MAXInterstitialCreativeType.HTML.rawValue
                ad.generator = nil
                ad.load(adUnitId: adUnitId)
                expect(ad.didLoadUsingAdapter).to(beFalse())
                expect(ad.didLoadUsingMRAID).to(beTrue())
                expect(ad.didLoadUsingVAST).to(beFalse())
            }
            
            it("should load interstitials with adapters for responses with creativeType 'empty'") {
                ad.generator = nil
                ad.load(adUnitId: adUnitId)
                expect(ad.didLoadUsingAdapter).to(beTrue())
                expect(ad.didLoadUsingMRAID).to(beFalse())
                expect(ad.didLoadUsingVAST).to(beFalse())
            }
        }
    }
}
