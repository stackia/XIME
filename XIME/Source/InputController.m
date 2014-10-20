//
//  InputController.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "InputController.h"

@implementation InputController {
    RimeSessionId rimeSessionId_; // Holds corresponding Rime session id of this input controller
}

#pragma mark IMKServerInput Delegate

/* We choose the 'handleEvent:client:' way to receive input events from the client. */

- (NSUInteger)recognizedEvents:(id)sender {
    return NSKeyDownMask | NSFlagsChangedMask | NSLeftMouseDownMask; // Receive KeyDown/ModifierFlagsChange/LeftMouseDown events
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    NSLog(@"Event received, type: %lu", [event type]);
    
    NSEventType eventType = [event type];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
    
    if (eventType == NSKeyDown) { // Key down event
        
        NSLog(@"[KeyDown] Key char: '%@', key code: %hu, modifier: %lu", [event characters], [event keyCode], modifierFlags);
        
        char keyChar = [[event characters] UTF8String][0]; // Case sensitive, already handled correctly by system
        
        int rimeKeyCode = [RimeWrapper rimeKeyCodeForKeyChar:keyChar];
        int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
        [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:rimeKeyCode rimeModifier:rimeModifier];
        
    } else if (eventType == NSFlagsChanged) { // Modifier flags changed event
        
        NSLog(@"[FlagsChanged] Modifier: %lu", modifierFlags);
        
        static NSEventModifierFlags lastModifierFlags = 0;
        NSEventModifierFlags flagDelta = lastModifierFlags ^ modifierFlags;
        lastModifierFlags = modifierFlags;
        
        int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
        
        if (flagDelta & NSAlphaShiftKeyMask) // CapsLock key
        {
            /* NOTE: Rime assumes XK_Caps_Lock to be sent before modifier changes, while NSFlagsChanged event has the flag changed already. So it is necessary to revert kLockMask. */
            rimeModifier ^= kLockMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Caps_Lock rimeModifier:rimeModifier];
        }
        
        if (flagDelta & NSShiftKeyMask) // Shift key
        {
            int releaseMask = modifierFlags & NSShiftKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Shift_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSControlKeyMask) // Control key
        {
            int releaseMask = modifierFlags & NSControlKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Control_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSAlternateKeyMask) // Option key
        {
            int releaseMask = modifierFlags & NSAlternateKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Alt_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSCommandKeyMask) // Command key
        {
            int releaseMask = modifierFlags & NSCommandKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Super_L rimeModifier:rimeModifier | releaseMask];
            // Do not update UI when using Command key
        }
        
    } else if (eventType == NSLeftMouseDown) { // Left mouse down event
        
        NSLog(@"[LeftMouseDown]");
        
    }
    
    return NO;
}

#pragma mark IMKStateSetting Delegate

#pragma mark IMKMouseHandling Delegate

#pragma mark IMKInputController Override

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
    if (self = [super initWithServer:server delegate:delegate client:inputClient]) {
        // Create Rime session
        rimeSessionId_ = [RimeWrapper createSession];
        NSLog(@"Rime session created: %lu", rimeSessionId_);
    }
    return self;
}

- (void)dealloc {
    // Destroy Rime session
    if ([RimeWrapper isSessionAlive:rimeSessionId_]) {
        [RimeWrapper destroySession:rimeSessionId_];
    }
    NSLog(@"Rime session destroyed: %lu", rimeSessionId_);
}

@end
