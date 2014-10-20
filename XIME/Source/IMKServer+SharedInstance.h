//
//  IMKServer+SharedInstance.h
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import <InputMethodKit/InputMethodKit.h>

@interface IMKServer (SharedInstance)

/// Get IMKSercer connection name from Info.plist
+ (NSString *)connectionName;

/// Get shared IMKServer object
+ (IMKServer *)sharedServer;

@end
