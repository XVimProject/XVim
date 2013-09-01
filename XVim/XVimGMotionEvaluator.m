//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandLineEvaluator.h"
#import "XVimGMotionEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMotionOption.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"

@implementation XVimGMotionEvaluator

- (XVimEvaluator*)g{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, MOTION_OPTION_NONE, 1);
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward {
    XVimCommandLineEvaluator* eval = [self searchEvaluatorForward:forward];
    NSRange r = [self.sourceView xvim_currentWord:MOTION_OPTION_NONE];
    if( r.location == NSNotFound ){
        return nil;
    }
    
    // This is not for matching the searching word itself
    // Vim also does this behavior( when matched string is not found )
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = r.location;
    [self.sourceView xvim_move:m];
    
    NSString* word = [self.sourceView.string substringWithRange:r];
    NSString* searchWord = [NSRegularExpression escapedPatternForString:word];
    [eval appendString:searchWord];
    [eval execute];
    self.motion = eval.evalutionResult;
    return nil;
}

- (XVimEvaluator*)ASTERISK{
	return [self searchCurrentWord:YES];
}

- (XVimEvaluator*)NUMBER{
	return [self searchCurrentWord:NO];
}

@end
