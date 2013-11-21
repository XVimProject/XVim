//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "IDEEditor+XVim.h"
#import "IDEEditorArea+XVim.h"
#import "IDEWorkspaceWindowHook.h"
#import "DVTSourceTextScrollViewHook.h"
#import "XVimView.h"

@implementation XVimHookManager

+ (void)hookWhenPluginLoaded
{
    [IDEEditorArea xvim_initialize];
    [IDEWorkspaceWindowHook hook];
    [DVTSourceTextScrollViewHook hook];
    [IDEEditor xvim_initialize];
    [IDEComparisonEditor xvim_initialize];
    [XVimView class];
}

@end
