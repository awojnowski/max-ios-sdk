# MAX iOS Sample App

## Installation

Before you start, ensure that you have Cocoapods version 1.0 or greater, and XCode 9.0 or greater. 

1. Enter the root directory for either the Swift or ObjC sample apps

2. Install the cocoapods for the project

```
pod install
```

3. Open the project's xcworkspace file

```
open MAXiOSSampleApp.xcworkspace
```

4. (Optional) Run the app in the sample device


## Adding additional sample creatives

The MAX iOS Sample App will load all creative files in the Creatives subdirectory. The app will choose which renderer to use (banner, interstitial, video) based on the identifier at the beginning of the filename (either `banner`, `interstitial`, or `vast`). Make sure to use the right identifier when adding a new sample creative. 

