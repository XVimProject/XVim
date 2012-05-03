//
//  XVimWindowManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowManager.h"

#import "IDEKit.h"

static XVimWindowManager *_instance = nil;

@interface XVimWindowManager() {
	IDESourceCodeEditor *_editor;
}
- (void)setHorizontal;
- (void)setVertical;
@end

@implementation XVimWindowManager

+ (void)createWithEditor:(IDESourceCodeEditor*)editor
{
	XVimWindowManager *instance = [[self alloc] init];
	instance->_editor = editor;
	_instance = instance;
}

+ (XVimWindowManager*)instance
{
	return _instance;
}

- (void)addEditorWindow
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

- (void)addEditorWindowVertical
{
	[self addEditorWindow];
	[self setVertical];
}

- (void)addEditorWindowHorizontal
{
	[self addEditorWindow];
	[self setHorizontal];
}

- (void)removeEditorWindow
{
    IDESourceCodeEditor *editor = _editor;
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

- (void)closeAllButActive 
{
    IDESourceCodeEditor *editor = _editor;
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
}

- (void)setHorizontal
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BH:self];
}

- (void)setVertical
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BV:self];
}

@end
