//
//  XVimWindowEvaluator.m
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimWindowEvaluator.h"
#import "XVimWindow.h"
#import "IDEKit.h"

/**
 * XVim Window - View structure:
 *
 * IDEWorkspaceWindowController  --- IDEWorkSpaceWindow
 *       |- IDEWorkspaceTabController
 *       |           |- Navigation Area
 *       |           |- Editor Area
 *       |           |- Debug Area
 *       |- IDEWorkspaceTabController
 *                   |- Navigation Area
 *                   |- Editor Area
 *                   |- Debug Area
 *
 *
 * The top level window is IDEWorkspaceWindow.
 * If you double click a file in navigator then you'll get another IDEWorkspaceWindow.
 * Actuall manipulations on the window is taken by IDEWorkspaceWindowController which you can get by IDEWorkspaceWindow's windowController method.
 * IDEWordspaceWindowController(IDEWSC) has multiple tabs and each tab is controlled by IDEWorkspaceTabController(IDEWTC).
 * IDEWTC manages all the view's in a tab. It means that it has navigation, editor, debug areas.
 * If you have multiple tabs it means you have multiple navigations or editors or debug areas since each tab has its own these areas.
 * Only one IDEWTC is active at once and you can get the active one through "activeWorkspaceTabContrller" method in IDEWSC.
 *
 * Most of the editor view manipulation can be done vie the IDEWTC.
 * You can get the all the areas in an IDEWTC by _keyboardFocusAreas method.
 * It returns array of IDEViewController derived classes such as IDENavigationArea, IDEEditorContext, IDEDefaultDebugArea.
 **/

@implementation XVimWindowEvaluator

- (IDEWorkspaceTabController*)tabController:(XVimWindow*)window{
    return [[[window currentWorkspaceWindow] windowController] activeWorkspaceTabController];
}

- (IDEEditorArea*)editorArea:(XVimWindow*)window{
    IDEWorkspaceWindowController* ctrl =  [[window currentWorkspaceWindow] windowController];
    return [ctrl editorArea];
}

- (void)addEditorWindow{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:self.window];
    IDEEditorArea *editorArea = [self editorArea:self.window];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

- (XVimEvaluator*)n{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:self.window];
    IDEEditorArea *editorArea = [self editorArea:self.window];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
    return nil;
}

- (XVimEvaluator*)o{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:self.window];
    IDEEditorArea *editorArea = [self editorArea:self.window];
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

- (XVimEvaluator*)s{
    [self addEditorWindow];
    [[self tabController:self.window] changeToAssistantLayout_BH:self];
    return nil;
}

- (XVimEvaluator*)q{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:self.window];
    IDEEditorArea *editorArea = [self editorArea:self.window];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }
    
    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    if ([geniusMode canRemoveAssistantEditor] == NO){
        [workspaceTabController changeToStandardEditor:self];
    }else {
        [workspaceTabController removeAssistantEditor:self];
    }
    return nil;
}

- (XVimEvaluator*)v{
    [self addEditorWindow];
    [[self tabController:self.window] changeToAssistantLayout_BV:self];
    return nil;
}

- (XVimEvaluator*)h{
    IDEViewController* current = [[self tabController:self.window] _currentFirstResponderArea];
    IDEViewController* next;
    while(true){
        [[self tabController:self.window] moveKeyboardFocusToPreviousArea:self];
        next = [[self tabController:self.window] _currentFirstResponderArea];
        if( [[[next class] description] isEqualToString:@"IDEEditorContext" ]) {
            break;
        }
        if( next == current ){ // When the fucus reaches one round we stop.
            break;
        }
    }
    return nil;
}

- (XVimEvaluator*)j{
    IDEViewController* current = [[self tabController:self.window] _currentFirstResponderArea];
    IDEViewController* next;
    while(true){
        [[self tabController:self.window] moveKeyboardFocusToNextArea:self];
        next = [[self tabController:self.window] _currentFirstResponderArea];
        if( [[[next class] description] isEqualToString:@"IDEEditorContext" ]) {
            break;
        }
        if( next == current ){ // When the fucus reaches one round we stop.
            break;
        }
    }
    return nil;
}

- (XVimEvaluator*)k{
    return [self h];
}

- (XVimEvaluator*)l{
    return [self j];
}

@end