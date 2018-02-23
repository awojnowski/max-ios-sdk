import Foundation

/// Centralized MAX logging
/// By default, only ERROR messages are logged to the console. To see debug
/// messages, call MAXLogLevelDebug()

enum MAXLogLevel {
    case debug
    case info
    case warn
    case error
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

    @objc
    public static var logger = MAXLog

    public init(identifier: String) {
        self.identifier = identifier
    }

    @objc
    public func setLogLevelDebug() {
        self.logLevel = .debug
    }

    @objc
    public func setLogLevelInfo() {
        self.logLevel = .info
    }

    @objc
    public func setLogLevelWarn() {
        self.logLevel = .warn
    }

    @objc
    public func setLogLevelError() {
        self.logLevel = .error
    }

    public func error(_ message: String) {
        NSLog("\(identifier) [ERROR]: \(message)")
    }

    public func warn(_ message: String) {
        guard [MAXLogLevel.warn, MAXLogLevel.info, MAXLogLevel.debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [WARN]: \(message)")
    }

    public func info(_ message: String) {
        guard [MAXLogLevel.info, MAXLogLevel.debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [INFO]: \(message)")
    }

    public func debug(_ message: String) {
        if self.logLevel == .debug {
            NSLog("\(identifier) [DEBUG]: \(message)")
        }
    }
}
