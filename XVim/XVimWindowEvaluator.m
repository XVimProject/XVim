//
//  XVimWindowEvaluator.m
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimWindowEvaluator.h"
#import "XVimWindow.h"
#import "IDEKit.h"
#import "XVimUtil.h"
#import "IDEWorkspaceTabController+XVim.h"


@implementation XVimWindowEvaluator

/**
 * CTRL-W_CTRL-c    same as "CTRL-W c"
 * CTRL-W_CTRL-h    same as "CTRL-W h"
 * CTRL-W_CTRL-j    same as "CTRL-W j"
 * CTRL-W_CTRL-k    same as "CTRL-W k"
 * CTRL-W_CTRL-l    same as "CTRL-W l"
 * CTRL-W_CTRL-n    same as "CTRL-W n"
 * CTRL-W_CTRL-o    same as "CTRL-W o"
 * CTRL-W_CTRL-q    same as "CTRL-W q"
 * CTRL-W_CTRL-s    same as "CTRL-W s"
 * CTRL-W_CTRL-v    same as "CTRL-W v"
 * CTRL-W_CTRL-w    same as "CTRL-W w"
 * CTRL-W_CTRL-W    same as "CTRL-W W"
 */
- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    
    SEL handler = keyStroke.selector;
    if ([self respondsToSelector:handler]) {
        TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self performSelector:handler];
#pragma clang diagnostic pop
    }
    XVimKeyStroke* modifiedKeyStroke = [keyStroke copy];
    if( [modifiedKeyStroke isCTRLModifier] ){
        modifiedKeyStroke.modifier = 0;
        return [super eval:modifiedKeyStroke];
    }
    return [super eval:keyStroke];
}

- (XVimEvaluator*)c{
        [XVimLastActiveWorkspaceTabController() xvim_closeCurrentEditor];
    return nil;
}

- (XVimEvaluator*)n{
    [XVimLastActiveWorkspaceTabController() xvim_addEditor];
    return nil;
}

- (XVimEvaluator*)o{
    [XVimLastActiveWorkspaceTabController() xvim_closeOtherEditors];
    return nil;
}

- (XVimEvaluator*)s{
    [XVimLastActiveWorkspaceTabController() xvim_addEditorHorizontally];
    return nil;
}

- (XVimEvaluator*)q{
    [XVimLastActiveWorkspaceTabController() xvim_closeCurrentEditor];
    return nil;
}

- (XVimEvaluator*)v{
    [XVimLastActiveWorkspaceTabController() xvim_addEditorVertically];
    return nil;
}

- (XVimEvaluator*)h{
    [XVimLastActiveWorkspaceTabController() xvim_moveFocusLeft];
    return nil;
}

- (XVimEvaluator*)j{
    [XVimLastActiveWorkspaceTabController() xvim_moveFocusDown];
    return nil;
}

- (XVimEvaluator*)k{
    [XVimLastActiveWorkspaceTabController() xvim_moveFocusUp];
    return nil;
}

- (XVimEvaluator*)l{
    [XVimLastActiveWorkspaceTabController() xvim_moveFocusRight];
    return nil;
}

/*
 CTRL-W w   Move cursor to window below/right of the current one. If there is
            no window below or right, go to top-left window.
 */
- (XVimEvaluator*)w{
    // TODO: Must handle numericMode  properly.
    //       Currently we do not have good way to know if current evaluator is in numericMode
    //       Accessing parent evaluator directly is not good practice.
    NSInteger count = NSIntegerMax < [self numericArg] ? NSIntegerMax : (NSInteger)[self numericArg] ;
    [XVimLastActiveWorkspaceTabController() xvim_jumpFocus:count relative:![self.parent numericMode]];
    return nil;
}

/*
 CTRL-W W   Move cursor to window above/left of current one. If there is no
            window above or left, go to bottom-right window.
 */
- (XVimEvaluator*)W{
    NSInteger count = NSIntegerMax < [self numericArg] ? NSIntegerMax : (NSInteger)[self numericArg];
    [XVimLastActiveWorkspaceTabController() xvim_jumpFocus:-count relative:![self.parent numericMode]];
    return nil;
}

@end