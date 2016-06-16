//
//  DVTSourceTextView.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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

@implementation DVTSourceTextView(XVim)

+ (void)xvim_initialize{

    [self xvim_swizzleInstanceMethod:@selector(setSelectedRanges:affinity:stillSelecting:) with:@selector(xvim_setSelectedRanges:affinity:stillSelecting:)];
    [self xvim_swizzleInstanceMethod:@selector(selectAll:) with:@selector(xvim_selectAll:)];
    // [self hook:@"cut:"];  // Cut calls delete: after all. Do not need to hook
    // [self hook:@"copy:"];  // Does not change any state. Do not need to hook
    [self xvim_swizzleInstanceMethod:@selector(paste:) with:@selector(xvim_paste:)];  
    [self xvim_swizzleInstanceMethod:@selector(delete:) with:@selector(xvim_delete:)];  
    [self xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
    [self xvim_swizzleInstanceMethod:@selector(mouseDown:) with:@selector(xvim_mouseDown:)];
    [self xvim_swizzleInstanceMethod:@selector(drawRect:) with:@selector(xvim_drawRect:)];
    [self xvim_swizzleInstanceMethod:@selector(_drawInsertionPointInRect:color:) with:@selector(xvim__drawInsertionPointInRect:color:)];
    [self xvim_swizzleInstanceMethod:@selector(drawInsertionPointInRect:color:turnedOn:) with:@selector(xvim_drawInsertionPointInRect:color:turnedOn:)];
    [self xvim_swizzleInstanceMethod:@selector(didChangeText) with:@selector(xvim_didChangeText)];
    [self xvim_swizzleInstanceMethod:@selector(viewDidMoveToSuperview) with:@selector(xvim_viewDidMoveToSuperview)];
    [self xvim_swizzleInstanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:) with:@selector(xvim_observeValueForKeyPath:ofObject:change:context:)];
    [self xvim_swizzleInstanceMethod:@selector(shouldAutoCompleteAtLocation:) with:@selector(xvim_shouldAutoCompleteAtLocation:)];
}

+ (void)xvim_finalize{
    [self xvim_swizzleInstanceMethod:@selector(setSelectedRanges:affinity:stillSelecting:) with:@selector(xvim_setSelectedRanges:affinity:stillSelecting:)];
    [self xvim_swizzleInstanceMethod:@selector(selectAll:) with:@selector(xvim_selectAll:)];
    // [self hook:@"cut:"];  // Cut calls delete: after all. Do not need to hook
    // [self hook:@"copy:"];  // Does not change any state. Do not need to hook
    [self xvim_swizzleInstanceMethod:@selector(paste:) with:@selector(xvim_paste:)];  
    [self xvim_swizzleInstanceMethod:@selector(delete:) with:@selector(xvim_delete:)];  
    [self xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
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
}

#pragma mark XVim Hook Methods

- (void)xvim_setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
    [self xvim_setSelectedRanges:ranges affinity:affinity stillSelecting:flag];
    [(NSTextView*)self xvim_syncStateFromView];
    [(NSTextView*)self setNeedsDisplay:YES];
}

- (void)xvim_selectAll:(id)sender{
    XVimWindow* window = [self xvim_window];
    [self xvim_selectAll:sender];
    [window syncEvaluatorStack];  
}

- (void)xvim_paste:(id)sender{
    XVimWindow* window = [self xvim_window];
    [self xvim_paste:sender];
    [window syncEvaluatorStack];  
    
}

- (void)xvim_delete:(id)sender{
    XVimWindow* window = [self xvim_window];
    [self xvim_delete:sender];
    [window syncEvaluatorStack];  
}

-  (void)xvim_keyDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"[%p]Event:%@, XVimNotation:%@", self, theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
        XVimWindow* window = [self xvim_window];
        if( nil == window ){
            [self xvim_keyDown:theEvent];
            return;
        }
        
        if( [window handleKeyEvent:theEvent] ){
            [self updateInsertionPointStateAndRestartTimer:YES];
            return;
        }
        // Call Original keyDown:
        [self xvim_keyDown:theEvent];
        return;
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
	// For debugging purpose we rethrow the exception
	if( [XVim instance].options.debug ){
	    @throw exception;
	}
    }
    return;
}

