//
//  XVimRegisterEvaluator.h
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

typedef enum {
    REGISTER_EVAL_MODE_YANK,
    REGISTER_EVAL_MODE_RECORD,
    REGISTER_EVAL_MODE_PLAYBACK
} XVimRegisterEvalMode;

@interface XVimRegisterEvaluator : XVimEvaluator

-(id)initWithMode:(XVimRegisterEvalMode)mode andCount:(NSUInteger)count;

@end
