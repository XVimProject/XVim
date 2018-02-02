//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimHookManager.h"
#import "DVTTextSidebarView+XVim.h"
#import "IDESourceEditor.h"
#import "IDEEditor+XVim.h"
#import "IDESourceCodeEditor+XVim.h"
#import "IDEEditorArea+XVim.h"
#import "DVTSourceTextScrollView+XVim.h"
#import "NSEvent+VimHelper.h"
#import "NSObject+XVimAdditions.h"
#import "DVTSourceTextView+XVim.h"
#import "IDEApplicationController+XVim.h"

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
    [DVTSourceTextView xvim_initialize];
    [DVTTextSidebarView xvim_initialize];
    [DVTSourceTextScrollView xvim_initialize];
    [IDESourceCodeEditor xvim_initialize];
    [IDEEditor xvim_initialize];
    [IDEApplicationController xvim_initialize];
}

@end
