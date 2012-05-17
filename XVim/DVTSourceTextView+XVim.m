//
//  DVTSourceTextView+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DVTSourceTextView+XVim.h"
#import "IDEEditorArea+XVim.h"

@implementation DVTSourceTextView (XVim)
- (XVimCommandLine*)commandLine{
    IDEWorkspaceWindowController* wc = [NSClassFromString(@"IDEWorkspaceWindowController") performSelector:@selector(workspaceWindowControllerForWindow:) withObject:[self window]];
    IDEEditorArea* editorArea = [wc editorArea];
    return [editorArea commandLine];
}
@end
