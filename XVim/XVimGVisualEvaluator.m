//
//  XVimGVisualEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGVisualEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimWindow.h"

@implementation XVimGVisualEvaluator

- (XVimEvaluator*)u:(XVimWindow*)window {
	XVimSourceView *view = [window sourceView];
    [view makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	XVimSourceView *view = [window sourceView];
    [view makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	XVimSourceView *view = [window sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

@end
