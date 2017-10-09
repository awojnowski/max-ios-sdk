//
//  MAXLogger.swift
//  MAX
//
//  Copyright © 2017 MAX. All rights reserved.
//

import Foundation

//
// Centralized MAX logging
// By default, only ERROR messages are logged to the console. To see debug
// messages, call MAXLogLevelDebug()
//

enum MAXLogLevel {
    case Debug
    case Info
    case Warn
    case Error
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

public class MAXLogger : NSObject {
    var identifier: String
    var logLevel: MAXLogLevel = .Info
    
    @objc
    public static var logger = MAXLog
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    @objc
    public func setLogLevelDebug() {
        self.logLevel = .Debug
    }

    @objc
    public func setLogLevelInfo() {
        self.logLevel = .Info
    }

    @objc
    public func setLogLevelWarn() {
        self.logLevel = .Warn
    }

    @objc
    public func setLogLevelError() {
        self.logLevel = .Error
    }

    public func error(_ x: String) {
        NSLog("\(identifier) [ERROR]: \(x)")
    }

    public func warn(_ x: String) {
        guard [MAXLogLevel.Warn, MAXLogLevel.Info, MAXLogLevel.Debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [WARN]: \(x)")
    }

    public func info(_ x: String) {
        guard [MAXLogLevel.Info, MAXLogLevel.Debug].contains(self.logLevel) else { return }
        NSLog("\(identifier) [INFO]: \(x)")
    }

    public func debug(_ x: String) {
        if self.logLevel == .Debug {
            NSLog("\(identifier) [DEBUG]: \(x)")
        }
    }
}
