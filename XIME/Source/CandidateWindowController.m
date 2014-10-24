//
//  CandidateWindowController.m
//  XIME
//
//  Created by Saiqi Jia on 10/23/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "CandidateWindowController.h"

@interface CandidateWindowController ()

@end

@implementation CandidateWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[self window] setLevel:NSScreenSaverWindowLevel];
    [[self window] setOpaque:NO];
    [[self window] setBackgroundColor:[NSColor clearColor]];
}

- (void)updateWithRimeContext:(XRimeContext *)context caretRect:(NSRect)caretRect {
    if ([[[context menu] candidates] count] == 0) {
        // Hide window
        [[self window] orderOut:self];
    } else {
        
        // Resize window
        NSRect windowRect = [[self window] frame];
        
        // Reposition window
        windowRect.origin.x = NSMinX(caretRect);
        windowRect.origin.y = NSMinY(caretRect) - kXIMECandidateWindowPositionVerticalOffset - NSHeight(windowRect);
        
        // Fit in current screen
        NSRect screenRect = [[NSScreen mainScreen] frame];
        NSArray* screens = [NSScreen screens];
        NSUInteger i;
        for (i = 0; i < [screens count]; ++i) {
            NSRect rect = [[screens objectAtIndex:i] frame];
            if (NSPointInRect(caretRect.origin, rect)) {
                screenRect = rect;
                break;
            }
        }
        if (NSMaxX(windowRect) > NSMaxX(screenRect)) {
            windowRect.origin.x = NSMaxX(screenRect) - NSWidth(windowRect);
        }
        if (NSMinX(windowRect) < NSMinX(screenRect)) {
            windowRect.origin.x = NSMinX(screenRect);
        }
        if (NSMinY(windowRect) < NSMinY(screenRect)) {
            windowRect.origin.y = NSMaxY(caretRect) + kXIMECandidateWindowPositionVerticalOffset;
        }
        if (NSMaxY(windowRect) > NSMaxY(screenRect)) {
            windowRect.origin.y = NSMaxY(screenRect) - NSHeight(windowRect);
        }
        
        // Show window
        [[self window] setFrame:windowRect display:YES];
        [[self window] orderFront:self];
    }
}

@end
