//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "IDEEditorAreaHook.h"
#import "DVTSourceTextViewHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorHook.h"

@implementation XVimHookManager

+ (void)hook
{
    [IDEEditorAreaHook hook];
	[DVTSourceTextViewHook hook];
	[IDESourceCodeEditorHook hook];
    [IDEEditorHook hook];
}

@end
