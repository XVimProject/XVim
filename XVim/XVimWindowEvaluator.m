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
    [[self tabController:self.window] changeToAssistantLayout_RV:self];
    return nil;
}

- (NSArray*)allEditorArea:(XVimWindow*)window{
    IDEWorkspaceTabController* tabCtrl = [self tabController:window];
    NSMutableArray* otherViews = [[NSMutableArray alloc] init];
    for( IDEViewController* c in [tabCtrl _keyboardFocusAreas] ){
        if( [[[c class] description] isEqualToString:@"IDEEditorContext"] ){
            [otherViews addObject:c];
        }
    }
    return otherViews;
}

/**
 * For Ctrl-w + h,j,k,l calculations.
 * The basic thing doing here is ...
 *   Enumerate all the editors and
 *   for each editors compare the position of the corner to current editors corner.
 *    For example if its Ctrl-w + h, we compare "current editor's left edge" and "others right edge".
 *    If we find the right edge on the left of current editors left edge we take it as a candidate to move forcus on.
 *    But there may be more than 1 editor which is on the left of current editor we have to find 
 *    the editor whose right edge is closest to the current editors right edge.
 **/
- (XVimEvaluator*)h{
    IDEWorkspaceTabController* tabCtrl = [self tabController:self.window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:self.window];
    
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

- (XVimEvaluator*)j{
    IDEWorkspaceTabController* tabCtrl = [self tabController:self.window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:self.window];
    
    // Compare current view's bottom and other views' top positions.(Find the top is bigger the the bottom but nearest one)
    // Remember that y gets bigger when gose to upper side.
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

- (XVimEvaluator*)k{
    IDEWorkspaceTabController* tabCtrl = [self tabController:self.window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:self.window];
    
    // Compare current view's bottom and other views' top positions.(Find the top is bigger the the bottom but nearest one)
    // Remember that y gets bigger when gose to upper side.
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

- (XVimEvaluator*)l{
    IDEWorkspaceTabController* tabCtrl = [self tabController:self.window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:self.window];
    
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

/*
 CTRL-W w   Move cursor to window below/right of the current one. If there is
            no window below or right, go to top-left window.
 */
- (XVimEvaluator*)w{
    // TODO: Must handle numericMode  properly.
    //       Currently we do not have good way to know if current evaluator is in numericMode
    //       Accessing parent evaluator directly is not good practice.
    NSInteger count = NSIntegerMax < [self numericArg] ? NSIntegerMax : (NSInteger)[self numericArg] ;
    [self jumpFocus:count relative:![self.parent numericMode]];
    return nil;
}

- (XVimEvaluator*)C_w{
    return [self w];
}

/*
 CTRL-W W   Move cursor to window above/left of current one. If there is no
            window above or left, go to bottom-right window.
 */
- (XVimEvaluator*)W{
    NSInteger count = NSIntegerMax < [self numericArg] ? NSIntegerMax : (NSInteger)[self numericArg];
    [self jumpFocus:-count  relative:![self.parent numericMode]];
    return nil;
}

// Vim does not jump focus more than 1 when it is relative jump
// but this method generalizes it and takes count to jump from current editor when relative is YES.
- (void)jumpFocus:(NSInteger)count relative:(BOOL)relative{
    NSAssert( 0 != count, @"Must not be 0" );
    NSAssert( count != NSIntegerMin, @"Can not specify NSIntegerMin value as a count");
    
    IDEEditorArea *editorArea = [self editorArea:self.window];
    if ([editorArea editorMode] != 1) {
        DEBUG_LOG(@"editor not in genius mode, nothing to jump to")
        return;
    }

    IDEWorkspaceTabController* tabCtrl = [self tabController:self.window];
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self allEditorArea:self.window];
    NSInteger numEditors= (NSInteger)[allEditors count]; // Should be no problem to cast it to NSInteger
    if( 0 == numEditors ){
        // Just in case
        return;
    }
    
    if( relative ){
        // Relative index (rotation)
        NSInteger idx = (NSInteger)[allEditors indexOfObject:current] + (count%numEditors) + numEditors; // add numEditors to make it always positive
        [allEditors[(NSUInteger)idx%numEditors] takeFocus];
    }else{
        // Absolute index (Note: both count and numEditors are not 0 here)
        count = MIN(ABS(count), numEditors) - 1; // -1 to convert it to array index
        [allEditors[(NSUInteger)count%numEditors] takeFocus];
    }
}

@end