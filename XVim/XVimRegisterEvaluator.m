//
//  XVimRegisterEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegisterEvaluator.h"
#import "XVimNormalEvaluator.h"
#import "XVimRegister.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
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

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    XVimRegister *xregister = [[XVim instance] findRegister:[keyStroke toSelectorString]];
    if (_mode == REGISTER_EVAL_MODE_YANK){
        if (xregister.isReadOnly == NO){
            return [[XVimNormalEvaluator alloc] initWithYankRegister:xregister];
        }else{
            [[XVim instance] ringBell];
        }
    } else if (_mode == REGISTER_EVAL_MODE_RECORD){
        if (xregister.isReadOnly == NO){
            [window recordIntoRegister:xregister];
        }else{
            [[XVim instance] ringBell];
        }
    } else if (_mode == REGISTER_EVAL_MODE_PLAYBACK){
        return [[XVimNormalEvaluator alloc] initWithRegister:xregister andPlaybackCount:_count];
    }

    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    return REGISTER_IGNORE;
}

@end