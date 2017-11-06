import FBAudienceNetwork

public let facebookIdentifier = "facebook"

public class FacebookTokenProvider: MAXTokenProvider {
    public let identifier: String = facebookIdentifier
    public func generateToken() -> String {
        return FBAdSettings.bidderToken
    }
}

extension MAXConfiguration {
    public func initializeFacebookIntegration() {
        self.tokenRegistrar.registerTokenProvider(FacebookTokenProvider())
        self.registerAdViewGenerator(FacebookBannerGenerator())
        self.registerInterstitialGenerator(FacebookInterstitialGenerator())
    }
}
