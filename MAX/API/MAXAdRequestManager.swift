//
//  MAXAdRequestManager.swift
//  Pods
//
//

import UIKit
import Foundation

class Block<T> {
    let f : T
    init (_ f: T) { self.f = f }
}

let ERROR_RETRY_BASE = 2.0, MAX_ERROR_RETRY = 30.0

//
// Use a MAXAdRequestManager to coordinate refreshing static ad units (banners) 
// in the following circumstances:
// 1) Auto-refresh periodically (e.g. every 30 seconds) 
// 2) Auto-retry of failed ad requests
// 3) Lifecycle management (e.g. automatically load a new ad when app is brought to foreground) 
//
public class MAXAdRequestManager : NSObject {
    public var lastRequest : MAXAdRequest?
    
    var _adUnitID : String
    var _completion : (MAXAdResponse?, NSError?) -> Void
    
    var _shouldRefresh = false
    var _timer : Timer?
    var _errorCount = 0.0

    var appObserver: NSObjectProtocol!
    
    public init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self._adUnitID = adUnitID
        self._completion = completion
        super.init()
        // App lifecycle: when the app is in the background, we will automatically ignore a 
        // request to refresh, so when the app comes back to the foreground, we need to resurrect the timer
        // so that the refresh begins again.
        self.appObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIApplicationDidBecomeActive,
                object: nil,
                queue: OperationQueue.main
        ) {
            notification in
            if self._shouldRefresh {
                MAXLog.debug("MAX: got UIApplicationDidBecomeActiveNotification, requesting auto-refresh")
                self.scheduleTimerImmediately()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self.appObserver)
    }

    func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        return MAXAdRequest.preBidWithMAXAdUnit(self._adUnitID, completion: completion)
    }

    // 
    // Performs an ad request and then calls the completion handler once it is done.
    // If an error occurs, a new ad request is generated on an exponential backoff strategy, and retried.
    //
    public func refresh() -> MAXAdRequest {
        MAXLog.debug("refresh() called")

        return self.runPreBid() { (response, error) in
            MAXLog.debug("preBidWithMAXAdUnit() returned")
            self._completion(response, error)

            // Auto-refresh the same pre-bid and execution logic if we successfully retrieved a pre-bid.
            // NOTE that the SSP refresh should be disabled if pre-bid refresh is being used.
            if let adResponse = response {
                self._errorCount = 0
                if adResponse.shouldAutoRefresh() {
                    if let autoRefreshInterval = adResponse.autoRefreshInterval {
                        self.scheduleTimerWithInterval(Double(autoRefreshInterval))
                    }
                }

            } else if let adError = error {
                self._errorCount += 1
                
                // Retry a failed ad request using exponential backoff. The request will be retried until it succeeds.
                MAXLog.error("MAX: Error occurred \(adError), retry attempt \(self._errorCount)")
                MAXErrorReporter.shared.logError(error: adError)
                self.scheduleTimerWithInterval(min(pow(ERROR_RETRY_BASE, self._errorCount), MAX_ERROR_RETRY))
            }
        }
    }
    
    public func startRefresh() {
        self._shouldRefresh = true
        self.scheduleTimerImmediately()
    }
    
    public func stopRefresh() {
        self._shouldRefresh = false
        self._timer?.invalidate()
        self._timer = nil
    }
    
    private func scheduleTimerWithInterval(_ interval: Double) {
        MAXLog.debug("MAX: Scheduling auto-refresh in \(interval) seconds")
        DispatchQueue.main.async(execute: {
            // if there is an existing timer, we first cancel it
            if let timer = self._timer {
                timer.invalidate()
            }
            // then, set a new timer with the requested time interval
            self._timer = Timer.scheduledTimer(
                    timeInterval: TimeInterval(interval),
                    target: self,
                    selector: #selector(self.refreshTimerDidFire(_:)),
                    userInfo: nil,
                    repeats: false
            )
        })
    }

    private func scheduleTimerImmediately() {
        self.scheduleTimerWithInterval(0)
    }
    
    @objc func refreshTimerDidFire(_ timer: Timer!) {
        self._timer = nil
        guard self._shouldRefresh else {
            return
        }
        guard UIApplication.shared.applicationState == .active else {
            // in this case, the user has stopped refresh for this ad manager explicitly,
            // or the application is backgrounded, in which case we should not attempt to continue
            // loading new ads
            MAXLog.debug("MAX: auto-refresh cancelled, app is not active")
            return
        }

        let _ = self.refresh()
    }
}
