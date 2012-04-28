//
//  XVimMarkMotionEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMarkMotionEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "NSTextView+VimMotion.h"

@interface XVimMarkMotionEvaluator() {
	XVimMarkOperator _markOperator;
}
@end

@implementation XVimMarkMotionEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimMotionEvaluator*)parent
		 markOperator:(XVimMarkOperator)markOperator
{
	if (self = [super initWithContext:context parent:parent])
	{
		_markOperator = markOperator;
	}
	return self;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    NSString* keyStr = [keyStroke toString];
	if ([keyStr length] != 1) {
        return nil;
    }

	NSValue* v = [[window getLocalMarks] valueForKey:keyStr];
	if (v == nil) {
		[window errorMessage:@"Mark not set" ringBell:YES];
		return nil;
	}
	
	NSRange r = [v rangeValue];
	DVTSourceTextView* view = [window sourceView];
	NSString* s = [[view textStorage] string];
	if (r.location > [s length]) {
		// mark is past end of file do nothing
		return nil;
	}
	
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = r.location;
	MOTION_TYPE motionType = CHARACTERWISE_EXCLUSIVE;
	
	if (_markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
		to = [view firstNonBlankInALine:to];
		motionType = LINEWISE;
	}
	
    return [[self motionEvaluator] _motionFixedFrom:from To:to Type:motionType inWindow:window];
}

@end
