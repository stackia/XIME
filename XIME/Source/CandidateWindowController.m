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
        const int verticalOffet = 5;
        
        // Resize window
        NSRect windowRect = [[self window] frame];
        
        // Reposition window
        windowRect.origin.x = NSMinX(caretRect);
        windowRect.origin.y = NSMinY(caretRect) - NSHeight(caretRect) - verticalOffet;
        
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
            windowRect.origin.y = NSMaxY(caretRect) + verticalOffet;
        }
        if (NSMaxY(windowRect) > NSMaxY(screenRect)) {
            windowRect.origin.y = NSMaxY(screenRect) - NSHeight(windowRect);
        }
        if (NSMinY(windowRect) < NSMinY(screenRect)) {
            windowRect.origin.y = NSMinY(screenRect);
        }
        
        // Show window
        [[self window] setFrame:windowRect display:YES];
        [[self window] orderFront:self];
    }
}

@end
