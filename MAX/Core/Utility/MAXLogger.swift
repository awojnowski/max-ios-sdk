import Foundation

/// Centralized MAX logging
/// By default, only ERROR messages are logged to the console. To see debug
/// messages, call MAXLogger.shared.setLogLevelDebug()

@objc public enum MAXLogLevel: Int, RawRepresentable {
    case debug
    case info
    case warn
    case error
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warn:
            return "WARN"
        case .error:
            return "ERROR"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "DEBUG":
            self = .debug
        case "INFO":
            self = .info
        case "WARN":
            self = .warn
        case "ERROR":
            self = .error
        default:
            self = .debug
        }
    }
}

public class MAXLogger: NSObject {
    
    @objc public let identifier: String
    @objc public private(set) var logLevel: MAXLogLevel = .info
    
    private static let shared = MAXLogger(identifier: "MAX", maxBaseLogger: MAXBaseLogger())
    private let maxBaseLogger: MAXBaseLogger

    private init(identifier: String, maxBaseLogger: MAXBaseLogger) {
        self.identifier = identifier
        self.maxBaseLogger = MAXBaseLogger()
        super.init()
    }

    @objc public static func setLogLevelDebug() {
        shared.logLevel = .debug
        shared.maxBaseLogger.logLevel = MAXBaseLogLevel.debug
    }

    @objc public static func setLogLevelInfo() {
        shared.logLevel = .info
        shared.maxBaseLogger.logLevel = MAXBaseLogLevel.info
    }

    @objc public static func setLogLevelWarn() {
        shared.logLevel = .warn
        shared.maxBaseLogger.logLevel = MAXBaseLogLevel.warn
    }

    @objc public static func setLogLevelError() {
        shared.logLevel = .error
        shared.maxBaseLogger.logLevel = MAXBaseLogLevel.error
    }

    internal static func error(_ message: String) {
        NSLog("\(shared.identifier) [ERROR]: \(message)")
        
        // Call error urls
        MAXErrorReporter.shared.logError(message: message)
    }

    internal static func warn(_ message: String) {
        guard [MAXLogLevel.warn, MAXLogLevel.info, MAXLogLevel.debug].contains(shared.logLevel) else { return }
        NSLog("\(shared.identifier) [WARN]: \(message)")
    }

    internal static func info(_ message: String) {
        guard [MAXLogLevel.info, MAXLogLevel.debug].contains(shared.logLevel) else { return }
        NSLog("\(shared.identifier) [INFO]: \(message)")
    }

    internal static func debug(_ message: String) {
        if shared.logLevel == .debug {
            NSLog("\(shared.identifier) [DEBUG]: \(message)")
        }
    }
}
