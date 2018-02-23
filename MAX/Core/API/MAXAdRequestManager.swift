import UIKit
import Foundation

let minErrorRetrySeconds = 2.0, maxErrorRetrySeconds = 30.0

/// Use a MAXAdRequestManager to coordinate refreshing static ad units (banners)
/// in the following circumstances:
/// 1) Auto-refresh periodically (e.g. every 30 seconds)
/// 2) Auto-retry of failed ad requests
/// 3) Lifecycle management (e.g. automatically load a new ad when app is brought to foreground)
open class MAXAdRequestManager: NSObject {
    public var lastRequest: MAXAdRequest?
    public var lastResponse: MAXAdResponse?
    public var lastError: NSError?

    var adUnitID: String
    var completion: (MAXAdResponse?, NSError?) -> Void

    var shouldRefresh = false
    var timer: Timer?
    var errorCount = 0.0

    var appActiveObserver: NSObjectProtocol!

    // Lock access to shouldRefresh variable to ensure only a single refresh cycle happens at a time.
    // While a number of steps in the refresh cycle are asynchronous, the chain of events in a single
    // complete cycle will happen in order, making refresh calls threadsafe.
    let refreshQueue = DispatchQueue(label: "RefreshQueue")

    public init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self.adUnitID = adUnitID
        self.completion = completion
        super.init()
        // App lifecycle: when the app is in the background, we will automatically ignore a 
        // request to refresh, so when the app comes back to the foreground, we need to resurrect the timer
        // so that the refresh begins again.
        self.appActiveObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIApplicationDidBecomeActive,
                object: nil,
                queue: OperationQueue.main
        ) {
            _ in
            if self.shouldRefresh {
                MAXLog.debug("\(String(describing: self)): got UIApplicationDidBecomeActiveNotification, requesting auto-refresh")
                self.scheduleTimerImmediately()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self.appActiveObserver)
    }

    public func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        return MAXAdRequest.preBidWithMAXAdUnit(self.adUnitID, completion: completion)
    }

    /// Performs an ad request and then calls the completion handler once it is done.
    /// If an error occurs, a new ad request is generated on an exponential backoff strategy, and retried.
    internal func refresh() -> MAXAdRequest {
        MAXLog.debug("\(String(describing: self)) internal refresh() called")
        return self.runPreBid { (response, error) in
            MAXLog.debug("\(String(describing: self)).runPreBid() returned with error: \(String(describing: error))")
            self.lastResponse = response
            self.lastError = error
            self.completion(response, error)
            self.scheduleNewRefresh()
        }
    }

    /// Auto-refresh the same pre-bid and execution logic if we successfully retrieved a pre-bid.
    /// NOTE that the SSP refresh should be disabled if pre-bid refresh is being used.
    internal func scheduleNewRefresh() {
        if let adResponse = self.lastResponse {
            self.errorCount = 0
            if adResponse.shouldAutoRefresh() {
                if let autoRefreshInterval = adResponse.autoRefreshInterval {
                    self.scheduleTimerWithInterval(Double(autoRefreshInterval))
                }
            }
        } else if let adError = self.lastError {
            self.errorCount += 1
            // Retry a failed ad request using exponential backoff. The request will be retried until it succeeds.
            MAXLog.error("\(String(describing: self)): Error occurred \(adError), retry attempt \(self.errorCount)")
            MAXErrorReporter.shared.logError(error: adError)
            self.scheduleTimerWithInterval(min(pow(minErrorRetrySeconds, self.errorCount), maxErrorRetrySeconds))
        } else {
            MAXLog.warn("\(String(describing: self)): tried to schedule a new refresh, but couldn't find an ad response or error. No refresh will be scheduled.")
        }
    }

    public func startRefresh() {
        MAXLog.debug("\(String(describing: self)).startRefresh() called")
        // See refreshQueue decsription at variable declaration
        refreshQueue.async {
            if !self.shouldRefresh {
                self.shouldRefresh = true
                self.scheduleTimerImmediately()
            }
        }
    }

    public func stopRefresh() {
        MAXLog.debug("\(String(describing: self)).stopRefresh() called")
        // See refreshQueue decsription at variable declaration
        refreshQueue.async {
            self.shouldRefresh = false
            // Guarantee timer is invalidated in same thread on which it was scheduled
            DispatchQueue.main.async {
                MAXLog.debug("\(String(describing: self)) refresh timer invalidated")
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }

    private func scheduleTimerWithInterval(_ interval: Double) {
        MAXLog.debug("\(String(describing: self)): Scheduling auto-refresh in \(interval) seconds")
        // Ensure timer is sheduled on main queue (Timers are added to main run loop by default)
        DispatchQueue.main.async(execute: {
            // if there is an existing timer, we first cancel it
            if let timer = self.timer {
                timer.invalidate()
            }
            // then, set a new timer with the requested time interval
            self.timer = Timer.scheduledTimer(
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
        self.timer = nil
        guard self.shouldRefresh else {
            return
        }
        guard UIApplication.shared.applicationState == .active else {
            // in this case, the user has stopped refresh for this ad manager explicitly,
            // or the application is backgrounded, in which case we should not attempt to continue
            // loading new ads
            MAXLog.debug("\(String(describing: self)): auto-refresh cancelled, app is not active")
            return
        }

        _ = self.refresh()
    }
}
