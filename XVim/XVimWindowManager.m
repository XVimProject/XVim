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
NSInteger yContextSort(id ctx1, id ctx2, void *context);
NSInteger xContextSort(id ctx1, id ctx2, void *context);
void dumpEditorContexts(NSString*prefix, IDEEditorContext* activeContext, NSArray* editorContexts);
NSRect editorContextWindowFrame(IDEEditorContext* obj1);
NSComparisonResult invertComparisonResult(NSComparisonResult comp);

typedef bool (^XvimDecider)(id obj) ;

@interface NSArray(Xvim)
-(NSArray*)filteredArrayUsingDecider:(XvimDecider)decider ;
@end

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
@property (weak) IDEEditorContext* activeContext;
@property (weak) NSArray* editorContexts;
@property (assign) XvimEditorMode editorMode ;
@property (assign) XvimAssistantLayoutMode assistantEditorsLayoutMode;
@end

@implementation XVimWindowManager
@synthesize  editor = _editor;
@dynamic workspaceTabController;
@dynamic editorArea;
@dynamic editorModeViewController;
@dynamic workspaceWindow;
@dynamic activeContext;
@dynamic editorContexts;
@dynamic editorMode;
@dynamic assistantEditorsLayoutMode ;


// 0 = horizontal, 1 = vertical
typedef enum { XVIM_HORIZONTAL_MOTION, XVIM_VERTICAL_MOTION } XvimWindowMotion ;
typedef bool DirectionDecisions[4] ;
static DirectionDecisions
    canJumpBetweenPrimaryAndSecondaryWhenMoving[] = {
        /*  Columns:
         0 = Can jump horizontally between assistant and primary,
         1 = Can jump vertically between assistant and primary,
         2 = Can move horizontally between the secondary editors,
         3 = Can move vertically between the secondary editors
         */
         
        /* 0 = XVIM_RIGHT_HORIZONTAL  */  { true,  false, false, true  }
        /* 1 = XVIM_RIGHT_VERTICAL    */, { true,  false, true,  false }
        /* 2 = UNDEFINED              */, { false, false, false, false }
        /* 3 = UNDEFINED              */, { false, false, false, false }
        /* 4 = UNDEFINED              */, { false, false, false, false }
        /* 5 = UNDEFINED              */, { false, false, false, false }
        /* 6 = XVIM_BOTTOM_HORIZONTAL */, { false, true,  false, true  }
        /* 7 = XVIM_BOTTOM_VERTICAL   */, { false, true,  true,  false }
    };

-(IDEWorkspaceTabController *) workspaceTabController { return  [self.editor workspaceTabController] ;}
-(IDEEditorArea *) editorArea { return self.workspaceTabController.editorArea; }
-(IDEEditorModeViewController*) editorModeViewController { return self.editorArea.editorModeViewController; }
-(IDEWorkspaceWindow*) workspaceWindow { return (IDEWorkspaceWindow*)[self.editor.textView window]; }
-(XvimEditorMode)editorMode { return (XvimEditorMode)self.editorArea.editorMode; }
-(XvimAssistantLayoutMode)assistantEditorsLayoutMode { return (XvimAssistantLayoutMode)self.workspaceTabController.assistantEditorsLayout; }
-(IDEEditorContext*)activeContext
{
    return [(IDESourceCodeEditor*)[(DVTSourceTextView*)[ self.workspaceWindow firstResponder ] delegate ] editorContext ];
}
-(NSArray*)editorContexts
{
    NSArray* contexts = nil;
    if ( self.editorModeViewController != nil && self.editorMode == XVIM_EDITOR_MODE_GENIUS )
    {
        contexts = [ self.editorModeViewController editorContexts ];
    }
    else if (self.activeContext)
    {
        contexts = [ NSArray arrayWithObject:self.activeContext ];
    }
    return contexts;
}

+ (void)createWithEditor:(IDESourceCodeEditor*)editor
{
    XVimWindowManager *instance = [[self alloc] initWithEditor:editor ];
    _instance = instance;
}

+ (XVimWindowManager*)instance
{
	return _instance;
}

- (id)initWithEditor:(IDESourceCodeEditor*)editor
{
    self = [super init];
    if (self) {
        _editor = editor;
        }
    return self;
}

