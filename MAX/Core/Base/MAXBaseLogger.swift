//
//  MAXBaseLogger.swift
//  MAX
//
//  Created by Bryan Boyko on 2/16/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

import Foundation

// NOTE: For now we wrap MaxCommonLogger ObjC class with Swift. After ObjC code is rewritten in
// Swift, we can remove wrapper and port objc implementation to Swift implementation in this class.
// MAXBaseLogger can then be removed in favor of MAXLogger class.


@objc public enum MAXBaseLogLevel: Int, CustomStringConvertible {
    
    case none = 0
    case error
    case warn
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
        case .warn:
            return "warn"
        case .info:
            return "info"
        case .debug:
            return "debug"
        }
    }
}

public class MAXBaseLogger: NSObject {
    
    private var _logLevel: MAXBaseLogLevel
    @objc public var logLevel: MAXBaseLogLevel {
        get {
            return self._logLevel
        }
        set(newLogLevel) {
            _logLevel = newLogLevel
            print("MAXBaseLogger: Log level set to \(newLogLevel.description)")
            MaxCommonLogger.setLogLevel(SourceKitLogLevel(rawValue: SourceKitLogLevel.RawValue(logLevel.rawValue)))
        }
    }
    
    public override init() {
        _logLevel = MAXBaseLogLevel.none
    }
    
    @objc public func error(tag: String, message: String) {
        MaxCommonLogger.error(tag, withMessage: message)
    }
    
    @objc public func warn(tag: String, message: String) {
        MaxCommonLogger.warning(tag, withMessage: message)
    }
    
    @objc public func info(tag: String, message: String) {
        MaxCommonLogger.info(tag, withMessage: message)
    }
    
    @objc public func debug(tag: String, message: String) {
        MaxCommonLogger.debug(tag, withMessage: message)
    }
}
