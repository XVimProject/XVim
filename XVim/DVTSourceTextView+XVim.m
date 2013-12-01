//
//  DVTSourceTextView+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DVTSourceTextView+XVim.h"
#import "IDEEditorArea+XVim.h"
#import "XVimWindow.h"

@implementation DVTSourceTextView (XVim)
- (IDEEditorArea*)editorArea{
    IDEWorkspaceWindowController* wc = [NSClassFromString(@"IDEWorkspaceWindowController") performSelector:@selector(workspaceWindowControllerForWindow:) withObject:[self window]];
    return [wc editorArea];
}

- (XVimWindow*)xvimWindow{
    return [[self editorArea] xvim_window];
}
@end
