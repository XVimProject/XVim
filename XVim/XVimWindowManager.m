//
//  XVimWindowManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowManager.h"
#import "IDESourceEditor.h"

#import "IDEKit.h"

static XVimWindowManager *_instance = nil;

@interface XVimWindowManager() {
	IDESourceCodeEditor *_editor;
}
- (void)setHorizontal;
- (void)setVertical;
@property (weak) IDESourceCodeEditor *editor ;
@property (weak) IDEWorkspaceTabController *workspaceTabController ;
@property (weak) IDEEditorArea *editorArea;
@property (weak) IDEEditorModeViewController* editorModeViewController ;
@property (weak) IDEWorkspaceWindow* workspaceWindow ;
@end

@implementation XVimWindowManager
@synthesize  editor = _editor;
@dynamic workspaceTabController;
@dynamic editorArea;
@dynamic editorModeViewController;
@dynamic workspaceWindow;

-(IDEWorkspaceTabController *) workspaceTabController { return  [self.editor workspaceTabController] ;}
-(IDEEditorArea *) editorArea { return self.workspaceTabController.editorArea; }
-(IDEEditorModeViewController*) editorModeViewController { return self.editorArea.editorModeViewController; }
-(IDEWorkspaceWindow*) workspaceWindow { return (IDEWorkspaceWindow*)[self.editor.textView window]; }

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
    [ workspaceTabController changeToStandardEditor:self];
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

// To do: this only jumps to the next editor in the set of editors. Need to generalise this to allow backward motion, and motion in a direction
-(void)jumpToOtherEditor
{
    if ( self.editorModeViewController != nil && [ self.editorModeViewController isMemberOfClass:NSClassFromString(@"IDEEditorGeniusMode") ])
    {
        IDEEditorContext* activeContext = [(IDESourceCodeEditor*)[(DVTSourceTextView*)[ self.workspaceWindow firstResponder ] delegate ] editorContext ];
        NSArray* editorContexts = [ self.editorModeViewController editorContexts ];
        NSUInteger idxOfActiveContext = [ editorContexts indexOfObject:activeContext ];
        IDEEditorContext* nextContext = [ editorContexts objectAtIndex:((idxOfActiveContext + 1) % [editorContexts count] )] ;
        [ nextContext takeFocus ];
    }
}
@end
