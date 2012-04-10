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
#import "common.h"

@interface XVimTextObjectEvaluator() {
	XVimOperatorAction *_operatorAction;
	NSUInteger _location;
	NSUInteger _repeat;
	BOOL _inclusive;
	XVIM_MODE _mode;
	XVimEvaluator *_parent;
}
@end

@implementation XVimTextObjectEvaluator

- (id)initWithOperatorAction:(XVimOperatorAction*)operatorAction 
						from:(NSUInteger)location
					  inMode:(XVIM_MODE)mode
					withParent:(XVimEvaluator*)parent
					  repeat:(NSUInteger)repeat 
				   inclusive:(BOOL)inclusive
{
	if (self = [super init])
	{
		self->_operatorAction = operatorAction;
		self->_location = location;
		self->_repeat = repeat;
		self->_inclusive = inclusive;
		self->_mode = mode;
		self->_parent = parent;
	}
	return self;
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return _location;
}

- (XVIM_MODE)becameHandlerInWindow:(XVimWindow*)window{
	return _mode;
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
    return _parent;
}

- (XVimEvaluator*)executeActionForRange:(NSRange)r inWindow:(XVimWindow*)window
{
	if (r.location != NSNotFound)
	{
		[window.sourceView clampRangeToBuffer:&r];
		return [_operatorAction motionFixedFrom:r.location To:r.location+r.length Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
	}
	return _parent;
}

- (XVimEvaluator*)b:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], _location, _repeat, _inclusive, '(', ')');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], _location, _repeat, _inclusive, '{', '}');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)w:(XVimWindow*)window
{
	NSRange r = xv_current_word([window.sourceView string], _location, _repeat, _inclusive, NO);
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)W:(XVimWindow*)window
{
	NSRange r = xv_current_word([window.sourceView string], _location, _repeat, _inclusive, YES);
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)LSQUAREBRACKET:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], _location, _repeat, _inclusive, '[', ']');
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
	NSRange r = xv_current_block([window.sourceView string], _location, _repeat, _inclusive, '<', '>');
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
	NSRange r = xv_current_quote([window.sourceView string], _location, _repeat, _inclusive, '\'');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window
{
	NSRange r = xv_current_quote([window.sourceView string], _location, _repeat, _inclusive, '"');
	return [self executeActionForRange:r inWindow:window];
}

@end
