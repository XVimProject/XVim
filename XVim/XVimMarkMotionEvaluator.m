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
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVim.h"

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

+ (NSUInteger)markLocationForMark:(NSString*)mark inWindow:(XVimWindow*)window
{
	if ([mark length] != 1) {
        return NSNotFound;
    }
    NSString* internalMark;
    if( [mark isEqualToString:@"`"] ){
        internalMark = @"'";
    } else {
        internalMark = mark;
    }

	NSValue* v = [[window getLocalMarks] valueForKey:internalMark];
	if (v == nil) {
		[window errorMessage:@"Mark not set" ringBell:YES];
		return NSNotFound;
	}

	NSRange r = [v rangeValue];
	XVimSourceView* view = [window sourceView];
	NSString* s = [view string];
	if (r.location > [s length]) {
		// mark is past end of file do nothing
		return NSNotFound;
	}
	
    NSUInteger to = r.location;
	return to;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window
{
    NSString* keyStr = [keyStroke toString];
	NSUInteger to = [[self class] markLocationForMark:keyStr inWindow:window];
	if (to == NSNotFound)
	{
		return nil;
	}
	
    NSUInteger from = [[window sourceView] selectedRange].location;
	MOTION_TYPE motionType = CHARACTERWISE_EXCLUSIVE;
	
	if (_markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
		to = [[window sourceView] firstNonBlankInALine:to];
		motionType = LINEWISE;
	}
	
    // set the position before the jump
    NSRange r = [[window sourceView] selectedRange];
    NSValue *v =[NSValue valueWithRange:r];
    [[window getLocalMarks] setValue:v forKey:@"'"];

    return [[self motionEvaluator] _motionFixedFrom:from To:to Type:motionType inWindow:window];
}

@end
