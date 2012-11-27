//
//  XVimShiftEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimShiftEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimWindow.h"

@interface XVimShiftEvaluator() {
	BOOL _unshift;
}
@end

@implementation XVimShiftEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*)action 
				  withParent:(XVimEvaluator*)parent
					 unshift:(BOOL)unshift
{
	if (self = [super initWithContext:context operatorAction:action withParent:parent]) {
		self->_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    if( !_unshift ){
        if ([self numericArg] < 1)
        return nil;
    
        XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
        return [self _motionFixed:m inWindow:window];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
    if( _unshift ){
        if ([self numericArg] < 1)
        return nil;
    
        XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
        return [self _motionFixed:m inWindow:window];
    }
    return nil;
}

- (XVimEvaluator*)_motionFixed:(XVimMotion *)motion inWindow:(XVimWindow *)window{
    if( _unshift ){
        [[window sourceView] shiftLeft:motion];
    }else{
        [[window sourceView] shiftRight:motion];
    }
    return nil;
}
@end
