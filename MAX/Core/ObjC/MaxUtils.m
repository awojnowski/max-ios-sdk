//
//  MaxUtils.m
//  MAX
//
//  Created by Bryan Boyko on 3/14/18.
//

#import "MaxUtils.h"
#import <UIKit/UIKit.h>

@implementation MaxUtils

+ (IPhoneType)iPhoneType
{
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
        switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
            case 1136:
                return IPhoneType5_5S_5C;
                break;
            case 1334:
                return IPhoneType6_6S_7_8;
                break;
            case 1920:
                return IPhoneType6_6S_7_8_Plus;
                break;
            case 2208:
                return IPhoneType6_6S_7_8_Plus;
                break;
            case 2436:
                return IPhoneTypeX;
                break;
            default:
                return IPhoneTypeNone;
        }
    }
    return IPhoneTypeNone;
}

@end
