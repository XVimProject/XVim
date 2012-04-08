//
//  XVimShiftEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimShiftEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"

@interface XVimShiftEvaluator() {
	BOOL _unshift;
}
@end

@implementation XVimShiftEvaluator

- (id)initWithOperatorAction:(XVimOperatorAction*)action 
					  repeat:(NSUInteger)repeat 
					 unshift:(BOOL)unshift
{
	if (self = [super initWithOperatorAction:action repeat:repeat])
	{
		self->_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)GREATERTHAN:(XVim*)xvim{
    if( !_unshift ){
        NSTextView* view = [xvim sourceView];
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(XVim*)xvim{
    //unshift
    if( _unshift ){
        NSTextView* view = [xvim sourceView];
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
    }
    return nil;
}

@end

@interface XVimShiftAction() {
	BOOL _unshift;
}
@end

@implementation XVimShiftAction

- (id)initWithUnshift:(BOOL)unshift
{
	if (self = [super init])
	{
		self->_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
	DVTSourceTextView* view = (DVTSourceTextView*)[xvim sourceView];
	[view selectOperationTargetFrom:from To:to Type:type];
	if( _unshift ){
		[view shiftLeft:self];
	}else{
		[view shiftRight:self];
	}
	[view setSelectedRange:NSMakeRange([view selectedRange].location, 0)];
	return nil;
}
@end