-  (void)xvim_mouseDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"Event:%@", theEvent.description);
        [self xvim_mouseDown:theEvent];
        // When mouse down, NSTextView ( self in this case) takes the control of event loop internally
        // and the method call above does not return immidiately and block until mouse up. mouseDragged: method is called from inside it but
        // it never calls mouseUp: event. After mouseUp event is handled internally it returns the control.
        // So the code here is executed AFTER mouseUp event is handled.
        // At this point NSTextView changes its selectedRange so we usually have to sync XVim state.
        
        // TODO: To make it simple we should forward mouse events
        //       to handleKeyStroke as a special key stroke
        //       and the key stroke should be handled by the current evaluator.
        XVimWindow* window = [self xvim_window];
        [window syncEvaluatorStack];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

// NSRect s_lastCaret;
- (void)xvim_drawRect:(NSRect)dirtyRect{ 
    // TRACE_LOG(@"drawRect dirtyRect(%f,%f,%f,%f)", dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height);

    @try{
        if( XVim.instance.options.hlsearch ){
            XVimMotion* lastSearch = [XVim.instance.searcher motionForRepeatSearch];
            if( nil != lastSearch.regex && !XVim.instance.foundRangesHidden ){
                [self xvim_updateFoundRanges:lastSearch.regex withOption:lastSearch.option];
            } else {
                [self xvim_clearHighlightText];
            }
        }else{
            [self xvim_clearHighlightText];
        }
        
        [self xvim_drawRect:dirtyRect];
        
        if( self.selectionMode != XVIM_VISUAL_NONE ){
            // NSTextView does not draw insertion point when selecting text. We have to draw insertion point by ourselves.
            NSUInteger glyphIndex = [self insertionPoint];
            NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
            [[[self insertionPointColor] colorWithAlphaComponent:0.5] set];
            NSRectFillUsingOperation( glyphRect, NSCompositeSourceOver);
        }
        
        /*
        if( ![XVim instance].options.blinkcursor ){
            // We need to draw caret on drawRect when it is not blinkcursor.
            // This is required when the view is IDEPlaygroundSourceTextView because
            // it doesn't use drawInsertionPointInRect to clear caret but user drawRect to clear the caret.
            // The reason "turnedOn" is set to NO is because
            // the drawing caret on this timing corresponds to clear caret.
            // This will keep consistence when it goes into Insert mode.
            [self drawInsertionPointInRect:s_lastCaret color:[self insertionPointColor] turnedOn:NO];
        }
         */
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

// Drawing Caret
- (void)xvim__drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    // TRACE_LOG(@"%f %f %f %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
    @try{
        XVimWindow* window = [self xvim_window];
        if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
            // Use original behavior when insert mode.
            return [self xvim__drawInsertionPointInRect:aRect color:aColor];
        }

        // Erase old cursor.
        // [self xvim_drawRect:s_lastCaret];
        
        NSUInteger glyphIndex = [self insertionPoint];
        NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
        // s_lastCaret = glyphRect;

        NSGraphicsContext *context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        [[NSBezierPath bezierPathWithRect:[self visibleRect]] setClip];
        [window drawInsertionPointInRect:glyphRect color:aColor];
        [context restoreGraphicsState];
        
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}
- (void)xvim_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag{
    XVimWindow* window = [self xvim_window];
    if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
        // Use original behavior when insert mode.
        return [self xvim_drawInsertionPointInRect:rect color:color turnedOn:flag];
    }

    /*
    BOOL shouldClear = NO;
    BOOL shouldDraw = NO;


    if( ![self performSelector:@selector(_isLayerBacked)] ){
        shouldClear = YES;
        shouldDraw = ![[[XVim instance] options] blinkcursor] || flag;
    }
    else {
        shouldClear = YES;
        shouldDraw = YES;
    }
     */

    /*
    if (shouldClear) {
        [self xvim_drawRect:s_lastCaret];
    }

    if (shouldDraw) {
        [self _drawInsertionPointInRect:rect color:color];
    }
    */

    return;
}
- (void)xvim_didChangeText{
    [self setNeedsUpdateFoundRanges:YES];
    [self xvim_didChangeText];
}

- (BOOL)xvim_shouldAutoCompleteAtLocation:(unsigned long long)location{
    XVimWindow* window = [self xvim_window];
    return [window shouldAutoCompleteAtLocation:(unsigned long long)location];
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
        [self setNeedsUpdateFoundRanges:YES];
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
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

