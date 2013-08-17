//
//  XVimYankEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimYankEvaluator.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVim.h"

@implementation XVimYankEvaluator

- (XVimEvaluator*)y{
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
    
}

- (XVimEvaluator*)UNDERSCORE{
    return [self y];
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    [[self sourceView] xvim_yank:motion];
    return nil;
}
@end

