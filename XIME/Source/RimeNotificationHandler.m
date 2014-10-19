//
//  RimeNotificationHandler.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/19/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "RimeNotificationHandler.h"

@implementation RimeNotificationHandler

- (void)onDeploymentStarted {
    NSLog(@"Deployment started.");
}

- (void)onDeploymentSuccessful {
    NSLog(@"Deployment successful.");
}

- (void)onDeploymentFailed {
    NSLog(@"Deployment failed.");
}

- (void)onSchemaChangedWithNewSchema:(NSString *)schema {
    NSLog(@"Schema changed to: %@", schema);
}

- (void)onOptionChangedWithOption:(RimeOption)option value:(BOOL)value {
    NSLog(@"Option changed: %lu, %d", option, value);
}

@end
