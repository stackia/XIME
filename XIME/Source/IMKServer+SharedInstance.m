//
//  IMKServer+SharedInstance.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "IMKServer+SharedInstance.h"

@implementation IMKServer (SharedInstance)

+ (IMKServer *)sharedServer {
    static IMKServer *server;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        server = [[IMKServer alloc] initWithName:[IMKServer connectionName] bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    });
    return server;
}

+ (NSString *)connectionName {
    NSString *connectionName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"InputMethodConnectionName"];
    return connectionName;
}

@end
