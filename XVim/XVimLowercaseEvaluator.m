//
//  XVimLowercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimLowercaseEvaluator.h"
#import "XVimWindow.h"
#import "XVim.h"

@implementation XVimLowercaseEvaluator

- (XVimEvaluator*)u{
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
}

-(XVimEvaluator*)motionFixed:(XVimMotion*)motion{
    [[self sourceView] xvim_makeLowerCase:motion];
    return nil;
}


@end

