//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimView.h"
#import "XVimHookManager.h"
#import "IDEEditor+XVim.h"
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
    [DVTSourceTextScrollViewHook hook];
    [IDEEditor xvim_initialize];
    [IDEComparisonEditor xvim_initialize];
    [XVimView class];
}

@end
