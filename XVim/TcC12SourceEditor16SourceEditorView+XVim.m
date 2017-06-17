//
//  Created by pebble on 2017/06/13.
//

#import "TcC12SourceEditor16SourceEditorView+XVim.h"
#import "Logger.h"

#import "DVTFoundation.h"
#import "DVTKit.h"
#import "XVimEvaluator.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "DVTKit.h"
#import "XVimStatusLine.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "IDEKit.h"
#import "IDEEditorArea+XVim.h"
#import "DVTSourceTextView+XVim.h"
#import "NSEvent+VimHelper.h"
#import "NSObject+ExtraData.h"
#import "XVim.h"
#import "XVimUtil.h"
#import "XVimSearch.h"
#import <objc/runtime.h>
#import <string.h>
#import "NSTextView+VimOperation.h"

#import "XVimInsertEvaluator.h"
#import "NSTextView+VimOperation.h"
#import "NSObject+XVimAdditions.h"

#import "SourceEditor.h"

@implementation _TtC12SourceEditor16SourceEditorView (XVim)
+ (void)xvim_initialize{
    //[self xvim_swizzleInstanceMethod:@selector(setSelectedRanges:affinity:stillSelecting:) with:@selector(xvim_setSelectedRanges:affinity:stillSelecting:)];
    //[self xvim_swizzleInstanceMethod:@selector(selectAll:) with:@selector(xvim_selectAll:)];
    // [self hook:@"cut:"];  // Cut calls delete: after all. Do not need to hook
    // [self hook:@"copy:"];  // Does not change any state. Do not need to hook
    //[self xvim_swizzleInstanceMethod:@selector(paste:) with:@selector(xvim_paste:)];
    //[self xvim_swizzleInstanceMethod:@selector(delete:) with:@selector(xvim_delete:)];
    [self xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
    /*
    [self xvim_swizzleInstanceMethod:@selector(mouseDown:) with:@selector(xvim_mouseDown:)];
    [self xvim_swizzleInstanceMethod:@selector(drawRect:) with:@selector(xvim_drawRect:)];
    [self xvim_swizzleInstanceMethod:@selector(_drawInsertionPointInRect:color:) with:@selector(xvim__drawInsertionPointInRect:color:)];
    [self xvim_swizzleInstanceMethod:@selector(drawInsertionPointInRect:color:turnedOn:) with:@selector(xvim_drawInsertionPointInRect:color:turnedOn:)];
    [self xvim_swizzleInstanceMethod:@selector(didChangeText) with:@selector(xvim_didChangeText)];
    [self xvim_swizzleInstanceMethod:@selector(viewDidMoveToSuperview) with:@selector(xvim_viewDidMoveToSuperview)];
    [self xvim_swizzleInstanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:) with:@selector(xvim_observeValueForKeyPath:ofObject:change:context:)];
    [self xvim_swizzleInstanceMethod:@selector(shouldAutoCompleteAtLocation:) with:@selector(xvim_shouldAutoCompleteAtLocation:)];
    */
}

+ (void)xvim_finalize{
    /*
    [self xvim_swizzleInstanceMethod:@selector(setSelectedRanges:affinity:stillSelecting:) with:@selector(xvim_setSelectedRanges:affinity:stillSelecting:)];
    [self xvim_swizzleInstanceMethod:@selector(selectAll:) with:@selector(xvim_selectAll:)];
    */
    // [self hook:@"cut:"];  // Cut calls delete: after all. Do not need to hook
    // [self hook:@"copy:"];  // Does not change any state. Do not need to hook
    /*
    [self xvim_swizzleInstanceMethod:@selector(paste:) with:@selector(xvim_paste:)];
    [self xvim_swizzleInstanceMethod:@selector(delete:) with:@selector(xvim_delete:)];
    */
    [self xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
    /*
    [self xvim_swizzleInstanceMethod:@selector(mouseDown:) with:@selector(xvim_mouseDown:)];
    [self xvim_swizzleInstanceMethod:@selector(drawRect:) with:@selector(xvim_drawRect:)];
    [self xvim_swizzleInstanceMethod:@selector(_drawInsertionPointInRect:color:) with:@selector(xvim__drawInsertionPointInRect:color:)];
    [self xvim_swizzleInstanceMethod:@selector(drawInsertionPointInRect:color:turnedOn:) with:@selector(xvim_drawInsertionPointInRect:color:turnedOn:)];
    [self xvim_swizzleInstanceMethod:@selector(didChangeText) with:@selector(xvim_didChangeText)];
    [self xvim_swizzleInstanceMethod:@selector(viewDidMoveToSuperview) with:@selector(xvim_viewDidMoveToSuperview)];
    // We do not unhook this too. Since "addObserver" is called in viewDidMoveToSuperview we should keep this hook
    // (Calling observerValueForKeyPath in NSObject results in throwing exception)
    // [self xvim_swizzleInstanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:) with:@selector(xvim_observeValueForKeyPath:ofObject:change:context:)];
    [self xvim_swizzleInstanceMethod:@selector(shouldAutoCompleteAtLocation:) with:@selector(xvim_shouldAutoCompleteAtLocation:)];
    */
}

-  (void)xvim_keyDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"[%p]Event:%@, XVimNotation:%@", self, theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
        XVimWindow* window = [self xvim_window];
        if( nil == window ){
            [self xvim_keyDown:theEvent];
        } else {
            //DEBUG_LOG("documentURL [%@]", self.documentURL);
            if( [window handleKeyEvent:theEvent] ){
                // [self updateInsertionPointStateAndRestartTimer:YES];
                //return;
            }
            // Call Original keyDown:
            [self xvim_keyDown:theEvent];
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
        // For debugging purpose we rethrow the exception
        if( [XVim instance].options.debug ){
            @throw exception;
        }
    }
}

-  (void)xvim_mouseDown:(NSEvent *)theEvent{
}

- (BOOL)isIDEPlaygroundSourceTextView
{
    return [self isMemberOfClass:NSClassFromString(@"IDEPlaygroundTextView")];
}



static NSString* XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW = @"XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW";

- (void)xvim_viewDidMoveToSuperview {
    @try{
        if ( ![ self boolForName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW ] ) {
            [XVim.instance.options addObserver:self forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [XVim.instance.options addObserver:self forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [XVim.instance.searcher addObserver:self forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [XVim.instance.options addObserver:self forKeyPath:@"highlight" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [ self xvim_performOnDealloc:^{
                @try{
                    [XVim.instance.options removeObserver:self forKeyPath:@"hlsearch"];
                    [XVim.instance.options removeObserver:self forKeyPath:@"ignorecase"];
                    [XVim.instance.searcher removeObserver:self forKeyPath:@"lastSearchString"];
                    [XVim.instance.searcher removeObserver:self forKeyPath:@"highlight"];
                }
                @catch (NSException* exception){
                    ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
                    [Logger logStackTrace:exception];
                }
            }];
            [ self setBool:YES forName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW ];
        }
        
        [self xvim_viewDidMoveToSuperview];
        
        // Hide scroll bars according to options
        NSScrollView * scrollView = [self enclosingScrollView];
        [scrollView setPostsBoundsChangedNotifications:YES];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context {
    if([keyPath isEqualToString:@"ignorecase"] || [keyPath isEqualToString:@"hlsearch"] || [keyPath isEqualToString:@"lastSearchString"] || [keyPath isEqualToString:@"highlight"]){
        //[self setNeedsUpdateFoundRanges:YES];
        //[self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
    }
}

#pragma mark XVim Category Methods
- (IDEEditorArea*)xvim_editorArea{
    IDEWorkspaceWindowController* wc = [NSClassFromString(@"IDEWorkspaceWindowController") performSelector:@selector(workspaceWindowControllerForWindow:) withObject:[self window]];
    return [wc editorArea];
}

- (XVimWindow*)xvim_window{
    return [[self xvim_editorArea] xvim_window];
}

@end

@interface _TtC12SourceEditor16SourceEditorView()
@property NSUInteger insertionPoint;
@property XVimPosition insertionPosition;
//@property NSUInteger insertionColumn;  // This is readonly also internally
//@property NSUInteger insertionLine;    // This is readonly also internally
@property NSUInteger preservedColumn;
@property NSUInteger selectionBegin;
//@property XVimPosition selectionBeginPosition; // This is readonly also internally
@property XVIM_VISUAL_MODE selectionMode;
@property BOOL selectionToEOL;
@property CURSOR_MODE cursorode;
@property(readonly) NSMutableArray* foundRanges;

// Internal properties
@property(strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (void)xvim_syncState; // update self's properties with our variables
- (NSArray*)xvim_selectedRanges;
- (void)xvim_setSelectedRange:(NSRange)range;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)xvim_indentCharacterRange:(NSRange)range;
- (void)xvim_scrollCommon_moveCursorPos:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (NSUInteger)xvim_lineNumberAtMiddle;
- (NSRange)xvim_search:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward;
- (void)xvim_swapCaseForRange:(NSRange)range;
- (void)xvim_registerInsertionPointForUndo;
- (void)xvim_registerPositionForUndo:(NSUInteger)pos;
@end

@implementation _TtC12SourceEditor16SourceEditorView (VimOperation)

/**
 * Properties in this category uses NSObject+ExtraData to
 * store additional properties.
 **/

- (NSUInteger)insertionPoint{
    NSNumber* ret = [self dataForName:@"insertionPoint"];
    return nil == ret ? 0 : [ret unsignedIntegerValue];
}

- (void)setInsertionPoint:(NSUInteger)insertion{
    [self setUnsignedInteger:insertion forName:@"insertionPoint"];
}

- (XVimPosition)insertionPosition{
    return XVimMakePosition(self.insertionLine, self.insertionColumn);
}

- (void)setInsertionPosition:(XVimPosition)pos{
    // Not implemented yet (Just update corresponding insertionPoint)
}

- (NSUInteger)insertionColumn{
    /*
    return [self.textStorage xvim_columnOfIndex:self.insertionPoint];
     */
}

- (NSUInteger)insertionLine{
    /*
    return [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint];
     */
}

- (NSUInteger)selectionBegin{
    id ret = [self dataForName:@"selectionBegin"];
    return nil == ret ? 0 : [ret unsignedIntegerValue];
}

- (void)setSelectionBegin:(NSUInteger)selectionBegin{
    [self setUnsignedInteger:selectionBegin forName:@"selectionBegin"];
}

- (XVimPosition)selectionBeginPosition{
    /*
    return XVimMakePosition([self.textStorage xvim_lineNumberAtIndex:self.selectionBegin], [self.textStorage xvim_columnOfIndex:self.selectionBegin]);
     */
}

/*
- (NSUInteger)numberOfSelectedLines{
    if (XVIM_VISUAL_NONE == self.selectionMode) {
        return 0;
    }
    
    XVimRange lines = [self _xvim_selectedLines];
    return lines.end - lines.begin + 1;
}

- (BOOL)selectionToEOL{
    return [[self dataForName:@"selectionToEOL"] boolValue];
}

- (void)setSelectionToEOL:(BOOL)selectionToEOL{
    [self setBool:selectionToEOL forName:@"selectionToEOL"];
}

- (void)setCursorMode:(CURSOR_MODE)cursorMode{
    [self setInteger:cursorMode forName:@"cursorMode"];
}
*/

/*
- (NSURL*)documentURL{
    if( [self.delegate isKindOfClass:[IDEEditor class]] ){
        return [(IDEEditorDocument*)((IDEEditor*)self.delegate).document fileURL];
    }else{
        return nil;
    }
}
*/

- (void)setXvimDelegate:(id)xvimDelegate{
    [self setData:xvimDelegate forName:@"xvimDelegate"];
}

- (id)xvimDelegate{
    return [self dataForName:@"xvimDelegate"];
}

- (long long)currentLineNumber {

//#ifdef __USE_DVTKIT__
    if( [self isKindOfClass:[DVTSourceTextView class]] ){
        return [(DVTSourceTextView*)self _currentLineNumber];
    }
    /*
#else
#error You must implement here.
#endif
    NSAssert(NO, @"You must implement here if you do not use this with DVTSourceTextView");
    return -1;
     */
}

- (NSString*)xvim_string{
    //return [self.textStorage xvim_string];
}


@end


@implementation NSTextView(VimOperationPrivate)

- (IDEEditorArea*)xvim_editorArea{
    IDEWorkspaceWindowController* wc = [NSClassFromString(@"IDEWorkspaceWindowController") performSelector:@selector(workspaceWindowControllerForWindow:) withObject:[self window]];
    return [wc editorArea];
}

- (XVimWindow*)xvim_window{
    return [[self xvim_editorArea] xvim_window];
}

/*
- (NSURL*)documentURL{
    if( [self.delegate isKindOfClass:[IDEEditor class]] ){
        return [(IDEEditorDocument*)((IDEEditor*)self.delegate).document fileURL];
    }else{
        return nil;
    }
}
*/


@end


