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
#import "Utils.h"

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
 * Actual manipulations on the window are taken by IDEWorkspaceWindowController which you can get by IDEWorkspaceWindow's windowController method.
 * IDEWordspaceWindowController(IDEWSC) has multiple tabs and each tab is controlled by IDEWorkspaceTabController(IDEWTC).
 * IDEWTC manages all the views in a tab. It means that it has navigation, editor, debug areas.
 * If you have multiple tabs it means you have multiple navigations or editors or debug areas since each tab has its own areas.
 * Only one IDEWTC is active at once and you can get the active one through "activeWorkspaceTabContrller" method in IDEWSC.
 *
 * Most of the editor view manipulation can be done via the IDEWTC.
 * You can get all the areas in an IDEWTC by _keyboardFocusAreas method.
 * It returns an array of IDEViewController derived classes such as IDENavigationArea, IDEEditorContext, IDEDefaultDebugArea.
 **/

@implementation XVimWindowEvaluator

- (IDEWorkspaceTabController*)tabController:(XVimWindow*)window{
    return [[[window currentWorkspaceWindow] windowController] activeWorkspaceTabController];
}

- (IDEEditorArea*)editorArea:(XVimWindow*)window{
    IDEWorkspaceWindowController* ctrl =  [[window currentWorkspaceWindow] windowController];
    return [ctrl editorArea];
}

- (void)addEditorWindow:(XVimWindow*)window{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:window];
    IDEEditorArea *editorArea = [self editorArea:window];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

- (XVimEvaluator*)n:(XVimWindow*)window{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:window];
    IDEEditorArea *editorArea = [self editorArea:window];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
    return nil;
}

- (XVimEvaluator*)o:(XVimWindow*)window{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:window];
    IDEEditorArea *editorArea = [self editorArea:window];
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

- (XVimEvaluator*)s:(XVimWindow*)window{
    [self addEditorWindow:window];
    [[self tabController:window] changeToAssistantLayout_BH:self];
    return nil;
}

- (XVimEvaluator*)q:(XVimWindow*)window{
    IDEWorkspaceTabController *workspaceTabController = [self tabController:window];
    IDEEditorArea *editorArea = [self editorArea:window];
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

- (XVimEvaluator*)v:(XVimWindow*)window{
    [self addEditorWindow:window];
    [[self tabController:window] changeToAssistantLayout_BV:self];
    return nil;
}


- (NSArray*)allEditorArea:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    NSMutableArray* otherViews = [[[NSMutableArray alloc] init] autorelease];
    for( IDEViewController* c in [tabCtrl _keyboardFocusAreas] ){
        if( [[[c class] description] isEqualToString:@"IDEEditorContext"] ){
            [otherViews addObject:c];
        }
    }
    return otherViews;
}

/**
 * For Ctrl-w + h,j,k,l calculations.
 * The basic thing happening here is ...
 *   Enumerate all the editors and
 *   for each editor compare the position of the corner to the current editor's corner.
 *    For example if it's Ctrl-w + h, we compare "current editor's left edge" and "other's right edge".
 *    If we find the right edge on the left of current editor's left edge we take it as a candidate to move focus on.
 *    But there may be more than 1 editor which is on the left of the current editor. We have to find 
 *    the editor whose right edge is closest to the current editor's right edge.
 **/
- (XVimEvaluator*)h:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:window];
    
    CGPoint current_point = [[current view] frame].origin; // Left bottom point
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is smaller than this left value.
    CGPoint point;
    CGFloat maximum_right = 0; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for( IDEEditorContext* c in allEditors){
        point = RightBottom([[c view] convertRect:[c.view frame]  toView:nil]);
        if( point.x <= current_point.x ){
            // This view is at least on the left of the current view.
            if( maximum_right < point.x ){
                targetEditor = c;
                maximum_right = point.x;
            }
        }
    }
    [targetEditor takeFocus];
    return nil;
}


- (XVimEvaluator*)j:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:window];
    
    // Compare current view's bottom and other views' top positions.(Find the top that is bigger the the bottom but nearest one)
    // Remember that y gets bigger when it goes to the upper side.
    CGPoint current_point = [current.view frame].origin; //Left bottom
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is smaller than this left value.
    CGPoint point;
    CGFloat maximum_top = 0; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for( IDEEditorContext* c in allEditors){
        point = LeftTop([[c view] convertRect:[c.view frame] toView:nil]);
        if( point.y <= current_point.y ){
            if( maximum_top < point.y ){
                targetEditor = c;
                maximum_top = point.y;
            }
        }
    }
    [targetEditor takeFocus];
    return nil;
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:window];
    
    // Compare current view's bottom and other views' top positions.(Find the top is bigger the the bottom but nearest one)
    // Remember that y gets bigger when it goes to upper side.
    CGPoint current_point = LeftTop([current.view frame]);
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is smaller than this left value.
    CGPoint point;
    CGFloat minimum_top = FLT_MAX; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for( IDEEditorContext* c in allEditors){
        point = [[c view] convertRect:[c.view frame] toView:nil].origin;
        if( point.y >= current_point.y ){
            if( minimum_top > point.y ){
                targetEditor = c;
                minimum_top = point.y;
            }
        }
    }
    [targetEditor takeFocus];
    return nil;
}

- (XVimEvaluator*)l:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:window];
    
    CGPoint current_point = RightBottom([[current view] frame]);
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is smaller than this left value.
    CGPoint point;
    CGFloat minimum_left = FLT_MAX; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for( IDEEditorContext* c in allEditors){
        point = [[c view] convertRect:[c.view frame]  toView:nil].origin; // Left Bottom
        if( point.x >= current_point.x ){
            if( minimum_left > point.x ){
                targetEditor = c;
                minimum_left = point.x;
            }
        }
    }
    [targetEditor takeFocus];
    return nil;
}

@end
