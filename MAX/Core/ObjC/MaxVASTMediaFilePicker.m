//
//  MaxVASTMediaFilePicker.m
//  VAST
//
//  Created by Muthu on 11/20/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "MaxVASTMediaFilePicker.h"
#import "MaxReachability.h"
#import "MaxVASTSettings.h"
#import "MaxCommonLogger.h"
#import <UIKit/UIKit.h>

// This enum will be of more use if we ever decide to include the media files'
// delivery type and/or bitrate into the picking algorithm.
typedef enum {
    NetworkTypeCellular,
    NetworkTypeNone,
    NetworkTypeWiFi
} NetworkType;

@interface MaxVASTMediaFilePicker()

+ (NetworkType)networkType;
+ (BOOL)isMIMETypeCompatible:(MaxVASTMediaFile *)vastMediaFile;

@end

@implementation MaxVASTMediaFilePicker

+ (MaxVASTMediaFile *)pick:(NSArray *)mediaFiles
{
    // Check whether we even have a network connection.
    // If not, return a nil.
    NetworkType networkType = [self networkType];
    
    [MaxCommonLogger debug:@"VAST - Mediafile Picker" withMessage:[NSString stringWithFormat:@"NetworkType: %d", networkType]];
    if (networkType == NetworkTypeNone) {
        return nil;
    }
    
    // Go through the provided media files and only those that have a compatible MIME type.
    NSMutableArray *compatibleMediaFiles = [[NSMutableArray alloc] init];
    for (MaxVASTMediaFile *vastMediaFile in mediaFiles) {
        // Make sure that you have type specified for mediafile and ignore accordingly
        if (vastMediaFile.type != nil && [self isMIMETypeCompatible:vastMediaFile]) {
            [compatibleMediaFiles addObject:vastMediaFile];
        }
    }
    if ([compatibleMediaFiles count] == 0) {
        return nil;
    }
    
    // Sort the media files based on their video size (in square pixels).
    NSArray *sortedMediaFiles = [compatibleMediaFiles sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        MaxVASTMediaFile *mf1 = (MaxVASTMediaFile *)a;
        MaxVASTMediaFile *mf2 = (MaxVASTMediaFile *)b;
        int area1 = mf1.width * mf1.height;
        int area2 = mf2.width * mf2.height;
        if (area1 < area2) {
            return NSOrderedAscending;
        } else if (area1 > area2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    // Pick the media file with the video size closes to the device's screen size.
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    int screenArea = screenSize.width * screenSize.height;
    int bestMatch = 0;
    int bestMatchDiff = INT_MAX;
    int len = (int)[sortedMediaFiles count];
    
    for (int i = 0; i < len; i++) {
        int videoArea = ((MaxVASTMediaFile *)sortedMediaFiles[i]).width * ((MaxVASTMediaFile *)sortedMediaFiles[i]).height;
        int diff = abs(screenArea - videoArea);
       if (diff >= bestMatchDiff) {
            break;
        }
        bestMatch = i;
        bestMatchDiff = diff;
    }
    
    MaxVASTMediaFile *toReturn = (MaxVASTMediaFile *)sortedMediaFiles[bestMatch];
    [MaxCommonLogger debug:@"VAST - Mediafile Picker" withMessage:[NSString stringWithFormat:@"Selected Media File: %@", toReturn.url]];
    return toReturn;
}

+ (NetworkType)networkType
{
    MaxReachability* reach = [MaxReachability reachabilityWithHostname:@"www.google.com"];
    NetworkType reachableState = NetworkTypeNone;
    if ([reach isReachable]) {
        if ([reach isReachableViaWiFi]) {
            reachableState = NetworkTypeWiFi;
        } else if ([reach isReachableViaWWAN]) {
            reachableState = NetworkTypeCellular;
        }
    }
    return reachableState;
}

+ (BOOL)isMIMETypeCompatible:(MaxVASTMediaFile *)vastMediaFile
{
    NSString *pattern = @"(mp4|m4v|quicktime|3gpp)";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:vastMediaFile.type
                                      options:0
                                        range:NSMakeRange(0, [vastMediaFile.type length])];
    
    return ([matches count] > 0);
}

@end
