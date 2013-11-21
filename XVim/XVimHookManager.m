//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "IDEEditorAreaHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditor+XVim.h"
#import "IDEWorkspaceWindowHook.h"
#import "DVTSourceTextScrollViewHook.h"
#import "XVimView.h"

@implementation XVimHookManager

+ (void)hookWhenPluginLoaded
{
    [IDEEditorAreaHook hook];
    [IDEWorkspaceWindowHook hook];
    [DVTSourceTextScrollViewHook hook];
    [IDESourceCodeEditorHook hook];
    [IDEEditor xvim_initialize];
    [IDEComparisonEditor xvim_initialize];
    [XVimView class];
}

@end
