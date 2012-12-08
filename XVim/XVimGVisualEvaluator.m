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

- (XVimEvaluator*)u{
	XVimSourceView *view = [self sourceView];
    [view makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)U{
	XVimSourceView *view = [self sourceView];
    [view makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

- (XVimEvaluator*)TILDE{
	XVimSourceView *view = [self sourceView];
    [view swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return nil;
}

@end
