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
#import "XVimSourceView+Xcode.h"
#import "XVim.h"
#import "XVimMark.h"
#import "XVimMarks.h"

@implementation XVimMarkMotionEvaluator

- (id)initWithWindow:(XVimWindow*)window{
	if (self = [super initWithWindow:window]) {
	}
	return self;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_NONE];
}

/*
+ (NSUInteger)markLocationForMark:(NSString*)mark inWindow:(XVimWindow*)window {
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
*/
 
 
@end
