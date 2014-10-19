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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // Create IMKServer
    if ([IMKServer sharedServer] == nil) {
        NSLog(@"Failed to create IMKServer.");
        [[NSApplication sharedApplication] terminate:self];
    }
    NSLog(@"IMKServer created.");
    
    // Set Rime notification handler
    [[RimeWrapper sharedWrapper] setDelegate:[self rimeNotificationHandler]];
    
    // Start Rime service
    if ([[RimeWrapper sharedWrapper] startService]) {
        NSLog(@"Rime service started.");
    } else {
        NSLog(@"Failed to start Rime service.");
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[RimeWrapper sharedWrapper] stopService];
    NSLog(@"IMKServer destroyed");
}

@end
