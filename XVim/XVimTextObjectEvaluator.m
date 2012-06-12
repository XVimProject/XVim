//
//  XVimTextObjectEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"
#import "XVimOperatorAction.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "XVimKeymapProvider.h"

@interface XVimTextObjectEvaluator() {
	XVimOperatorAction *_operatorAction;
	BOOL _inclusive;
	XVimEvaluator *_parent;
}
@end

@implementation XVimTextObjectEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*)operatorAction 
					withParent:(XVimEvaluator*)parent
				   inclusive:(BOOL)inclusive
{
	if (self = [super initWithContext:context])
	{
		self->_operatorAction = operatorAction;
		self->_inclusive = inclusive;
		self->_parent = parent;
	}
	return self;
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
    return [_parent insertionPointInWindow:window];
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
	return [_parent drawRect:rect inWindow:window];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return [_parent shouldDrawInsertionPointInWindow:window];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio
{
	return [_parent drawInsertionPointInRect:rect color:color inWindow:window heightRatio:.5];
}

- (NSString*)modeString
{
	return [_parent modeString];
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other
{
	return [super isRelatedTo:other] || other == _parent;
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
    return [_parent withNewContext];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)executeActionForRange:(NSRange)r inWindow:(XVimWindow*)window
{
	if (r.location != NSNotFound)
	{
		[window.sourceView clampRangeToBuffer:&r];
		return [_operatorAction motionFixedFrom:r.location To:r.location+r.length Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
	}
	return [_parent withNewContext];
}

- (XVimEvaluator*)b:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '(', ')');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '{', '}');
	return [self executeActionForRange:r inWindow:window];
}

-(XVimEvaluator*)p:(XVimWindow*)window
{
    NSUInteger start = [self insertionPointInWindow:window];
    if(start != 0){
        start = [window.sourceView paragraphsBackward:[self insertionPointInWindow:window] count:1 option:MOPT_PARA_BOUND_BLANKLINE];
    }
    NSUInteger starts_end = [window.sourceView paragraphsForward:start count:1 option:MOPT_PARA_BOUND_BLANKLINE];
    NSUInteger end = [window.sourceView paragraphsForward:[self insertionPointInWindow:window] count:[self numericArg] option:MOPT_PARA_BOUND_BLANKLINE];
    
    if(starts_end != end){
        start = starts_end;
    }
    
    NSRange r = NSMakeRange(start, end - start);
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)w:(XVimWindow*)window
{
    MOTION_OPTION opt = _inclusive ? INCLUSIVE : MOTION_OPTION_NONE;
    NSRange r = [window.sourceView currentWord:[self insertionPointInWindow:window] count:[self numericArg] option:opt];
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)W:(XVimWindow*)window
{
    MOTION_OPTION opt = _inclusive ? INCLUSIVE : MOTION_OPTION_NONE;
    NSRange r = [window.sourceView currentWord:[self insertionPointInWindow:window] count:[self numericArg] option:opt|BIGWORD];
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)LSQUAREBRACKET:(XVimWindow*)window
{
	NSRange r = xv_current_block([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '[', ']');
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
	NSRange r = xv_current_block([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '<', '>');
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
	NSRange r = xv_current_quote([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '\'');
	return [self executeActionForRange:r inWindow:window];
}

- (XVimEvaluator*)DQUOTE:(XVimWindow*)window
{
	NSRange r = xv_current_quote([window.sourceView string], [self insertionPointInWindow:window], [self numericArg], _inclusive, '"');
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
