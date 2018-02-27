import Foundation

/// Centralized MAX logging
/// By default, only ERROR messages are logged to the console. To see debug
/// messages, call MAXLogLevelDebug()

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

public let MAXLog: MAXLogger = {
    let log = MAXLogger(identifier: "MAX")
    return log
}()

public func MAXLogLevelDebug() {
    MAXLog.setLogLevelDebug()
}

public func MAXLogLevelInfo() {
    MAXLog.setLogLevelInfo()
}

public func MAXLogLevelWarn() {
    MAXLog.setLogLevelWarn()
}

public func MAXLogLevelError() {
    MAXLog.setLogLevelError()
}

public class MAXLogger: NSObject {
    var identifier: String
    var logLevel: MAXLogLevel = .info

    @objc public static var logger = MAXLog

    @objc public init(identifier: String) {
        self.identifier = identifier
    }

    @objc public func setLogLevelDebug() {
        self.logLevel = .debug
    }

    @objc public func setLogLevelInfo() {
        self.logLevel = .info
    }

    @objc public func setLogLevelWarn() {
        self.logLevel = .warn
    }

    @objc public func setLogLevelError() {
        self.logLevel = .error
    }

    @objc public func error(_ message: String) {
        NSLog("\(identifier) [ERROR]: \(message)")
    }

    @objc public func warn(_ message: String) {
        guard [MAXLogLevel.warn, MAXLogLevel.info, MAXLogLevel.debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [WARN]: \(message)")
    }

    @objc public func info(_ message: String) {
        guard [MAXLogLevel.info, MAXLogLevel.debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [INFO]: \(message)")
    }

    @objc public func debug(_ message: String) {
        if self.logLevel == .debug {
            NSLog("\(identifier) [DEBUG]: \(message)")
        }
    }
}
