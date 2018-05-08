//
//  MAX-Bridging-Header.h
//  MAX
//
//  Created by Bryan Boyko on 4/5/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//



// NOTE: This file is currently only in use for the MAXTests target

#ifndef MAX_Bridging_Header_h
#define MAX_Bridging_Header_h

// Third party
#import <VungleSDK/VungleSDK.h>
#import <VungleSDK/VungleSDKHeaderBidding.h>

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

#endif /* MAX_Bridging_Header_h */
