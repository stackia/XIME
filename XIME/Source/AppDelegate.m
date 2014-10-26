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
    id keyUpEventMonitor_;
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
    
    // Add a global key up event hook
    keyUpEventMonitor_ = [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyUpMask handler:^(NSEvent *event) {
        [self handleKeyUpEvent:event];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop Rime service
    [RimeWrapper stopService];
    
    // Destroy IMKServer
    NSLog(@"IMKServer destroyed");
    
    // Remove key up hook
    [NSEvent removeMonitor:keyUpEventMonitor_];
}

- (void)awakeFromNib {
    // Set menu item actions
    // These selectors will be passed to InputController, instead of AppDelegate
    [menuItemRedeploy_ setAction:@selector(menuActionRedeploy:)];
    [menuItemShowPreferences_ setAction:@selector(menuActionShowPreferences:)];
}

#pragma mark Key Up Event Handler

/**
 * We create only one key up handler here.
 * At first I try to put this in InputController but that leads to all input controller receiving the same key up event.
 */
- (void)handleKeyUpEvent:(NSEvent *)event {
    if ([self currentInputController] == nil) {
        return;
    }
    RimeSessionId currentRimeSessionId = [[self currentInputController] rimeSessionId];
    if ([RimeWrapper getOptionStateForSession:currentRimeSessionId optionName:@"_chord_typing"]) { // If Rime chord composer enabled
        char keyChar = [[event characters] UTF8String][0]; // Case sensitive, already handled correctly by system
        
        int rimeKeyCode = [RimeWrapper rimeKeyCodeForOSXKeyCode:[event keyCode]];
        if (!rimeKeyCode) { // If this is not a special keyCode we could recognize, then get keyCode from keyChar.
            rimeKeyCode = [RimeWrapper rimeKeyCodeForKeyChar:keyChar];
        }
        int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:[event modifierFlags]];
        [RimeWrapper inputKeyForSession:currentRimeSessionId rimeKeyCode:rimeKeyCode rimeModifier:rimeModifier | kReleaseMask];
        
        [[self currentInputController] syncWithRime];
    }
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
