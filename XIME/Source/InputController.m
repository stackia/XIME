//
//  InputController.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "InputController.h"
#import "AppDelegate.h"
#import "CandidateWindowController.h"

@implementation InputController {
    RimeSessionId rimeSessionId_; // Holds corresponding Rime session id of this input controller
    BOOL committed_; // Indicate whether XIME has committed composed text
    BOOL canceled_; // Indicate whether XIME has canceled composition.
    NSMutableAttributedString *composedText_;
    int cursorPosition_; // Cursor position in the composed text
}

#pragma mark IMKServerInput Delegate

/* We choose the 'handleEvent:client:' way to receive input events from the client. */
- (BOOL)handleEvent:(NSEvent *)event client:(id)sender {
    
    BOOL handled = NO;
    NSEventType eventType = [event type];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
    
    // Rime session may failed to create during deployment, so here is a second check to make sure there is an available sessios.
    if (![RimeWrapper isSessionAlive:rimeSessionId_]) {
        rimeSessionId_ = [RimeWrapper createSession];
        if (!rimeSessionId_) { // If still failed to create Rime session, do not handle this event.
            return NO;
        }
    }
    
    if (eventType == NSKeyDown) { // Key down event
        
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
        
        static NSEventModifierFlags lastModifierFlags = 0;
        NSEventModifierFlags flagDelta = lastModifierFlags ^ modifierFlags;
        lastModifierFlags = modifierFlags;
        
        int rimeModifier = [RimeWrapper rimeModifierForOSXModifier:modifierFlags];
        
        if (flagDelta & NSAlphaShiftKeyMask) { // CapsLock key
            /* NOTE: Rime assumes XK_Caps_Lock to be sent before modifier changes, while NSFlagsChanged event has the flag changed already. So it is necessary to revert kLockMask. */
            rimeModifier ^= kLockMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Caps_Lock rimeModifier:rimeModifier];
        }
        
        if (flagDelta & NSShiftKeyMask) { // Shift key
            int releaseMask = modifierFlags & NSShiftKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Shift_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSControlKeyMask) { // Control key
            int releaseMask = modifierFlags & NSControlKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Control_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSAlternateKeyMask) { // Option key
            int releaseMask = modifierFlags & NSAlternateKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Alt_L rimeModifier:rimeModifier | releaseMask];
        }
        
        if (flagDelta & NSCommandKeyMask) { // Command key
            int releaseMask = modifierFlags & NSCommandKeyMask ? 0 : kReleaseMask;
            [RimeWrapper inputKeyForSession:rimeSessionId_ rimeKeyCode:XK_Super_L rimeModifier:rimeModifier | releaseMask];
            // Do not update UI when using Command key
        }
        
        [self syncWithRime];
        handled = NO; // Pass event down to the responder chain
        
    } else if (eventType == NSLeftMouseDown) { // Left mouse down event
        
        [self cancelComposition];
        handled = NO; // Pass event down to the responder chain
        
    }
    
    return handled;
}

- (id)composedString:(id)sender {
    return composedText_;
}

- (NSAttributedString *)originalString:(id)sender {
    return composedText_;
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
 *  XIME Candidate Window <-- Rime Context
 *
 * Action:
 *  XIME Commit Composition --> Rime Commit Composition
 *  XIME Insert Text <-- Rime Commit Composition
 *  XIME Cancel Composition --> Rime Clear Composition
 */
- (void)syncWithRime {
    
    if (!rimeSessionId_) { // Cannot sync if there is no rime session
        return;
    }
    
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
    
    // Action: XIME Cancel Composition --> Rime Clear Composition
    if (canceled_) {
        canceled_ = NO;
        [RimeWrapper clearCompositionForSession:rimeSessionId_];
    }
    
    XRimeContext *context = [RimeWrapper contextForSession:rimeSessionId_];

    // Data: XIME Composed Text <-- Rime Context Preedited Text
    XRimeComposition *composition = [context composition];
    composedText_ = [[NSMutableAttributedString alloc] initWithString:[[context composition] preeditedText]];
    NSRange convertedRange = NSMakeRange(0, [composition selectionStart]);
    NSRange selectedRange = NSMakeRange([composition selectionStart], [composition selectionEnd] - [composition selectionStart]);
    [composedText_ setAttributes:[self markForStyle:kTSMHiliteConvertedText atRange:convertedRange] range:convertedRange]; // Text attribute for converted text
    [composedText_ setAttributes:[self markForStyle:kTSMHiliteSelectedRawText atRange:selectedRange] range:selectedRange]; // Text attribute for uncoverted text
    cursorPosition_ = [composition cursorPosition];
    [self updateComposition];
    
    // Data: XIME Candidate Window <-- Rime Context
#pragma mark TODO: XIME Candidate Window <-- Rime Context Candidates
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    CandidateWindowController *candidateWindowController = [appDelegate candidateWindowController];
    NSRect caretRect;
    [[self client] attributesForCharacterIndex:0 lineHeightRectangle:&caretRect];
    [candidateWindowController updateWithRimeContext:context caretRect:caretRect];
}

#pragma mark IMKStateSetting Delegate

- (void)deactivateServer:(id)sender {
#warning Known issue: When switching IME, the system will first call commitComposition: then deactivateServer:. The cancelComposition: method here doesn't really make a difference.
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

// Rewrite this method because the original one will crash when using ARC
- (void)updateComposition {
    NSAttributedString *composedString = [self composedString:self];
    [[self client] setMarkedText:composedString selectionRange:[self selectionRange] replacementRange:[self replacementRange]];
}

// Rewrite this method because the original one will crash when using ARC
- (void)cancelComposition {
    [[self client] insertText:[self originalString:self] replacementRange:[self replacementRange]];
    canceled_ = YES;
    [self syncWithRime];
}

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
    if (self = [super initWithServer:server delegate:delegate client:inputClient]) {
        rimeSessionId_ = [RimeWrapper createSession]; // Try to create Rime session
    }
    return self;
}

- (void)hidePalettes {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [[appDelegate candidateWindowController] hideWindow:self];
}

- (NSMenu *)menu {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    return [appDelegate mainMenu];
}

- (void)inputControllerWillClose {
    // Destroy Rime session
    if ([RimeWrapper isSessionAlive:rimeSessionId_]) {
        [RimeWrapper destroySession:rimeSessionId_];
    }
}

#pragma mark Menu item actions

- (void)menuActionRedeploy:(id)sender {
    [RimeWrapper redeployWithFastMode:NO];
}

- (void)menuActionShowPreferences:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[[[[NSBundle mainBundle] infoDictionary] objectForKey:kXIMEUserDataDirectoryKey] stringByStandardizingPath]];
}

@end
