//
//  XVimUppercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimUppercaseEvaluator.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "NSTextView+VimOperation.h"

@implementation XVimUppercaseEvaluator

- (XVimEvaluator*)U{
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
}

-(XVimEvaluator*)motionFixed:(XVimMotion*)motion{
    [[self sourceView] xvim_makeUpperCase:motion];
    return nil;
}

@end
