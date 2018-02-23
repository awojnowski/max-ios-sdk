//
//  MAXBaseLogger.swift
//  MAX
//
//  Created by Bryan Boyko on 2/16/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

// NOTE: For now we wrap MaxCommonLogger ObjC class with Swift. After ObjC code is rewritten in Swift, we can remove wrapper and port objc implementation to Swift implementation in this class.

@objc public enum MAXBaseLogLevel: Int, CustomStringConvertible {
    
    case none = 0
    case error
    case warning
    case info
    case debug
    
    public var index: Int {
        return rawValue
    }
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .error:
            return "error"
        case .warning:
            return "warning"
        case .info:
            return "info"
        case .debug:
            return "debug"
        }
    }
}

public class MAXBaseLogger: NSObject {
    
    @objc public var logLevel: MAXBaseLogLevel {
        willSet(newLogLevel) {
            print("MAXBaseLogger: Log level set to \(newLogLevel.description)")
            MaxCommonLogger.setLogLevel(SourceKitLogLevel(rawValue: SourceKitLogLevel.RawValue(logLevel.rawValue)))
        }
    }
    
    public override init() {
        logLevel = MAXBaseLogLevel.none
    }
    
    @objc public func error(tag: String, message: String) {
        MaxCommonLogger.error(tag, withMessage: message)
    }
    
    @objc public func warning(tag: String, message: String) {
        MaxCommonLogger.warning(tag, withMessage: message)
    }
    
    @objc public func info(tag: String, message: String) {
        MaxCommonLogger.info(tag, withMessage: message)
    }
    
    @objc public func debug(tag: String, message: String) {
        MaxCommonLogger.debug(tag, withMessage: message)
    }
}
