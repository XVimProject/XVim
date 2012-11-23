//
//  XVimTildeEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTildeEvaluator.h"
#import "XVimWindow.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"

@implementation XVimTildeEvaluator

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m inWindow:window];
}

-(XVimEvaluator*)motionFixed:(XVimMotion*)motion inWindow:(XVimWindow*)window {
    [[window sourceView] swapCase:motion];
    return nil;
}

@end

@implementation XVimTildeAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
	XVimSourceView *view = [window sourceView];
	NSRange r = [view getOperationRangeFrom:from To:to Type:type];
	[view toggleCaseForRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}
@end