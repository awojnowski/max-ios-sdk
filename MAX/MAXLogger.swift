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
public let MAXLog: MAXLogger = {
    let log = MAXLogger(identifier: "MAX")
    return log
}()

public func MAXLogLevelDebug() {
    MAXLog.setLogLevelDebug()
}

public class MAXLogger : NSObject {
    var identifier: String
    var logLevelDebug: Bool = false
    
    @objc
    public static var logger = MAXLog
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    @objc
    public func setLogLevelDebug() {
        self.logLevelDebug = true
    }
    
    public func error(_ x: String) {
        NSLog("\(identifier) [ERROR]: \(x)")
    }

    public func warn(_ x: String) {
        if logLevelDebug {
            NSLog("\(identifier) [WARN]: \(x)")
        }
    }

    public func info(_ x: String) {
        if logLevelDebug {
            NSLog("\(identifier) [INFO]: \(x)")
        }
    }

    public func debug(_ x: String) {
        if logLevelDebug {
            NSLog("\(identifier) [DEBUG]: \(x)")
        }
    }
}
