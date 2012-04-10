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
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
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

- (XVimEvaluator*)executeActionForRange:(NSRange)r inWindow:(XVimWindow*)window
{
	if (r.location != NSNotFound)
	{
		[window.sourceView clampRangeToBuffer:&r];
		return [_operatorAction motionFixedFrom:r.location To:r.location+r.length Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
	}
	return nil;
}

- (XVimEvaluator*)b:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '(', ')');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '{', '}');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)w:(XVimWindow*)window
{
	NSRange r = xv_current_word([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, NO);
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)W:(XVimWindow*)window
{
	NSRange r = xv_current_word([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, YES);
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)LSQUAREBRACKET:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '[', ']');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)RSQUAREBRACKET:(XVimWindow*)window
{
	return [self LSQUAREBRACKET:window];
}

- (XVimEvaluator*)LBRACE:(XVimWindow*)window
{
	return [self B:window];
}

- (XVimEvaluator*)RBRACE:(XVimWindow*)window
{
	return [self B:window];
}

- (XVimEvaluator*)LESSTHAN:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '<', '>');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)GREATERTHAN:(XVimWindow*)window
{
	return [self LESSTHAN:window];
}

- (XVimEvaluator*)LPARENTHESIS:(XVimWindow*)window
{
	return [self b:window];
}

- (XVimEvaluator*)RPARENTHESIS:(XVimWindow*)window
{
	return [self b:window];
}

- (XVimEvaluator*)SQUOTE:(XVimWindow*)window
{
	NSRange r = xv_current_quote([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '\'');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window
{
	NSRange r = xv_current_quote([window.sourceView string], [window.sourceView selectedRange].location, _repeat, _inclusive, '"');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister
{
    if (xregister.isRepeat && [keyStroke instanceResponds:self] ) 
	{
		return REGISTER_APPEND;
	}
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
