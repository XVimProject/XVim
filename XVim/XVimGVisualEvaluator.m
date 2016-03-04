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
#import "XVimJoinEvaluator.h"

@implementation XVimGVisualEvaluator

- (XVimEvaluator *)defaultNextEvaluator {
    return [XVimEvaluator popEvaluator];
}

- (NSString *)modeString {
    return self.parent.modeString;
}

- (void)didEndHandler
{
    [self.parent.argumentString setString:@""];
    [super didEndHandler];
}

- (XVimEvaluator*)e{
    XVimMotion *motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, self.numericArg);
    [[self sourceView] xvim_move:motion];
    [self.parent resetNumericArg];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)E{
    XVimMotion *motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, self.numericArg);
    [[self sourceView] xvim_move:motion];
    [self.parent resetNumericArg];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator *)f{
    [self.window errorMessage:@"{visual}gf unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator *)F{
    return [self f];
}

- (XVimEvaluator *)C_g{
    [self.window errorMessage:@"{Visual}g CTRL-G unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator *)g{
    XVimMotion *motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    motion.line = self.numericArg;
    [[self sourceView] xvim_move:motion];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)j{
    XVimMotion *motion = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, CHARACTERWISE_EXCLUSIVE, DISPLAY_LINE, self.numericArg);
    [[self sourceView] xvim_move:motion];
    [self.parent resetNumericArg];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)k{
    XVimMotion *motion = XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, CHARACTERWISE_EXCLUSIVE, DISPLAY_LINE, self.numericArg);
    [[self sourceView] xvim_move:motion];
    [self.parent resetNumericArg];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)J{
    XVimJoinEvaluator* eval = [[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:NO];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, self.numericArg)];
}

- (XVimEvaluator *)q{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)u{
	NSTextView *view = [self sourceView];
    [view xvim_makeLowerCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)U{
	NSTextView *view = [self sourceView];
    [view xvim_makeUpperCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator *)w{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator *)QUESTION{
    [self.window errorMessage:@"{visual}g? unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)TILDE{
	NSTextView *view = [self sourceView];
    [view xvim_swapCase:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1)];
	return [XVimEvaluator invalidEvaluator];
}

@end
