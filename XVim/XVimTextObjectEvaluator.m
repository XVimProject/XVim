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
@property (readonly) NSString *string;
@property (readonly) NSUInteger index;
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

- (NSString *)string
{
	return [self.textView string];
}

- (NSUInteger)index
{
	return [self.textView selectedRange].location;
}

- (XVimEvaluator*)executeActionForRange:(NSRange)r
{
	if (r.location != NSNotFound)
	{
		[self.textView clampRangeToBuffer:&r];
		return [_operatorAction motionFixedFrom:r.location To:r.location+r.length Type:CHARACTERWISE_EXCLUSIVE];
	}
	return nil;
}

- (XVimEvaluator*)b:(id)arg
{
	NSRange r = xv_current_block(self.string, self.index, _repeat, _inclusive, '(', ')');
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)B:(id)arg
{
	NSRange r = xv_current_block(self.string, self.index, _repeat, _inclusive, '{', '}');
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)w:(id)arg
{
	NSRange r = xv_current_word(self.string, self.index, _repeat, _inclusive, NO);
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)W:(id)arg
{
	NSRange r = xv_current_word(self.string, self.index, _repeat, _inclusive, YES);
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)LSQUAREBRACKET:(id)arg
{
	NSRange r = xv_current_block(self.string, self.index, _repeat, _inclusive, '[', ']');
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)RSQUAREBRACKET:(id)arg
{
	return [self LSQUAREBRACKET:arg];
}

- (XVimEvaluator*)LBRACE:(id)arg
{
	return [self B:arg];
}

- (XVimEvaluator*)RBRACE:(id)arg
{
	return [self B:arg];
}

- (XVimEvaluator*)LESSTHAN:(id)arg
{
	NSRange r = xv_current_block(self.string, self.index, _repeat, _inclusive, '<', '>');
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)GREATERTHAN:(id)arg
{
	return [self LESSTHAN:arg];
}

- (XVimEvaluator*)LPARENTHESIS:(id)arg
{
	return [self b:arg];
}

- (XVimEvaluator*)RPARENTHESIS:(id)arg
{
	return [self b:arg];
}

- (XVimEvaluator*)SQUOTE:(id)arg
{
	NSRange r = xv_current_quote(self.string, self.index, _repeat, _inclusive, '\'');
	return [self executeActionForRange:r];
}

- (XVimEvaluator*)DQUOTE:(id)arg
{
	NSRange r = xv_current_quote(self.string, self.index, _repeat, _inclusive, '"');
	return [self executeActionForRange:r];
}

@end
