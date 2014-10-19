//
//  AppDelegate.h
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RimeNotificationHandler.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSApplication *owner;
@property (weak) IBOutlet NSObject *app;

@property (nonatomic, strong) RimeNotificationHandler *rimeNotificationHandler;

@end

