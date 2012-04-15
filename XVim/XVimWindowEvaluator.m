//
//  XVimWindowEvaluator.m
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"
#import "XVimSourceCodeEditor.h"
#import "IDEEditorModeViewController.h"
#import "IDEWorkspaceTabController.h"
#import "IDEEditorMultipleContext.h"
#import "IDESourceCodeEditor.h"
#import "IDEEditorGeniusMode.h"
#import "IDEEditorArea.h"
#import "Logger.h"
#import "XVim.h"

@interface XVimWindowEvaluator()
- (void)addEditorWindow;
- (void)removeEditorWindow;
@end

@implementation XVimWindowEvaluator

- (void)addEditorWindow{
    IDESourceCodeEditor *editor = (IDESourceCodeEditor*)[XVim instance].editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

- (void)removeEditorWindow{
    IDESourceCodeEditor *editor = (IDESourceCodeEditor*)[XVim instance].editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }
    
    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    if ([geniusMode canRemoveAssistantEditor] == NO){
        [workspaceTabController changeToStandardEditor:self];
    }else {
        [workspaceTabController removeAssistantEditor:self];
    }
}

- (XVimEvaluator*)n:(id)arg{
    [self addEditorWindow];
    return nil;
}

- (XVimEvaluator*)o:(id)arg{
    IDESourceCodeEditor *editor = (IDESourceCodeEditor*)[XVim instance].editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }

    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    IDEEditorMultipleContext *multipleContext = [geniusMode alternateEditorMultipleContext];
    if ([multipleContext canCloseEditorContexts]){
        [multipleContext closeAllEditorContextsKeeping:[multipleContext selectedEditorContext]];
    }
    return nil;
}

- (XVimEvaluator*)s:(id)arg{
    [self addEditorWindow];
    
    // Change to horizontal
    IDESourceCodeEditor *editor = (IDESourceCodeEditor*)[XVim instance].editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BH:self];
    return nil;
}

- (XVimEvaluator*)q:(id)arg{
    [self removeEditorWindow];
    return nil;
}

- (XVimEvaluator*)v:(id)arg{
    [self addEditorWindow];
    
    // Change to vertical
    IDESourceCodeEditor *editor = (IDESourceCodeEditor*)[XVim instance].editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BV:self];
    return nil;
}

@end