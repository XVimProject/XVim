//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.  
//  Copyright 2012 JugglerShu.Net. All rights reserved.  
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimKeyStroke.h"
#import "Logger.h"
#import "XVim.h"

@implementation XVimEvaluator

- (XVIM_MODE)becameHandler:(XVim*)xvim{
    return MODE_NORMAL;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke XVim:(XVim*)xvim{
    // This is default implementation of evaluator.
    // Only keyDown events are supposed to be passed here.	
    // Invokes each key event handler
    // <C-k> invokes "C_k:" selector
	
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler)
	{
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler withObject:xvim];
	}
    else{
        TRACE_LOG(@"SELECTOR %@ not found", NSStringFromSelector(handler));
        return [self defaultNextEvaluatorWithXVim:xvim];
    }
}

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_GLOBAL_MAP];
}

- (XVimEvaluator*)defaultNextEvaluatorWithXVim:(XVim*)xvim{
    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (xregister.isReadOnly){
        return REGISTER_IGNORE;
    }
    return REGISTER_APPEND;
}

- (NSUInteger)insertionPoint:(XVim*)xvim {
    NSRange range = [[xvim sourceView] selectedRange];
    return range.location + range.length;
}

- (XVimEvaluator*)D_d:(XVim*)xvim{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}
@end


