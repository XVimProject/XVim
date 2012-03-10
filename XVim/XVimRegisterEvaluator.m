//
//  XVimRegisterEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegisterEvaluator.h"
#import "XVimRegister.h"
#import "XVim.h"
#import "Logger.h"

@implementation XVimRegisterEvaluator

NSUInteger _count;
XVimRegisterEvalMode _mode;

-(id)initWithMode:(XVimRegisterEvalMode)mode andCount:(NSUInteger)count{
    self = [super init];
    if (self != nil){
        _mode = mode;
        _count = count;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent*) event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    XVimRegister *xregister = [xvim findRegister:keyStr];
    if (_mode == REGISTER_EVAL_MODE_RECORD){
        TRACE_LOG(@"handling record key: %@ register: %@", keyStr, xregister);
        if (xregister.isReadOnly == NO){
            [xvim recordIntoRegister:xregister];
        }else{
            [xvim ringBell];
        }
    } else if(_mode == REGISTER_EVAL_MODE_PLAYBACK){
        TRACE_LOG(@"handling playback key %@", keyStr);
        [xvim playbackRegister:xregister withRepeatCount:_count];
    }
    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    return REGISTER_IGNORE;
}

@end
