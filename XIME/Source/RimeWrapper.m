//
//  RimeWrapper.m
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import "RimeWrapper.h"
#include "rime_api.h"

void notificationHandler(void* context_object, RimeSessionId session_id, const char* message_type, const char* message_value) {
    NSLog(@"Rime notification from session: %lu, type: %s, value: %s", session_id, message_type, message_value);
    
    id<RimeNotificationDelegate> notificationDelegate = [[RimeWrapper sharedWrapper] delegate];
    
    if (notificationDelegate == nil) {
        return;
    }
    
    if (!strcmp(message_type, "deploy")) { // Deployment state change
        
        if (!strcmp(message_value, "start")) {
            if ([notificationDelegate respondsToSelector:@selector(onDeploymentStarted)]) {
                [notificationDelegate onDeploymentStarted];
            }
        }
        else if (!strcmp(message_value, "success")) {
            if ([notificationDelegate respondsToSelector:@selector(onDeploymentSuccessful)]) {
                [notificationDelegate onDeploymentSuccessful];
            }
        }
        else if (!strcmp(message_value, "failure")) {
            if ([notificationDelegate respondsToSelector:@selector(onDeploymentFailed)]) {
                [notificationDelegate onDeploymentFailed];
            }
        }
        
    } else if (!strcmp(message_type, "schema") && [notificationDelegate respondsToSelector:@selector(onSchemaChangedWithNewSchema:)]) { // Schema change
        
        const char* schema_name = strchr(message_value, '/');
        if (schema_name) {
            ++schema_name;
            [notificationDelegate onSchemaChangedWithNewSchema:[NSString stringWithFormat:@"%s", schema_name]];
        }
        
    } else if (!strcmp(message_type, "option") && [notificationDelegate respondsToSelector:@selector(onOptionChangedWithOption:value:)]) { // Option change
        
        RimeOption option;
        BOOL value = (message_value[0] != '!');;
        
        if (!strcmp(message_value, "ascii_mode") || !strcmp(message_value, "!ascii_mode")) {
            option = RimeOptionASCIIMode;
        }
        else if (!strcmp(message_value, "full_shape") || !strcmp(message_value, "!full_shape")) {
            option = RimeOptionFullShape;
        }
        else if (!strcmp(message_value, "ascii_punct") || !strcmp(message_value, "!ascii_punct")) {
            option = RimeOptionASCIIPunct;
        }
        else if (!strcmp(message_value, "simplification") || !strcmp(message_value, "!simplification")) {
            option = RimeOptionSimplification;
        }
        else if (!strcmp(message_value, "extended_charset") || !strcmp(message_value, "!extended_charset")) {
            option = RimeOptionExtendedCharset;
        }
        
        [notificationDelegate onOptionChangedWithOption:option value:value];
        
    }
}

@implementation RimeWrapper

+ (RimeWrapper *)sharedWrapper {
    static dispatch_once_t onceToken;
    static RimeWrapper *wrapper;
    dispatch_once(&onceToken, ^{
        wrapper = [[RimeWrapper alloc] init];
    });
    return wrapper;
}

- (BOOL)startService {
    NSString *userDataDir = [[[[NSBundle mainBundle] infoDictionary] objectForKey:kXIMEUserDataDirectoryKey] stringByStandardizingPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:userDataDir]) {
        if (![fileManager createDirectoryAtPath:userDataDir withIntermediateDirectories:YES attributes:nil error:nil]) {
            NSLog(@"Failed to create user data directory.");
            return NO;
        }
    }
    
    RIME_STRUCT(RimeTraits, vXIMETraits);
    vXIMETraits.shared_data_dir = [[[NSBundle mainBundle] sharedSupportPath] UTF8String];
    vXIMETraits.user_data_dir = [userDataDir UTF8String];
    vXIMETraits.distribution_name = "XIME";
    vXIMETraits.distribution_code_name = "XIME";
    vXIMETraits.distribution_version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] UTF8String];
    vXIMETraits.app_name = "rime.xime";
    
    // Set Rime notification handler
    RimeSetNotificationHandler(notificationHandler, (__bridge void *)self);
    
    // Setup deployer and logging
    RimeSetup(&vXIMETraits);
    
    // Load modules and start service
    RimeInitialize(NULL);
    
    // Fast deploy
    [self deployWithFastMode:YES];
    
    return YES;
}

- (void)stopService {
    RimeCleanupAllSessions();
    RimeFinalize();
}

