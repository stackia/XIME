//
//  AppDelegate.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "AppDelegate.h"
#import "IMKServer+SharedInstance.h"
#import "RimeWrapper.h"

@implementation AppDelegate

#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // Create IMKServer
    if ([IMKServer sharedServer] == nil) {
        NSLog(@"Failed to create IMKServer.");
        [[NSApplication sharedApplication] terminate:self];
    }
    NSLog(@"IMKServer created.");
    
    // Set Rime notification handler
    [RimeWrapper setNotificationDelegate:self];
    
    // Start Rime service
    if ([RimeWrapper startService]) {
        NSLog(@"Rime service started.");
    } else {
        NSLog(@"Failed to start Rime service.");
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop Rime service
    [RimeWrapper stopService];
    
    // Destroy IMKServer
    NSLog(@"IMKServer destroyed");
}

#pragma mark Rime Notification Delegate

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

- (void)onOptionChangedWithOption:(XRimeOption)option value:(BOOL)value {
    NSLog(@"Option changed: %lu, %d", option, value);
}

@end
