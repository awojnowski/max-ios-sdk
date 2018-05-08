//
//  MAX.h
//  MAX
//
//  Created by Bryan Boyko on 4/6/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for MAX.
FOUNDATION_EXPORT double MAXVersionNumber;

//! Project version string for MAX.
FOUNDATION_EXPORT const unsigned char MAXVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MAX/PublicHeader.h>

// The below imports for exposing internal ObjC files to internal Swift files (unfortunately, these files will also be exposed publicly.. When our ObjC code is converted to Swift, the below imports can be removed)

#import <MAX/MaxMRAIDView.h>
#import <MAX/MaxMRAIDInterstitial.h>
#import <MAX/MaxMRAIDServiceDelegate.h>
#import <MAX/MaxReachability.h>
#import <MAX/MaxCommonLogger.h>



// Third party wrappers

// TEMPORARY - since no third parties will need access to these files, they only need to be added here until MAX Swift files are reqritten to ObjC
#ifdef MAX_VUNGLE_INTEGRATION_EXISTS
#import <MAX/MAXObjCVungleConfiguration.h>
#import <MAX/MAXObjCVungleInterstitialAdapter.h>
#endif
