//
//  XVimGVisualEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGVisualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"
#import "XVimWindow.h"

@implementation XVimGVisualEvaluator

- (XVimEvaluator*)u:(XVimWindow*)window {
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view uppercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	NSTextView *view = [window sourceView];
	NSRange r = [view selectedRange];
	[view toggleCaseForRange:r];
	return nil;
}

@end
