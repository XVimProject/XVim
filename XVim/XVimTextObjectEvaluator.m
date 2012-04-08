//
//  XVimTextObjectEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"
#import "XVimOperatorAction.h"
#import "NSTextView+VimMotion.h"
#import "common.h"

@interface XVimTextObjectEvaluator() {
	XVimOperatorAction *_operatorAction;
	NSUInteger _repeat;
	BOOL _inclusive;
}
@end

@implementation XVimTextObjectEvaluator

- (id)initWithOperatorAction:(XVimOperatorAction*)operatorAction repeat:(NSUInteger)repeat inclusive:(BOOL)inclusive
{
	if (self = [super init])
	{
		self->_operatorAction = operatorAction;
		self->_repeat = repeat;
		self->_inclusive = inclusive;
	}
	return self;
}

- (XVimEvaluator*)executeActionForRange:(NSRange)r XVim:(XVim*)xvim
{
	if (r.location != NSNotFound)
	{
		[xvim.sourceView clampRangeToBuffer:&r];
		return [_operatorAction motionFixedFrom:r.location To:r.location+r.length Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
	}
	return nil;
}

- (XVimEvaluator*)b:(XVim*)xvim
{
	NSRange r = xv_current_block([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '(', ')');
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)B:(XVim*)xvim
{
	NSRange r = xv_current_block([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '{', '}');
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)w:(XVim*)xvim
{
	NSRange r = xv_current_word([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, NO);
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)W:(XVim*)xvim
{
	NSRange r = xv_current_word([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, YES);
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)LSQUAREBRACKET:(XVim*)xvim
{
	NSRange r = xv_current_block([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '[', ']');
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)RSQUAREBRACKET:(XVim*)xvim
{
	return [self LSQUAREBRACKET:xvim];
}

- (XVimEvaluator*)LBRACE:(XVim*)xvim
{
	return [self B:xvim];
}

- (XVimEvaluator*)RBRACE:(XVim*)xvim
{
	return [self B:xvim];
}

- (XVimEvaluator*)LESSTHAN:(XVim*)xvim
{
	NSRange r = xv_current_block([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '<', '>');
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)GREATERTHAN:(XVim*)xvim
{
	return [self LESSTHAN:xvim];
}

- (XVimEvaluator*)LPARENTHESIS:(XVim*)xvim
{
	return [self b:xvim];
}

- (XVimEvaluator*)RPARENTHESIS:(XVim*)xvim
{
	return [self b:xvim];
}

- (XVimEvaluator*)SQUOTE:(XVim*)xvim
{
	NSRange r = xv_current_quote([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '\'');
	return [self executeActionForRange:r XVim:xvim];
}

- (XVimEvaluator*)DQUOTE:(XVim*)xvim
{
	NSRange r = xv_current_quote([xvim.sourceView string], [xvim.sourceView selectedRange].location, _repeat, _inclusive, '"');
	return [self executeActionForRange:r XVim:xvim];
}

@end