- (void)deployWithFastMode:(BOOL)fastMode {
    if (fastMode) {
        // If default.yaml config_version is changed, schedule a maintenance
        RimeStartMaintenance(False); // full_check = False to check config_version first, return True if a maintenance is triggered
    } else {
        // Maintenance with full check
        RimeStartMaintenance(True);
    }
}

- (void)redeployWithFastMode:(BOOL)fastMode {
    // Restart service
    RimeFinalize();
    RimeInitialize(NULL);
    
    // Deploy
    [self deployWithFastMode:fastMode];
}

- (RimeSessionId)createSession {
    return RimeCreateSession();
}

- (void)destroySession:(RimeSessionId)sessionId {
    RimeDestroySession(sessionId);
}

- (BOOL)isSessionAlive:(RimeSessionId)sessionId {
    return RimeFindSession(sessionId) == True;
}

- (BOOL)handleKeyForSession:(RimeSessionId)sessionId rimeKeyCode:(int)keyCode rimeModifier:(int)modifier {
    return RimeProcessKey(sessionId, keyCode, modifier);
}

- (BOOL)handleKeyForSession:(RimeSessionId)sessionId vOSXkeyCode:(int)keyCode keyChar:(char)keyChar vOSXModifier:(int)modifier {
    BOOL shift = modifier & NSShiftKeyMask;
    BOOL capsLock = modifier & NSAlphaShiftKeyMask;
    int rimeKeyCode = [self rimeKeyCodeForOSXKeyCode:keyCode keyChar:keyCode shift:shift capsLock:capsLock];
    int rimeModifier = [self rimeModifierForOSXModifier:modifier];
    return RimeProcessKey(sessionId, rimeKeyCode, rimeModifier);
}

- (int)rimeKeyCodeForOSXKeyCode:(int)keyCode keyChar:(char)keyChar shift:(BOOL)shift capsLock:(BOOL)capsLock {
    int ret = 0;
    
    switch (keyCode) {
        case kVK_Space:
            ret = XK_space;
            break;
        case kVK_Tab:
            ret = XK_Tab;
            break;
        case kVK_Return:
            ret = XK_Return;
            break;
        case kVK_Delete:
            ret = XK_BackSpace;
            break;
        case kVK_Escape:
            ret = XK_Escape;
            break;
        case kVK_PageUp:
            ret = XK_Prior;
            break;
        case kVK_PageDown:
            ret = XK_Next;
            break;
        case kVK_End:
            ret = XK_End;
            break;
        case kVK_Home:
            ret = XK_Home;
            break;
        case kVK_LeftArrow:
            ret = XK_Left;
            break;
        case kVK_UpArrow:
            ret = XK_Up;
            break;
        case kVK_RightArrow:
            ret = XK_Right;
            break;
        case kVK_DownArrow:
            ret = XK_Down;
            break;
        case kVK_ForwardDelete:
            ret = XK_Delete;
            break;
        case kVK_Control:
            ret = XK_Control_L;
            break;
        case kVK_RightControl:
            ret = XK_Control_R;
            break;
        case kVK_Shift:
            ret = XK_Shift_L;
            break;
        case kVK_RightShift:
            ret = XK_Shift_R;
            break;
        case kVK_Option:
            ret = XK_Alt_L;
            break;
        default:
            /* NOTE:
             * IBus/Rime use different keycodes for uppercase/lowercase letters.
             */
            if ((shift != capsLock) && keyChar >= 'a' && keyChar <= 'z') {
                keyChar -= 'a' - 'A';
            }
            if (keyChar >= 0x20 && keyChar <= 0x7e) {
                ret = keyChar;
            }
            else if (keyChar == 0x1b) {  // ^[ left bracket
                ret = XK_bracketleft;
            }
            else if (keyChar == 0x1c) {  // ^\ backslash
                ret = XK_backslash;
            }
            else if (keyChar == 0x1d) {  // ^] right bracket
                ret = XK_bracketright;
            }
            else if (keyChar == 0x1f) {  // ^_ minus
                ret = XK_minus;
            }
            break;
    }
    
    return ret;
}

- (int)rimeModifierForOSXModifier:(int)modifier {
    int ret = 0;
    
    if (modifier & NSAlphaShiftKeyMask)
        ret |= kLockMask;
    if (modifier & NSShiftKeyMask)
        ret |= kShiftMask;
    if (modifier & NSControlKeyMask)
        ret |= kControlMask;
    if (modifier & NSAlternateKeyMask)
        ret |= kAltMask;
    if (modifier & NSCommandKeyMask)
        ret |= kSuperMask;
    
    return ret;
}

@end