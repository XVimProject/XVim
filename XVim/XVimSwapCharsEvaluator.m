//
//  XVimLowercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimSwapCharsEvaluator.h"
#import "XVimWindow.h"
#import "XVim.h"

@implementation XVimSwapCharsEvaluator {
    int _mode;
}

- (instancetype)initWithWindow:(XVimWindow *)window mode:(int)mode
{
    if ((self = [self initWithWindow:window])) {
        _mode = mode;
    }
    return self;
}

- (XVimEvaluator *)_doitLineWiseIfModeIs:(int)mode
{
    if (_mode != mode || [self numericArg] < 1)
        return nil;

    XVimMotion *m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOPT_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
}

- (XVimEvaluator *)u
{
    [self.argumentString appendString:@"u"];
    return [self _doitLineWiseIfModeIs:XVIM_BUFFER_SWAP_LOWER];
}

- (XVimEvaluator *)U
{
    [self.argumentString appendString:@"U"];
    return [self _doitLineWiseIfModeIs:XVIM_BUFFER_SWAP_UPPER];
}

- (XVimEvaluator *)QUESTION
{
    [self.argumentString appendString:@"?"];
    return [self _doitLineWiseIfModeIs:XVIM_BUFFER_SWAP_ROT13];
}

- (XVimEvaluator *)TILDE
{
    [self.argumentString appendString:@"~"];
    return [self _doitLineWiseIfModeIs:XVIM_BUFFER_SWAP_CASE];
}

- (XVimEvaluator *)motionFixed:(XVimMotion*)motion
{
    [self.currentView doSwapCharacters:motion mode:_mode];
    return nil;
}


@end
