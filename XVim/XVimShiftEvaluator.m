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

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow *)window withParent:(XVimEvaluator*)parent unshift:(BOOL)unshift
{
	if (self = [super initWithContext:context withWindow:window withParent:parent]) {
		_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)GREATERTHAN{
    if( !_unshift ){
        if ([self numericArg] < 1)
        return nil;
    
        XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
        return [self _motionFixed:m];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN{
    if( _unshift ){
        if ([self numericArg] < 1)
        return nil;
    
        XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
        return [self _motionFixed:m];
    }
    return nil;
}

- (XVimEvaluator*)_motionFixed:(XVimMotion *)motion{
    if( _unshift ){
        [[self sourceView] shiftLeft:motion];
    }else{
        [[self sourceView] shiftRight:motion];
    }
    return nil;
}
@end