- (void)addEditorWindow
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    if (self.editorMode != XVIM_EDITOR_MODE_GENIUS){
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
    if (self.editorMode != XVIM_EDITOR_MODE_GENIUS){
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
    NSArray* editorContexts = self.editorContexts;
    if (editorContexts) {
        NSUInteger idxOfActiveContext = [ editorContexts indexOfObject:self.activeContext ];
        IDEEditorContext* nextContext = [ editorContexts objectAtIndex:((idxOfActiveContext + 1) % [editorContexts count] )] ;
        [ nextContext takeFocus ];
    }
}
-(void)jumpToEditorDown
{
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION];
        bool canJumpVerticallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return;
        }
        if (!canJumpVerticallyInSecondaryEditors && !self.activeContext.isPrimaryEditorContext) {
            return;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:yContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if (idxOfActiveContext != NSNotFound && idxOfActiveContext > 0)
        {
            IDEEditorContext* nextContext = [ sortedEditorContexts objectAtIndex:(idxOfActiveContext - 1) ] ;
            [ nextContext takeFocus ];
        }
    }
    
}
-(void)jumpToEditorUp
{
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION];
        bool canJumpVerticallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return;
        }
        if (!canJumpVerticallyInSecondaryEditors
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpBetweenAssistantAndPrimary) {
            return;
        }
        if (canJumpBetweenAssistantAndPrimary
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpVerticallyInSecondaryEditors)
        {
            [ self.editorModeViewController.primaryEditorContext takeFocus];
            return;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:yContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if ( idxOfActiveContext != NSNotFound && idxOfActiveContext < ([sortedEditorContexts count]-1))
        {
            IDEEditorContext* nextContext = [ sortedEditorContexts objectAtIndex:(idxOfActiveContext + 1) ] ;
            [ nextContext takeFocus ];
        }
    }
}
-(void)jumpToEditorLeft
{
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION];
        bool canJumpHorizontallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return;
        }
        
        if (!canJumpHorizontallyInSecondaryEditors
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpBetweenAssistantAndPrimary)
        {
            return;
        }
        if (canJumpBetweenAssistantAndPrimary
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpHorizontallyInSecondaryEditors)
        {
            [ self.editorModeViewController.primaryEditorContext takeFocus];
            return;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:xContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if (idxOfActiveContext != NSNotFound && idxOfActiveContext > 0)
        {
            IDEEditorContext* nextContext = [ sortedEditorContexts objectAtIndex:((idxOfActiveContext - 1) % [sortedEditorContexts count] )] ;
            [ nextContext takeFocus ];
        }
    }
    
}
-(void)jumpToEditorRight
{
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION];
        bool canJumpHorizontallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return;
        }
        if (!canJumpHorizontallyInSecondaryEditors && !self.activeContext.isPrimaryEditorContext) {
            return;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:xContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if ( idxOfActiveContext != NSNotFound && idxOfActiveContext < ([sortedEditorContexts count]-1))
        {
            IDEEditorContext* nextContext = [ sortedEditorContexts objectAtIndex:((idxOfActiveContext + 1) % [sortedEditorContexts count] )] ;
            [ nextContext takeFocus ];
        }
    }
}
@end


NSInteger yContextSort(id ctx1, id ctx2, void *context)
{
    NSPoint o1 = editorContextWindowFrame((IDEEditorContext*)ctx1).origin;
    NSPoint o2 = editorContextWindowFrame((IDEEditorContext*)ctx2).origin;
    return (o1.y < o2.y) ? NSOrderedAscending
    : ( (o1.y > o2.y) ? NSOrderedDescending
       : ((context == NULL) ? NSOrderedSame
          : invertComparisonResult( xContextSort(ctx1, ctx2, NULL ) ) ) );
}


NSInteger xContextSort(id ctx1, id ctx2, void *context)
{
    NSPoint o1 = editorContextWindowFrame((IDEEditorContext*)ctx1).origin;
    NSPoint o2 = editorContextWindowFrame((IDEEditorContext*)ctx2).origin;
    return (o1.x < o2.x) ? NSOrderedAscending
    : ( (o1.x > o2.x) ? NSOrderedDescending
       : (( context == NULL) ? NSOrderedSame
          : invertComparisonResult( yContextSort(ctx1, ctx2, NULL) ) ) );
}

NSComparisonResult invertComparisonResult(NSComparisonResult comp)
{
    return ( comp == NSOrderedAscending ) ? NSOrderedDescending : ( ( comp == NSOrderedDescending ) ? NSOrderedAscending : NSOrderedSame ) ;
}

NSRect editorContextWindowFrame(IDEEditorContext* obj1)
{
    NSView* view1 = ((IDEEditorContext*)obj1).view;
    NSRect view1Frame = [ view1 convertRect:[view1 frame] toView:nil ];
    return view1Frame;
}

@implementation NSArray(Xvim)

-(NSArray*)filteredArrayUsingDecider:(XvimDecider)decider
{
    NSMutableArray* filtered = [NSMutableArray array];
    for (id item in self)
    {
        if (decider(item))
        {
            [filtered addObject:item];
        }
    }
    return filtered;
    
}

@end