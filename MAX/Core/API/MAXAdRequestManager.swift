import UIKit
import Foundation


@objc public protocol MAXAdRequestManagerDelegate {
    // NOT guaranteed on main queue
    @objc func onRequestSuccess(adResponse: MAXAdResponse?)
    // NOT guaranteed on main queue
    @objc func onRequestFailed(error: NSError?)
}

/// Use a MAXAdRequestManager to coordinate refreshing static ad units (banners)
/// in the following circumstances:
/// 1) Auto-refresh periodically (e.g. every 30 seconds)
/// 2) Auto-retry of failed ad requests
/// 3) Lifecycle management (e.g. automatically load a new ad when app is brought to foreground)
open class MAXAdRequestManager: NSObject {
    
    @objc public static let defaultRefreshTimeSeconds = 60
    @objc public var adUnitId: String?
    @objc public weak var delegate: MAXAdRequestManagerDelegate?
    
    internal var lastError: NSError?
    internal var errorCount = 0.0
    internal var minErrorRetrySeconds = 2.0
    internal var maxErrorRetrySeconds = 30.0
    
    private var isRefreshing = false
    private var timer: Timer?
    private var appActiveObserver: NSObjectProtocol!
    
    // Lock access to isRefreshing variable to ensure only a single refresh cycle happens at a time.
    // While a number of steps in the refresh cycle are asynchronous, the chain of events in a single
    // complete cycle will happen in order, making refresh calls threadsafe.
    private let refreshQueue = DispatchQueue(label: "RefreshQueue")
    
    @objc public override init() {
        super.init()
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self.appActiveObserver)
    }
    
    @objc public func requestAd() {
        self.requestAdFromAPI { (response, error) in
            
            self.isRefreshing = false
            
            if let e = error {
                self.lastError = e
                self.errorCount += 1
                self.reportError(message: "\(String(describing: self)).requestAd() for adUnitId: \(String(describing: response?.adUnitId)) returned with error: \(String(describing: e))")
            } else {
                self.lastError = nil
                self.errorCount = 0
                MAXLogger.debug("\(String(describing: self)).requestAd() returned successfully for adUnitId: \(String(describing: response?.adUnitId))")
                if let del = self.delegate {
                    del.onRequestSuccess(adResponse: response)
                }
            }
        }
    }

    internal func requestAdFromAPI(completion: @escaping MAXResponseCompletion) {
        
        guard let id = self.adUnitId else {
            reportError(message: "\(String(describing: self)).requestAdFromAPI() could not be completed because adUnitID is nil")
            return
        }
        
        _ = MAXAdRequest.preBidWithMAXAdUnit(id, completion: completion)
    }
    
    @objc public func startRefreshTimer(delay: Int) {
        MAXLogger.debug("\(String(describing: self)).isRefreshing() called")
        
        // Guarantee threadsafe refresh cycle with refreshQueue - see decsription at variable declaration
        refreshQueue.async {
            if !self.isRefreshing {
                self.isRefreshing = true
                self.startRefreshTimerInternal(delay: delay)
            }
        }
    }
    
    @objc public func stopRefreshTimer() {
        MAXLogger.debug("\(String(describing: self)).stopRefresh() called")
        
        // See refreshQueue decsription at variable declaration
        refreshQueue.async {
            self.isRefreshing = false
            self.stopRefreshTimerInternal()
        }
    }
    
    // Not threadsafe. Use startFrefreshTimer(delay:) if thread safety needed
    internal func startRefreshTimerInternal(delay: Int) {
        if !self.isRefreshing {
            self.isRefreshing = true
            if let error = self.lastError {
                // Retry a failed ad request using exponential backoff. The request will be retried until it succeeds.
                reportError(message: "\(String(describing: self)): refresh error occurred <\(error)>, retry attempt \(self.errorCount)")
                
                if minErrorRetrySeconds < 1 {
                    MAXLogger.warn("\(String(describing: self)): minErrorRetrySeconds is less than 1. Resetting to 1.")
                    minErrorRetrySeconds = 1
                }
                
                if maxErrorRetrySeconds < minErrorRetrySeconds {
                    MAXLogger.warn("\(String(describing: self)): maxErrorRetrySeconds is less than minErrorRetrySeconds. Resetting to minErrorRetrySeconds.")
                    maxErrorRetrySeconds = minErrorRetrySeconds
                }
                
                self.scheduleTimerWithInterval(interval: Int(min(pow(self.minErrorRetrySeconds, self.errorCount), self.maxErrorRetrySeconds)))
            } else {
                let delay = delay > 0 ? delay : MAXAdRequestManager.defaultRefreshTimeSeconds
                self.scheduleTimerWithInterval(interval: delay)
            }
            
            self.scheduleTimerWithInterval(interval: Int(min(pow(self.minErrorRetrySeconds, self.errorCount), self.maxErrorRetrySeconds)))
        } else {
            let delay = delay > 0 ? delay : MAXAdRequestManager.defaultRefreshTimeSeconds
            self.scheduleTimerWithInterval(interval: delay)
        }
    }
    
    // Not threadsafe. Use stopRefreshTimer() if thread safety needed
    internal func stopRefreshTimerInternal() {
        // Guarantee timer is invalidated in same thread on which it was scheduled
        DispatchQueue.main.async {
            MAXLogger.debug("\(String(describing: self)) refresh timer invalidated")
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    private func scheduleTimerWithInterval(interval: Int) {
        MAXLogger.debug("\(String(describing: self)): Scheduling auto-refresh in \(interval) seconds")
        // Ensure timer is sheduled on main queue (Timers are added to main run loop by default)
        DispatchQueue.main.async(execute: {
            
            var finalInterval = interval
            if finalInterval < 0 {
                finalInterval = MAXAdRequestManager.defaultRefreshTimeSeconds
            }
            
            // if there is an existing timer, we first cancel it
            if let timer = self.timer {
                timer.invalidate()
            }
            
            // then, set a new timer with the requested time interval
            self.timer = Timer.scheduledTimer(
                timeInterval: TimeInterval(finalInterval),
                target: self,
                selector: #selector(self.refreshTimerDidFire(_:)),
                userInfo: nil,
                repeats: false
            )
        })
    }
    
    @objc private func refreshTimerDidFire(_ timer: Timer!) {
        MAXLogger.debug("\(String(describing: self)): refresh timer fired")
        
        self.timer = nil
        
        guard self.isRefreshing else {
            return
        }
        
        guard UIApplication.shared.applicationState == .active else {
            // in this case, the user has stopped refresh for this ad manager explicitly,
            // or the application is backgrounded, in which case we should not attempt to continue
            // loading new ads
            MAXLogger.debug("\(String(describing: self)): auto-refresh cancelled, app is not active")
            return
        }
        
        self.requestAd()
    }
    
    private func addObservers() {
        // App lifecycle: when the app is in the background, we will automatically ignore a
        // request to refresh, so when the app comes back to the foreground, we need to resurrect the timer
        // so that the refresh begins again.
        self.appActiveObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil,
            queue: OperationQueue.main
        ) {
            _ in
            if self.isRefreshing {
                MAXLogger.debug("\(String(describing: self)): got UIApplicationDidBecomeActiveNotification, requesting auto-refresh")
                self.requestAd()
            }
        }
    }
    
    private func reportError(message: String) {
        MAXLogger.error(message)
        let error = MAXClientError(message: message)
        if let del = self.delegate {
            del.onRequestFailed(error: error)
        }
    }
}
