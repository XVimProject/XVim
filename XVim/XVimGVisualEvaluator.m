//
//  XVimGVisualEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGVisualEvaluator.h"
#import "NSTextView+VimOperation.h"
#import "XVimWindow.h"

@implementation XVimGVisualEvaluator

- (XVimEvaluator*)u{
	NSTextView *view = [self sourceView];
    [view xvim_makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)U{
	NSTextView *view = [self sourceView];
    [view xvim_makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)TILDE{
	NSTextView *view = [self sourceView];
    [view xvim_swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

@end
