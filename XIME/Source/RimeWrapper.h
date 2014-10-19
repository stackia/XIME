//
//  RimeWrapper.h
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    RimeOptionASCIIMode,
    RimeOptionFullShape,
    RimeOptionASCIIPunct,
    RimeOptionSimplification,
    RimeOptionExtendedCharset,
} RimeOption;

@protocol RimeNotificationDelegate <NSObject>

@optional
- (void)onDeploymentStarted;
- (void)onDeploymentSuccessful;
- (void)onDeploymentFailed;
- (void)onSchemaChangedWithNewSchema:(NSString *)schema;
- (void)onOptionChangedWithOption:(RimeOption)option value:(BOOL)value;

@end

@interface RimeWrapper : NSObject

@property (nonatomic, strong) id<RimeNotificationDelegate> delegate;

+ (RimeWrapper *)sharedWrapper;

/// Start Rime service. This will setup notification handler, logging and deployer. And then start the service and perform a fast deployment.
- (BOOL)startService;

/// Stop Rime service.
- (void)stopService;

/// With fast == YES, Rime will get deployed only when there is a newer version of config. Otherwise it will always get deployed.
- (void)deployWithFastMode:(BOOL)fastMode;

/// Restart Rime service and perform a deployment.
- (void)redeployWithFastMode:(BOOL)fastMode;

@end
