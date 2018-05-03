//
//  MAXObjCVungleConfiguration.h
//  MAX
//
//  Created by Bryan Boyko on 5/2/18.
//  Copyright © 2018 Bryan Boyko. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MAXObjCVungleConfigurationDelegate;


@interface MAXObjCVungleConfiguration : NSObject

+ (MAXObjCVungleConfiguration *)shared;

- (void)initializeVungleSDKWithAppId:(NSString *)appId placementIds:(NSArray <NSString *> *)placementIds enabledLogging:(BOOL)enableLogging;

- (NSString *)vungleSDKVersion;


@property (nonatomic, strong) id<MAXObjCVungleConfigurationDelegate> delegate;

@end


@protocol MAXObjCVungleConfigurationDelegate <NSObject>

- (void)vungleError:(NSError *)error;

@end
