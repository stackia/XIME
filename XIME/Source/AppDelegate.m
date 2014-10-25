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
#import "InputController.h"

@implementation AppDelegate {
    IBOutlet NSMenuItem *menuItemRedeploy_;
    IBOutlet NSMenuItem *menuItemShowPreferences_;
}

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
    
    // Initialize candidate window controller
    [self setCandidateWindowController:[[CandidateWindowController alloc] initWithWindowNibName:@"CandidateWindowController"]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop Rime service
    [RimeWrapper stopService];
    
    // Destroy IMKServer
    NSLog(@"IMKServer destroyed");
}

- (void)awakeFromNib {
    // Set menu item actions
    // These selectors will be passed to InputController, instead of AppDelegate
    [menuItemRedeploy_ setAction:@selector(menuActionRedeploy:)];
    [menuItemShowPreferences_ setAction:@selector(menuActionShowPreferences:)];
}

#pragma mark Rime Notification Delegate

- (void)onDeploymentStarted {
    NSLog(@"Deployment started.");
    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"XIME Input Method Editor"];
    [notification setSubtitle:@"Deploying..."];
    [notification setInformativeText:@"Wait a second..."];
    [userNotificationCenter removeAllDeliveredNotifications];
    [userNotificationCenter deliverNotification:notification];
}

- (void)onDeploymentSuccessful {
    NSLog(@"Deployment successful.");
    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"XIME Input Method Editor"];
    [notification setSubtitle:@"Deployment successful!"];
    [notification setInformativeText:@"Have fun :)"];
    [userNotificationCenter removeAllDeliveredNotifications];
    [userNotificationCenter deliverNotification:notification];
}

- (void)onDeploymentFailed {
    NSLog(@"Deployment failed.");
    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"XIME Input Method Editor"];
    [notification setSubtitle:@"Deployment failed!"];
    [notification setInformativeText:@"Failed to load your custom settings and schemas."];
    [userNotificationCenter removeAllDeliveredNotifications];
    [userNotificationCenter deliverNotification:notification];
}

- (void)onSchemaChangedWithNewSchema:(NSString *)schema {
    NSLog(@"Schema changed to: %@", schema);
}

- (void)onOptionChangedWithOption:(XRimeOption)option value:(BOOL)value {
    NSLog(@"Option changed: %lu, %d", option, value);
}

@end
