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

@synthesize xvim = _xvim;

- (NSUInteger)insertionPoint{
    NSRange range = [[self textView] selectedRange];
    return range.location + range.length;
}

- (XVIM_MODE)becameHandler:(XVim*)xvim{
    self.xvim = xvim;
    return MODE_NORMAL;
}



- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke ofXVim:(XVim*)xvim{
    // This is default implementation of evaluator.
    // Only keyDown events are supposed to be passed here.	
    // Invokes each key event handler
    // <C-k> invokes "C_k:" selector
	
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler)
	{
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler withObject:nil];
	}
    else{
        TRACE_LOG(@"SELECTOR %@ not found", NSStringFromSelector(handler));
        return [self defaultNextEvaluator];
    }
}

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_GLOBAL_MAP];
}

- (XVimEvaluator*)defaultNextEvaluator{
    return nil;
}

- (DVTSourceTextView*)textView{
    return [self.xvim sourceView];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (xregister.isReadOnly){
        return REGISTER_IGNORE;
    }
    return REGISTER_APPEND;
}

- (XVimEvaluator*)D_d:(id)arg{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}
@end


