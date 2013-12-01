//
//  XVimGVisualEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGVisualEvaluator.h"
#import "XVimView.h"
#import "XVimWindow.h"
#import "XVimJoinEvaluator.h"
#import "XVim.h"

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

- (XVimEvaluator*)J{
    XVimJoinEvaluator* eval = [[[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:NO] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator *)q{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)u{
    [self.argumentString appendString:@"u"];
    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    [self.currentView doSwapCharacters:m mode:XVIM_BUFFER_SWAP_LOWER];
    [[XVim instance] fixOperationCommands];
	return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)U{
    [self.argumentString appendString:@"U"];
    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    [self.currentView doSwapCharacters:m mode:XVIM_BUFFER_SWAP_UPPER];
    [[XVim instance] fixOperationCommands];
	return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator *)w{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator *)QUESTION{
    [self.argumentString appendString:@"?"];
    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    [self.currentView doSwapCharacters:m mode:XVIM_BUFFER_SWAP_ROT13];
    [[XVim instance] fixOperationCommands];
	return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)TILDE{
    [self.argumentString appendString:@"~"];
    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 1);
    [self.currentView doSwapCharacters:m mode:XVIM_BUFFER_SWAP_CASE];
    [[XVim instance] fixOperationCommands];
	return [XVimEvaluator invalidEvaluator];
}

@end
