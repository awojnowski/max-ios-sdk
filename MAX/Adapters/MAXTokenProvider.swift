import Foundation

/// The MAXTokenProvider protocol enables identifier tokens to be registered
/// with MAX, which will be sent with each bid request. These identifier tokens
/// are typically used to provide information identifying the user or app to
/// the exchange buyer. MAXAdRequests will send up these tokens as key-value
/// pairs, with the `identifier` field as the key, and the result of the
/// `generateToken()` call as the value.
///
/// After creating a class that implements MAXTokenProvider, an instance of the
/// token provider class should be registered with MAXConfiguration. For example:
/// ```swift
/// MAXConfiguration.shared.tokenRegistrar.registerTokenProvider(SomeTokenProvider())
/// ```
public protocol MAXTokenProvider {
    var identifier: String { get }
    func generateToken() -> String
}

public class MAXTokenRegistrar {

    public var tokens: Dictionary<String, MAXTokenProvider> = [:]
    
    public func registerTokenProvider(_ tokenProvider: MAXTokenProvider) {
        self.tokens[tokenProvider.identifier] = tokenProvider
    }
    
    public func generateToken(_ withIdentifier: String) -> String? {
        if let provider = tokens[withIdentifier] {
            return provider.generateToken()
        }
        
        return nil
    }
}
