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
    
    [[self window] setOpaque:NO];
    [[self window] setBackgroundColor:[NSColor clearColor]];
}

- (void)updateWithRimeContext:(XRimeContext *)context caretRect:(NSRect)caretRect {
    NSWindow *window = [self window];
    if ([[[context menu] candidates] count] == 0) {
        // Hide window
        [window orderOut:self];
    } else {
        // Compose candidates
        NSMutableAttributedString *candidateText = [[NSMutableAttributedString alloc] init];
        NSArray *candidates = [[context menu] candidates];
        for (int i = 0; i < [candidates count]; ++i) {
            XRimeCandidate *candidate = [candidates objectAtIndex:i];
            [candidateText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d ", i + 1]]];
            [candidateText appendAttributedString:[[NSAttributedString alloc] initWithString:[candidate text]]];
            if (i != [candidates count] - 1) {
                [candidateText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
        }
        [[self mainTextField] setAttributedStringValue:candidateText];
        
        // Update window size (use auto layout to resize window frame)
        [[self mainTextFieldWidth] setConstant:[[self mainTextField] intrinsicContentSize].width]; // But we have to set text field width manuelly
        [[self window] layoutIfNeeded];
        
        // Reposition window
        NSRect windowRect = [window frame];
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
        [window setFrame:windowRect display:YES];
        [window orderFront:self];
    }
}

- (void)hideWindow:(id)sender {
    [[self window] orderOut:sender];
}

- (void)setWindowLevel:(CGWindowLevel)level {
    [[self window] setLevel:level];
}

@end
