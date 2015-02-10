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

- (XVimEvaluator*)C_w{
    return [self w];
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