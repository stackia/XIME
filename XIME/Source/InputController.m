//
//  InputController.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "InputController.h"

@implementation InputController

#pragma mark Handle input events

- (NSUInteger)recognizedEvents:(id)sender {
    return NSKeyDownMask | NSFlagsChangedMask | NSLeftMouseDownMask;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    NSLog(@"Event: %lu", [event type]);
    
    // Create Rime session if it doesn't exist
    if (![RimeWrapper isSessionAlive:rimeSessionId_]) {
        rimeSessionId_ = [RimeWrapper createSession];
        NSLog(@"Rime session created: %lu", rimeSessionId_);
    }
    
    NSEventType eventType = [event type];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
    
    if (eventType == NSKeyDown) { // Key down event
        
        NSLog(@"KeyDown: %@, %hu, %lu", [event characters], [event keyCode], modifierFlags);
        
        int keyCode = [event keyCode];
        char keyChar = [[event charactersIgnoringModifiers] UTF8String][0];
        [RimeWrapper handleKeyForSession:rimeSessionId_ vOSXkeyCode:keyCode keyChar:keyChar vOSXModifier:modifierFlags];
        
    } else if (eventType == NSFlagsChanged) { // Modifier flag changed event
        
        NSLog(@"FlagsChanged: %lu", modifierFlags);
        
        static NSEventModifierFlags lastModifierFlags = 0;
        NSEventModifierFlags flagDelta = lastModifierFlags ^ modifierFlags;
        lastModifierFlags = modifierFlags;
        
        int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
        
        if (flagDelta & NSAlphaShiftKeyMask)
        {
            // NOTE: rime assumes XK_Caps_Lock to be sent before modifier changes,
            // while NSFlagsChanged event has the flag changed already.
            // so it is necessary to revert kLockMask.
            rimeModifier ^= kLockMask;
            [RimeWrapper handleKeyForSession:rimeSessionId_ rimeKeyCode:XK_Caps_Lock rimeModifier:rimeModifier];
        }
        
        if (flagDelta & NSShiftKeyMask)
        {
            int releaseMask = modifierFlags & NSShiftKeyMask ? 0 : kReleaseMask;
            [RimeWrapper handleKeyForSession:rimeSessionId_ rimeKeyCode:XK_Shift_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSControlKeyMask)
        {
            int releaseMask = modifierFlags & NSControlKeyMask ? 0 : kReleaseMask;
            [RimeWrapper handleKeyForSession:rimeSessionId_ rimeKeyCode:XK_Control_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSAlternateKeyMask)
        {
            int releaseMask = modifierFlags & NSAlternateKeyMask ? 0 : kReleaseMask;
            [RimeWrapper handleKeyForSession:rimeSessionId_ rimeKeyCode:XK_Alt_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSCommandKeyMask)
        {
            int releaseMask = modifierFlags & NSCommandKeyMask ? 0 : kReleaseMask;
            [RimeWrapper handleKeyForSession:rimeSessionId_ rimeKeyCode:XK_Super_L rimeModifier:rimeModifier | releaseMask];
            // Do not update UI when using Command key
        }
        
    } else if (eventType == NSLeftMouseDown) { // Left mouse down event
        
        NSLog(@"LeftMouseDown");
        
    }
    
    return NO;
}

- (void)dealloc {
    // Destroy Rime session
    if ([RimeWrapper isSessionAlive:rimeSessionId_]) {
        [RimeWrapper destroySession:rimeSessionId_];
    }
    NSLog(@"Rime session destroyed: %lu", rimeSessionId_);
}

@end
