import UIKit
import Foundation

let minErrorRetrySeconds = 2.0, maxErrorRetrySeconds = 30.0

/// Use a MAXAdRequestManager to coordinate refreshing static ad units (banners)
/// in the following circumstances:
/// 1) Auto-refresh periodically (e.g. every 30 seconds)
/// 2) Auto-retry of failed ad requests
/// 3) Lifecycle management (e.g. automatically load a new ad when app is brought to foreground)
public class MAXAdRequestManager: NSObject {
    public var lastRequest: MAXAdRequest?
    public var lastResponse: MAXAdResponse?
    public var lastError: NSError?

    var adUnitID: String
    var completion: (MAXAdResponse?, NSError?) -> Void

    var shouldRefresh = false
    var timer: Timer?
    var errorCount = 0.0

    var appObserver: NSObjectProtocol!

    public init(adUnitID: String, completion: @escaping (MAXAdResponse?, NSError?) -> Void) {
        self.adUnitID = adUnitID
        self.completion = completion
        super.init()
        // App lifecycle: when the app is in the background, we will automatically ignore a 
        // request to refresh, so when the app comes back to the foreground, we need to resurrect the timer
        // so that the refresh begins again.
        self.appObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIApplicationDidBecomeActive,
                object: nil,
                queue: OperationQueue.main
        ) {
            _ in
            if self.shouldRefresh {
                MAXLog.debug("MAX: got UIApplicationDidBecomeActiveNotification, requesting auto-refresh")
                self.scheduleTimerImmediately()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self.appObserver)
    }

    func runPreBid(completion: @escaping MAXResponseCompletion) -> MAXAdRequest {
        return MAXAdRequest.preBidWithMAXAdUnit(self.adUnitID, completion: completion)
    }

    /// Performs an ad request and then calls the completion handler once it is done.
    /// If an error occurs, a new ad request is generated on an exponential backoff strategy, and retried.
    public func refresh() -> MAXAdRequest {
        MAXLog.debug("refresh() called")

        return self.runPreBid { (response, error) in
            MAXLog.debug("preBidWithMAXAdUnit() returned")
            self.lastResponse = response
            self.lastError = error
            self.completion(response, error)
            self.scheduleNewRefresh()
        }
    }

    /// Auto-refresh the same pre-bid and execution logic if we successfully retrieved a pre-bid.
    /// NOTE that the SSP refresh should be disabled if pre-bid refresh is being used.
    func scheduleNewRefresh() {
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
            MAXLog.error("MAX: Error occurred \(adError), retry attempt \(self.errorCount)")
            MAXErrorReporter.shared.logError(error: adError)
            self.scheduleTimerWithInterval(min(pow(minErrorRetrySeconds, self.errorCount), maxErrorRetrySeconds))
        } else {
            MAXLog.warn("Tried to schedule a new refresh, but couldn't find an ad response or error. No refresh will be scheduled.")
        }
    }

    public func startRefresh() {
        self.shouldRefresh = true
        self.scheduleTimerImmediately()
    }

    public func stopRefresh() {
        self.shouldRefresh = false
        self.timer?.invalidate()
        self.timer = nil
    }

    private func scheduleTimerWithInterval(_ interval: Double) {
        MAXLog.debug("MAX: Scheduling auto-refresh in \(interval) seconds")
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
            MAXLog.debug("MAX: auto-refresh cancelled, app is not active")
            return
        }

        _ = self.refresh()
    }
}
