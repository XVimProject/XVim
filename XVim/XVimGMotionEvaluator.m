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

- (XVimEvaluator*)eval:(XVimKeyStroke *)keyStroke{
    self.key = keyStroke;
    return [super eval:keyStroke];
}

- (XVimEvaluator*)e{
    // Select previous word end
    self.motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]);
    return nil;
}

- (XVimEvaluator*)E{
    // Select previous WORD end
    self.motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_INCLUSIVE, BIGWORD, [self numericArg]);
    return nil;
}

- (XVimEvaluator*)g{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, MOTION_OPTION_NONE, 1);
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)j{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, CHARACTERWISE_EXCLUSIVE, DISPLAY_LINE, self.numericArg);
    return nil;
}

- (XVimEvaluator*)k{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, CHARACTERWISE_EXCLUSIVE, DISPLAY_LINE, self.numericArg);
    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward {
    XVimCommandLineEvaluator* eval = [self searchEvaluatorForward:forward];
    NSRange r = [self.sourceView xvim_currentWord:MOTION_OPTION_NONE];
    if( r.location == NSNotFound ){
        return nil;
    }
    
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

- (XVimEvaluator*)SEMICOLON{
    // SEMICOLON is handled by parent evaluator (not really good design though)
    self.motion = nil;
    return nil;
}

@end
