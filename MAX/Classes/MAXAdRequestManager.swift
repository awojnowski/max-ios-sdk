//
//  MAXAdRequestManager.swift
//  Pods
//
//

import Foundation

class Block<T> {
    let f : T
    init (_ f: T) { self.f = f }
}

let MIN_ERROR_RETRY = 1.0, MAX_ERROR_RETRY = 30.0

//
// Use a MAXAdRequestManager to coordinate refreshing static ad units (banners) 
// in the following circumstances:
// 1) Auto-refresh periodically (e.g. every 30 seconds) 
// 2) Auto-retry of failed ad requests
// 3) Lifecycle management (e.g. automatically load a new ad when app is brought to foreground) 
//
public class MAXAdRequestManager {
    public var lastRequest : MAXAdRequest?
    
    private var _adUnitID : String
    private var _completion : (MAXAdResponse?, NSError?) -> Void
    
    private var _shouldRefresh = false
    private var _timer : NSTimer?
    private var _errorCount = 0
    private var _retryInterval = 0.0
    
    public init(adUnitID: String, completion: (MAXAdResponse?, NSError?) -> Void) {
        self._adUnitID = adUnitID
        self._completion = completion
        
        // App lifecycle: when the app is in the background, we will automatically ignore a 
        // request to refresh, so when the app comes back to the foreground, we need to resurrect the timer
        // so that the refresh begins again.
        let foregroundNotification = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) {
            notification in
            if self._shouldRefresh {
                NSLog("MAX: got UIApplicationDidBecomeActiveNotification, requesting auto-refresh")
                self.scheduleTimerWithInterval(0)
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // 
    // Performs an ad request and then calls the completion handler once it is done.
    // If an error occurs, a new ad request is generated on an exponential backoff strategy, and retried.
    //
    public func refresh() -> MAXAdRequest {
        let adr = MAXAdRequest.preBidWithMAXAdUnit(self._adUnitID) {(response, error) in
            self._completion(response, error)
            
            // Auto-refresh the same pre-bid and execution logic if we successfully retrieved a pre-bid.
            // NOTE that the SSP refresh should be disabled if pre-bid refresh is being used.
            //
            if let adResponse = response {
                self._errorCount = 0
                self._retryInterval = 0.0
                
                if adResponse.shouldAutoRefresh() {
                    if let autoRefreshInterval = adResponse.autoRefreshInterval {
                        self.scheduleTimerWithInterval(Double(autoRefreshInterval))
                    }
                }

            } else if let adError = error {
                // Retry a failed ad request using exponential backoff. The request will be retried until it succeeds.
                self._errorCount += 1
                self._retryInterval = min(MAX_ERROR_RETRY, max(self._retryInterval * 2, MIN_ERROR_RETRY))

                NSLog("MAX: Error occurred, retry attempt \(self._errorCount)")
                self.scheduleTimerWithInterval(self._retryInterval)
            }
        }
        
        return adr
    }
    
    public func startRefresh() {
        self._shouldRefresh = true
        self.scheduleTimerWithInterval(0)
    }
    
    public func stopRefresh() {
        self._shouldRefresh = false
        self._timer?.invalidate()
        self._timer = nil
    }
    
    private func scheduleTimerWithInterval(interval: Double) {
        NSLog("MAX: Scheduling auto-refresh in \(interval) seconds")
        dispatch_async(dispatch_get_main_queue(), {
            // if there is an existing timer, we first cancel it
            if let timer = self._timer {
                timer.invalidate()
            }
            // then, set a new timer with the requested time interval
            self._timer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(interval),
                target: self,
                selector: #selector(self.refreshTimerDidFire(_:)),
                userInfo: nil,
                repeats: false)
        })
    }
    
    @objc func refreshTimerDidFire(timer: NSTimer!) {
        self._timer = nil
        guard self._shouldRefresh else {
            return
        }
        guard UIApplication.sharedApplication().applicationState == .Active else {
            // in this case, the user has stopped refresh for this ad manager explicitly,
            // or the application is backgrounded, in which case we should not attempt to continue
            // loading new ads
            NSLog("MAX: auto-refresh cancelled, app is not active")
            return
        }

        self.refresh()
    }


}
