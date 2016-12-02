# MAX

[![Version](https://img.shields.io/cocoapods/v/MAX.svg?style=flat)](http://cocoapods.org/pods/MAX)
[![License](https://img.shields.io/cocoapods/l/MAX.svg?style=flat)](http://cocoapods.org/pods/MAX)
[![Platform](https://img.shields.io/cocoapods/p/MAX.svg?style=flat)](http://cocoapods.org/pods/MAX)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Currently validated with MoPub SDK 4.1 or higher.

## Installation

NOTE: for versions below MAX 1.0, please install the CocoaPod into your project through GitHub:

```ruby
pod 'MAX', :git => 'git@github.com:MoLabsInc/MAX.git'
```

MAX is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MAX"
```

## Integration Overview

MAX is a simple parallel bidding mechanism, which works by running an auction before you call your
primary ad waterfall. This "pre-bid" phase allows more than one exchange or programmatic buyer to 
establish a price for your inventory and then compete at various points in your waterfall.

It works as follows:

1. Your app calls MAX to prepare and send a pre-bid request to the MAX backend.
2. MAX contacts all of your configured ad sources and collects bids from each.
3. The bids are compared and the highest bid that is compliant with your targeting and other
rules is selected.
4. MAX returns the pre-bid results and a set of keywords.
5. Your app calls your ad server/SSP normally, attaching the keywords that were returned. The keywords are designed to match specific line items in your waterfall, which can be set up to trigger only if a certain price is met.
6. If a line item matches the keywords, the ad server/SSP hands off to the MAX custom event. The custom event then shows the ad returned in the pre-bid from the partner exchange or buyer.
7. If nothing matches a MAX line item, then your waterfall proceeds normally.

In this way, you can increase competition and take control of the exchange layer in your ad waterfall without disrupting
the way your ads are served currently.

## Banner Example

It is simple to wrap your existing ad banner view with a MAX pre-bid, using `MAXAdRequestManager`. MAX will handle
all auto-refresh and error retry logic, so you should disable these features on your SSP.

Typically, you will add a banner `AdView` object to your view hierarchy as follows:

```swift
    let banner = MPAdView(adUnitId: MOPUB_BANNER_ADUNIT_ID, size: CGSizeMake(320, 50))
    banner.frame = CGRect(origin: CGPointZero, size: banner.adContentViewSize())
    banner.delegate = self
    self.resultsView.addSubview(banner)
```

To wrap this banner ad view with a MAX pre-bid, do the following:

1. Use a `MAXAdRequestManager` object, which controls the auto-refresh and error retry logic. 
2. In your completion handler, pass the MAX pre-bid keywords to the banner `AdView` object and call `loadAd()`. 
3. Call `startRefresh()` to begin loading ads into the banner view.

```swift
    let adManager = MAXAdRequestManager(adUnitID: MAX_BANNER_ADUNIT_ID) {(response, error) in
        dispatch_sync(dispatch_get_main_queue()) {
            banner.keywords = response?.preBidKeywords ?? banner.keywords
            banner.loadAd()
        }
    }
    adManager.startRefresh()
```

Note that you may want to use `banner.stopAutomaticallyRefreshingContents()` or a similar method
for your ad server to ensure that auto-refresh logic is not duplicated without first running a pre-bid.


## Interstitial Example

Interstitials work similarly to the above. None of your other interstitial display logic needs to change.

```swift
        MAXAdRequest.preBidWithMAXAdUnit(MAX_FULLSCREEN_ADUNIT_ID) {(response, error) in
            dispatch_sync(dispatch_get_main_queue()) {
                self.interstitialController = MPInterstitialAdController(forAdUnitId: MOPUB_FULLSCREEN_ADUNIT_ID)
                self.interstitialController!.keywords = response?.preBidKeywords ?? self.interstitialController!.keywords
                self.interstitialController!.loadAd()
            }
        }
```

## Ad Server/SSP Setup

### Pre-bid Keywords 

MAX works by triggering line items in your SSP/ad server waterfall using keyword targeting. The keywords returned from
the MAX pre-bid system for a $0.26 bid look like this:

```
	m_max:true,max_bidX:000,max_bidXX:020,max_bidXXX:026
```

This structure allows you to set price increments in your SSP at the dollar, ten cent or single cent level. 

### Line Item Custom Events

To create a MAX line item:

1. Create a new line item of type Custom Native 
2. Set the Custom Event Class to the appropriate value depending on their type: `MAXMoPubBannerCustomEvent` or `MAXMoPubInterstitialCustomEvent`.
3. Set the Custom Event Info to `{"adunit_id": "<MAX_ADUNIT_ID>"}` where the value of `MAX_ADUNIT_ID` corresponds to the ID of the MAX ad unit for this request.

## Author

MoLabs Inc, hello@molabs.com

## License

MAX is available under the MIT license. See the LICENSE file for more info.
