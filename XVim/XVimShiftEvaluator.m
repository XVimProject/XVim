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
	if (self = [super initWithContext:context
					   operatorAction:action 
								  withParent:parent])
	{
		self->_unshift = unshift;
	}
	return self;
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window{
    if( !_unshift ){
        XVimSourceView* view = [window sourceView];
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window{
    //unshift
    if( _unshift ){
        XVimSourceView* view = [window sourceView];
        NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
        return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
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

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
	DVTSourceTextView* view = (DVTSourceTextView*)[window sourceView];
	NSUInteger lineNumber = [view lineNumber:MIN(from, to)];
	[view selectOperationTargetFrom:from To:to Type:type];
	if( _unshift ){
		[view shiftLeft];
	}else{
		[view shiftRight];
	}
	NSUInteger cursorLocation = [view firstNonBlankInALine:[view positionAtLineNumber:lineNumber]];
	[view setSelectedRangeWithBoundsCheck:cursorLocation To:cursorLocation];
	return nil;
}
@end
