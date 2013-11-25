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
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"

@implementation XVimGMotionEvaluator
@synthesize motion, key;

- (XVimEvaluator*)eval:(XVimKeyStroke *)keyStroke{
    self.key = keyStroke;
    return [super eval:keyStroke];
}

- (XVimEvaluator*)g{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, MOPT_NONE, 1);
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward {
    XVimCommandLineEvaluator* eval = [self searchEvaluatorForward:forward];
    NSRange r = [self.currentView xvim_currentWord:MOPT_NONE];
    if( r.location == NSNotFound ){
        return nil;
    }
    
    // This is not for matching the searching word itself
    // Vim also does this behavior( when matched string is not found )
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    m.position = r.location;
    [self.currentView moveCursorWithMotion:m];
    
    NSString* word = [self.currentView.textView.string substringWithRange:r];
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
