import FBAudienceNetwork

internal class FacebookTokenProvider: MAXTokenProvider {
    @objc public let identifier: String = facebookIdentifier
    @objc public func generateToken() -> String {
        return FBAdSettings.bidderToken
    }
}

// Make MAXConfiguration extension public because MAXConfiguration is public
public extension MAXConfiguration {
    @objc public func initializeFacebookIntegration() {
        // FBAudienceNetwork has a race condition in their bidderToken method
        // when it's called before anything else has been initialized. We create and
        // immediately throw out this view to force the initialization to happen.
        MAXLogger.debug("Initializing FBAudienceNetwork integration")
        _ = FBAdView()
        self.directSDKManager.tokenRegistrar.registerTokenProvider(FacebookTokenProvider())
        self.registerAdViewGenerator(FacebookBannerGenerator())
        self.registerInterstitialGenerator(FacebookInterstitialGenerator())
    }
}
