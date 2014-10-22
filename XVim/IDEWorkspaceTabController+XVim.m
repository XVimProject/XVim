//
//  IDEWorkspaceTabController+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 10/23/14.
//
//

#import "Logger.h"
#import "IDEWorkspaceTabController+XVim.h"
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

enum EditorMode{
    STANDARD,
    GENIUS,
    VERSION
};

@implementation IDEWorkspaceTabController (XVim)

- (NSArray*)xvim_allEditorArea{
    NSMutableArray* otherViews = [[NSMutableArray alloc] init];
    for( IDEViewController* c in [self _keyboardFocusAreas] ){
        if( [[[c class] description] isEqualToString:@"IDEEditorContext"] ){
            [otherViews addObject:c];
        }
    }
    return otherViews;
}

- (void)xvim_addEditorVertically{
    [self xvim_addEditor];
    [self changeToAssistantLayout_RV:self];
}

- (void)xvim_addEditorHorizontally{
    [self xvim_addEditor];
    [self changeToAssistantLayout_BH:self];
}

// Vim does not jump focus more than 1 when it is relative jump
// but this method generalizes it and takes count to jump from current editor when relative is YES.
- (void)xvim_jumpFocus:(NSInteger)count relative:(BOOL)relative{
    if( count == 0 || count == NSIntegerMin ){
        return;
    }
    
    IDEEditorArea *editorArea = [self editorArea];
    if ([editorArea editorMode] != GENIUS) {
        DEBUG_LOG(@"editor not in genius mode, nothing to jump to");
        return;
    }

    IDEViewController* current = [self _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    NSInteger numEditors= (NSInteger)[allEditors count]; // Should be no problem to cast it to NSInteger
    if( 0 >= numEditors ){
        // Just in case
        return;
    }
    
    if( relative ){
        // Relative index (rotation)
        NSInteger idx = (NSInteger)[allEditors indexOfObject:current] + (count%numEditors) + numEditors; // add numEditors to make it always positive
        [allEditors[(NSUInteger)(idx%numEditors)] takeFocus];
    }else{
        // Absolute index (Note: both count and numEditors are not 0 here)
        count = MIN(ABS(count), numEditors) - 1; // -1 to convert it to array index
        [allEditors[(NSUInteger)(count%numEditors)] takeFocus];
    }
}

- (void)xvim_addEditor{
    IDEWorkspaceTabController *workspaceTabController = self;
    IDEEditorArea *editorArea = [self editorArea];
    if ([editorArea editorMode] != GENIUS){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

/**
 * For move focus calculations.
 * The basic thing doing here is ...
 *   Enumerate all the editors and
 *   for each editors compare the position of the corner to current editors corner.
 *    For example if its Ctrl-w + h, we compare "current editor's left edge" and "others right edge".
 *    If we find the right edge on the left of current editors left edge we take it as a candidate to move forcus on.
 *    But there may be more than 1 editor which is on the left of current editor we have to find 
 *    the editor whose right edge is closest to the current editors right edge.
 **/

- (void)xvim_moveFocusDown{
    IDEWorkspaceTabController* tabCtrl = self;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    
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
    
}

- (void)xvim_moveFocusUp{
    IDEWorkspaceTabController* tabCtrl = self;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    
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
    
}

- (void)xvim_moveFocusLeft{
    IDEWorkspaceTabController* tabCtrl = self;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    
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
}

- (void)xvim_moveFocusRight{
    IDEWorkspaceTabController* tabCtrl = self;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    
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
}

- (void)xvim_closeOtherEditors{
    // Not implemented.
    // This is a little difficult to implement
    // because Xcode has a concept of Assistant Editor.
}

- (void)xvim_closeCurrentEditor{
    // Not implemented.
    // This is a little difficult to implement
    // because Xcode has a concept of Assistant Editor.
}

- (void)xvim_removeAssistantEditor{
    IDEEditorArea *editorArea = self.editorArea;
    IDEEditorGeniusMode *geniusMode;
    switch([editorArea editorMode]){
        case STANDARD:
            return;
            break;
        case GENIUS:
            geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
            if ([geniusMode canRemoveAssistantEditor] == NO){
                [self changeToStandardEditor:self];
            }else {
                [self removeAssistantEditor:self];
            }
            break;
        case VERSION:
            return;
            break;
    }
}

@end
