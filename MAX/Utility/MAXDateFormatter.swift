import Foundation

let RFC3339DateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssXXX"

/// MaxDateFormatter formats dates using the RFC3339 codec. It uses a thread-local date formatter to
/// avoid thread safety issues that can arise using DateFormatter.
class MaxDateFormatter {
    /// Parse RFC 3339 date string to NSDate
    public class func dateForRFC3339DateTimeString(rfc3339DateTimeString: String) -> Date? {
        let formatter = getThreadLocalRFC3339DateFormatter()
        return formatter.date(from: rfc3339DateTimeString)
    }

    /// Generate RFC 3339 date string for an NSDate
    public class func rfc3339DateTimeStringForDate(_ date: Date) -> String {
        let formatter = getThreadLocalRFC3339DateFormatter()
        return formatter.string(from: date)
    }

    // Date formatters are not thread-safe, so use a thread-local instance
    private class func getThreadLocalRFC3339DateFormatter() -> DateFormatter {
        return cachedThreadLocalObjectWithKey("io.maxads.MAXDateFormatter") {
            let en_US_POSIX = Locale(identifier: "en_US_POSIX")
            let rfc3339DateFormatter = DateFormatter()
            rfc3339DateFormatter.locale = en_US_POSIX
            rfc3339DateFormatter.dateFormat = RFC3339DateFormat
            rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return rfc3339DateFormatter
        }
    }

    /// Return a thread-local object, creating it if it has not already been created
    private class func cachedThreadLocalObjectWithKey<T: AnyObject>(_ key: String, create: () -> T) -> T {
        let threadDictionary = Thread.current.threadDictionary
        if let cachedObject = threadDictionary[key] as? T {
            return cachedObject
        } else {
            let newObject = create()
            threadDictionary[key] = newObject
            return newObject
        }
    }
}
