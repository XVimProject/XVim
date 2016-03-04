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
}

- (BOOL)isPlaygroundTextView
{
    return [self isMemberOfClass:NSClassFromString(@"IDEPlaygroundTextView")];
}

BOOL s_turnedOn;
- (void)xvim_drawRect:(NSRect)dirtyRect{ 
    //TRACE_LOG(@"%@", NSStringFromRect(dirtyRect));

    @try{
        NSGraphicsContext* context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
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
        
        // call original drawRect
        [self xvim_drawRect:dirtyRect];
        
        // this logic is effective when selecting text.
        XVimWindow* window = [self xvim_window];
        if( ![[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
            // Normal mode
            
            if ([self isPlaygroundTextView]) {
                // Playground
                if (![[[XVim instance] options] blinkcursor] || s_turnedOn){
                    [self _drawInsertionPointInRect:NSZeroRect color:[self insertionPointColor]];
                }
                s_turnedOn = NO;
            } else {
                // DVTSourceTextView
                NSUInteger glyphIndex = [self insertionPoint];
                NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
                if (CGRectIntersectsRect(NSRectToCGRect(dirtyRect), NSRectToCGRect(glyphRect))){
                    if( ![[[XVim instance] options] blinkcursor] || !s_turnedOn){
                        [window drawInsertionPointInRect:glyphRect color:[self insertionPointColor]];
                    }
                }
            }
        }
        [context restoreGraphicsState];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

// Drawing Caret
- (void)xvim__drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    //TRACE_LOG(@"aColor %@ %@", aColor, NSStringFromRect(aRect));
    @try{
        XVimWindow* window = [self xvim_window];
        if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
            // Use original behavior when insert mode.
            [self xvim__drawInsertionPointInRect:aRect color:aColor];
        } else {
            // Normal mode
            if ([self isPlaygroundTextView]){
                // Playground
                NSGraphicsContext* context = [NSGraphicsContext currentContext];
                [context saveGraphicsState];
                
                NSUInteger glyphIndex = [self insertionPoint];
                NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
                [window drawInsertionPointInRect:glyphRect color:aColor];
                
                [context restoreGraphicsState];
            } else {
                // DVTSourceTextView
            }
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

/**
 * @brief turnedOn
 */
- (void)xvim_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag{
    //TRACE_LOG(@"turnedOn %d %@", flag, NSStringFromRect(rect));
    XVimWindow* window = [self xvim_window];
    if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
        // Use original behavior when insert mode.
        [self xvim_drawInsertionPointInRect:rect color:color turnedOn:flag];
    } else {
        // Normal mode
        if ([self isPlaygroundTextView]){
            // Playground
            // method is called only when flag is YES for Playground.
            if (flag) {
                s_turnedOn = YES;
                NSUInteger glyphIndex = [self insertionPoint];
                NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
                [self setNeedsDisplayInRect:glyphRect];
            }
        } else {
            // DVTSourceTextView
            // method is called when flag is YES/NO for DVTSourceTextView.
            s_turnedOn = flag;
            NSUInteger glyphIndex = [self insertionPoint];
            NSRect glyphRect = [self xvim_boundingRectForGlyphIndex:glyphIndex];
            [self setNeedsDisplayInRect:glyphRect];
        }
    }
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

