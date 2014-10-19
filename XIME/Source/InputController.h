//
//  InputController.h
//  XIME
//
//  Created by Stackia <jsq2627@gmail.com> on 10/18/14.
//  Copyright (c) 2014 Stackia. All rights reserved.
//

#import <InputMethodKit/InputMethodKit.h>
#import "RimeWrapper.h"

@interface InputController : IMKInputController {
    RimeSessionId rimeSessionId_;
}

@end
