//
//  XVimWindowEvaluator.m
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowEvaluator.h"
#import "XVimWindowManager.h"

@implementation XVimWindowEvaluator

- (XVimEvaluator*)n:(id)arg
{
    [[XVimWindowManager instance] addEditorWindow];
    return nil;
}

- (XVimEvaluator*)o:(id)arg
{
	[[XVimWindowManager instance] closeAllButActive];
    return nil;
}

- (XVimEvaluator*)s:(id)arg{
    [[XVimWindowManager instance] addEditorWindowHorizontal];
    
    return nil;
}

- (XVimEvaluator*)q:(id)arg{
    [[XVimWindowManager instance] removeEditorWindow];
    return nil;
}

- (XVimEvaluator*)v:(id)arg{
    [[XVimWindowManager instance] addEditorWindowVertical];
    return nil;
}

@end