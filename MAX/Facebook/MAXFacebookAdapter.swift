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
        // FBAudienceNetwork has a race condition in their bidderToken method
        // when it's called before anything else has been initialized. We create and
        // immediately throw out this view to force the initialization to happen.
        MAXLog.debug("Initializing FBAudienceNetwork integration")
        _ = FBAdView()
        self.tokenRegistrar.registerTokenProvider(FacebookTokenProvider())
        self.registerAdViewGenerator(FacebookBannerGenerator())
        self.registerInterstitialGenerator(FacebookInterstitialGenerator())
    }
}
