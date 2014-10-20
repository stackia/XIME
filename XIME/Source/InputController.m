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
    BOOL committed_; // Indicate whether XIME has committed composed text
    NSMutableAttributedString *composedText_;
    int cursorPosition_; // Cursor position in the composed text
}

#pragma mark IMKServerInput Delegate

/* We choose the 'handleEvent:client:' way to receive input events from the client. */
- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    NSLog(@"Event received, type: %lu", [event type]);
    
    BOOL handled = NO;
    NSEventType eventType = [event type];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
    
    // Rime session may failed to create during deployment, so here is a second check to make sure there is an available sessios.
    if (![RimeWrapper isSessionAlive:rimeSessionId_]) {
        rimeSessionId_ = [RimeWrapper createSession];
        if (!rimeSessionId_) { // If still failed to create Rime session, do not handle this event.
            return NO;
        }
        NSLog(@"Rime session created: %lu", rimeSessionId_);
    }
    
    if (eventType == NSKeyDown) { // Key down event
        
        NSLog(@"[KeyDown] Key char: '%@', key code: %hu, modifier: %lu", [event characters], [event keyCode], modifierFlags);
        
        if (modifierFlags & NSCommandKeyMask) { // 'Command + <key>' events will also be passed to here. We will ignore them.
            handled = NO;
        } else {
            char keyChar = [[event characters] UTF8String][0]; // Case sensitive, already handled correctly by system
        
            int rimeKeyCode = [RimeWrapper rimeKeyCodeForOSXKeyCode:[event keyCode]];
            if (!rimeKeyCode) { // If this is not a special keyCode we could recognize, then get keyCode from keyChar.
                rimeKeyCode = [RimeWrapper rimeKeyCodeForKeyChar:keyChar];
            }
            int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
            handled = [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:rimeKeyCode rimeModifier:rimeModifier];
        
            [self syncWithRime];
        }
        
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
        
        [self syncWithRime];
        handled = NO; // Pass event down to the responder chain
        
    } else if (eventType == NSLeftMouseDown) { // Left mouse down event
        
        NSLog(@"[LeftMouseDown]");
        
        [self cancelComposition];
        handled = NO; // Pass event down to the responder chain
        
    }
    
    return handled;
}

- (id)composedString:(id)sender {
    return composedText_;
}

- (NSAttributedString *)originalString:(id)sender {
#pragma mark TODO: Get original string from Rime service
    return [[NSAttributedString alloc] initWithString:@""];
}

- (void)commitComposition:(id)sender {
    committed_ = YES;
    [self syncWithRime];
}

#pragma mark Sync With Rime Service

/**
 * We have to sync data and action between XIME and Rime with the following strategy:
 *
 * Data:
 *  XIME Composed Text <-- Rime Context Preedited Text
 *  XIME Candidate Window <-- Rime Context Candidates
 *
 * Action:
 *  XIME Commit Composition --> Rime Commit Composition
 *  XIME Insert Text <-- Rime Commit Composition
 */
- (void)syncWithRime {
    
    // Action: XIME Commit Composition --> Rime Commit Composition
    if (committed_) { // Flagged in commitComposition:(id)sender
        committed_ = NO;
        [RimeWrapper commitCompositionForSession:rimeSessionId_];
    }
    
    // Action: XIME Insert Text <-- Rime Commit Composition
    NSString *rimeComposedText = [RimeWrapper consumeComposedTextForSession:rimeSessionId_];
    if (rimeComposedText) { // If there is composed text to consume, we can infer that Rime did commit action
        [[self client] insertText:rimeComposedText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }
    
    XRimeContext *context = [RimeWrapper contextForSession:rimeSessionId_];

    // Data: XIME Composed Text <-- Rime Context Preedited Text
    XRimeComposition *composition = [context composition];
    composedText_ = [[NSMutableAttributedString alloc] initWithString:[[context composition] preeditedText]];
#warning Need UTF-8 fix for cursor position
    cursorPosition_ = [composition cursorPosition];
#pragma mark TODO: Add text attribute for converted text and selected raw text
    [self updateComposition];
    
    // Data: XIME Candidate Window <-- Rime Context Candidates
#pragma mark TODO: XIME Candidate Window <-- Rime Context Candidates
    NSArray *candidates = [[context menu] candidates];
    if ([candidates count] > 0)
        NSLog(@"Candidates:");
    int i = 0;
    for (XRimeCandidate *candidate in candidates) {
        ++i;
        NSLog(@"%d: %@, %@", i, [candidate text], [candidate comment]);
    }
}

#pragma mark IMKStateSetting Delegate

- (void)deactivateServer:(id)sender {
    [self cancelComposition];
}

- (NSUInteger)recognizedEvents:(id)sender {
    return NSKeyDownMask | NSFlagsChangedMask | NSLeftMouseDownMask; // Receive KeyDown/ModifierFlagsChange/LeftMouseDown events
}

#pragma mark IMKMouseHandling Delegate

#pragma mark IMKInputController Override

- (NSRange)selectionRange {
    return NSMakeRange(cursorPosition_, 0);
}

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
    if (self = [super initWithServer:server delegate:delegate client:inputClient]) {
        rimeSessionId_ = [RimeWrapper createSession]; // Try to create Rime session
        if (rimeSessionId_ ) {
            NSLog(@"Rime session created: %lu", rimeSessionId_);
        }
    }
    return self;
}

- (void)inputControllerWillClose {
    // Destroy Rime session
    if ([RimeWrapper isSessionAlive:rimeSessionId_]) {
        [RimeWrapper destroySession:rimeSessionId_];
    }
    NSLog(@"Rime session destroyed: %lu", rimeSessionId_);
}

@end
