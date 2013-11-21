//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimHookManager.h"
#import "DVTSourceTextViewHook.h"
#import "DVTTextSidebarViewHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorHook.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorArea+XVim.h"
#import "DVTSourceTextScrollViewHook.h"
#import "NSEvent+VimHelper.h"
#import "NSObject+XVimAdditions.h"

@implementation IDEWorkspaceWindow (XVim)

+ (void)xvim_initialize
{
#if 0 // Only useful for debugging purposes
    if (self == [IDEWorkspaceWindow class]) {
        [self xvim_swizzleInstanceMethod:@selector(sendEvent:)
                                    with:@selector(xvim_sendEvent:)];
    }
#endif
}

- (void)xvim_sendEvent:(NSEvent *)event
{
    if (event.type == NSKeyDown) {
        TRACE_LOG(@"Window:%p keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d",
                  self, event.keyCode, event.characters, event.charactersIgnoringModifiers, event.unmodifiedKeyCode);
    }
    [self xvim_sendEvent:event];
}

@end

@implementation XVimHookManager

+ (void)hookWhenPluginLoaded
{
    [IDEWorkspaceWindow xvim_initialize];
    [IDEEditorArea xvim_initialize];
    [DVTSourceTextViewHook hook];
    [DVTTextSidebarViewHook hook];
    [DVTSourceTextScrollViewHook hook];
    [IDESourceCodeEditorHook hook];
    [IDEEditorHook hook];
}

@end
