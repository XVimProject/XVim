//
//  XVimShiftEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimShiftEvaluator.h"
#import "NSTextView+VimOperation.h"
#import "XVimWindow.h"
#import "XVim.h"

@interface XVimShiftEvaluator() {
	BOOL _unshift;
}
@end

@implementation XVimShiftEvaluator

- (id)initWithWindow:(XVimWindow *)window unshift:(BOOL)unshift {
	if (self = [super initWithWindow:window]) {
		_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)GREATERTHAN {
    if( !_unshift ){
        if ([self numericArg] < 1){
            return nil;
        }
    
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

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    if( _unshift ){
        [[self sourceView] xvim_shiftLeft:motion];
    }else{
        [[self sourceView] xvim_shiftRight:motion];
    }
    return nil;
}
@end
