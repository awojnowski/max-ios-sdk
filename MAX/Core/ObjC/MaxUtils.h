//
//  MaxUtils.h
//  MAX
//
//  Created by Bryan Boyko on 3/14/18.
//

#import <Foundation/Foundation.h>

typedef enum {
    IPhoneTypeNone,
    IPhoneType5_5S_5C,
    IPhoneType6_6S_7_8,
    IPhoneType6_6S_7_8_Plus,
    IPhoneTypeX
} IPhoneType;

@interface MaxUtils : NSObject

+ (IPhoneType)iPhoneType;

@end
