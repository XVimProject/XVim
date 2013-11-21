//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "DVTSourceTextViewHook.h"
#import "DVTTextSidebarViewHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorArea+XVim.h"
#import "IDEWorkspaceWindowHook.h"
#import "DVTSourceTextScrollViewHook.h"

@implementation XVimHookManager

+ (void)hookWhenPluginLoaded
{
    [IDEEditorArea xvim_initialize];
    [IDEWorkspaceWindowHook hook];
    [DVTSourceTextViewHook hook];
    [DVTTextSidebarViewHook hook];
    [DVTSourceTextScrollViewHook hook];
    [IDESourceCodeEditorHook hook];
    [IDEEditorHook hook];
}

@end
