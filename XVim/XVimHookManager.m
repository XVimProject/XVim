//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "DVTEditorAreaHook.h"
#import "DVTSourceTextViewHook.h"
#import "DVTSourceCodeEditorHook.h"
#import "DVTSourceTextScrollViewHook.h"

@implementation XVimHookManager

+ (void)hook
{
    [DVTEditorAreaHook hook];
	[DVTSourceTextViewHook hook];
	[DVTSourceCodeEditorHook hook];
    [DVTSourceTextScrollViewHook hook];
}

@end
