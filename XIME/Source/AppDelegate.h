//
//  AppDelegate.h
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "RimeWrapper.h"
#import "CandidateWindowController.h"
#include "InputController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, RimeNotificationDelegate>

@property (weak) IBOutlet NSMenu *mainMenu;

@property (strong) CandidateWindowController *candidateWindowController;
@property (weak) InputController *currentInputController; // Keeps most recently active input controller

@end
