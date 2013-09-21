//
//  DVTSourceTextView.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#define __XCODE5__

#import "DVTFoundation.h"
#import "DVTKit.h"
#import "DVTSourceTextViewHook.h"
#import "XVimEvaluator.h"
#import "XVimWindow.h"
#import "Hooker.h"
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

@implementation DVTSourceTextViewHook

+ (void)hook:(NSString*)method{
    NSString* cls = @"DVTSourceTextView";
    NSString* thisCls = NSStringFromClass([self class]);
    [Hooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void)unhook:(NSString*)method{
    NSString* cls = @"DVTSourceTextView";
    [Hooker unhookClass:cls method:method];
}

+ (void)hook{
    [self hook:@"initWithCoder:"];
    [self hook:@"initWithFrame:textContainer:"];
    [self hook:@"dealloc"];
    [self hook:@"setSelectedRanges:affinity:stillSelecting:"];
    [self hook:@"keyDown:"];
    [self hook:@"mouseDown:"];
    [self hook:@"drawRect:"];
    [self hook:@"_drawInsertionPointInRect:color:"];
    [self hook:@"drawInsertionPointInRect:color:turnedOn:"];
    [self hook:@"didChangeText"];
    [self hook:@"viewDidMoveToSuperview"];
    [self hook:@"shouldChangeTextInRange:replacementString"];
    [self hook:@"observeValueForKeyPath:ofObject:change:context:"];
}

+ (void)unhook{
    // We never unhook these two methods.
    // This is because we always have to control observers for XVimOptions
    // If we unhook these, these may be a memory leak or it leads crash when a removing observer which has not been added as a observer in dealloc method.
    // [self unhook:@"initWithCoder:"];
    // [self unhook:@"initWithFrame:textContainer:"];
    // [self unhook:@"dealloc"]; 
    [self unhook:@"setSelectedRanges:affinity:stillSelecting"];
    [self unhook:@"keyDown:"];
    [self unhook:@"mouseDown:"];
    [self unhook:@"drawRect:"];
    [self unhook:@"_drawInsertionPointInRect:color:"];
    [self unhook:@"_drawInsertionPointInRect:color:turnedOn:"];
    [self unhook:@"didChangeText"];
    [self unhook:@"viewDidMoveToSuperview"];
    [self unhook:@"shouldChangeTextInRange:replacementString"];
    // We do not unhook this too. Since "addObserver" is called in initWithCoder we should keep this hook
    // (Calling observerValueForKeyPath in NSObject results in throwing exception)
    //[self unhook:@"observeValueForKeyPath:ofObject:change:context:"];
}

#ifdef __XCODE5__
- (id)initWithFrame:(NSRect)rect textContainer:(NSTextContainer *)container{
    TRACE_LOG(@"ENTER");
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    id obj =  (DVTSourceTextViewHook*)[base initWithFrame_:rect textContainer:container];
    if( nil != obj ){
        [XVim.instance.options addObserver:obj forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.options addObserver:obj forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.searcher addObserver:obj forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    return obj;
}

- (id)initWithCoder:(NSCoder*)coder{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    id obj =  (DVTSourceTextViewHook*)[base initWithCoder_:coder];
    if( nil != obj ){
        [XVim.instance.options addObserver:obj forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.options addObserver:obj forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.searcher addObserver:obj forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    return (DVTSourceTextViewHook*)[base initWithCoder_:coder];
}
#else
- (id)initWithFrame:(NSRect)rect textContainer:(NSTextContainer *)container{
    TRACE_LOG(@"ENTER");
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    return (DVTSourceTextViewHook*)[base initWithFrame_:rect];
}
- (id)initWithCoder:(NSCoder*)coder{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    id obj =  (DVTSourceTextViewHook*)[base initWithCoder_:coder];
    if( nil != obj ){
        [XVim.instance.options addObserver:obj forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.options addObserver:obj forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.searcher addObserver:obj forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    return obj;
}
#endif

// This pragma is for suppressing warning that the dealloc method does not call [super dealloc]. ([base dealloc_] calls [super dealloc] so we do not need it)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
- (void)dealloc{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    @try{
        [XVim.instance.options removeObserver:self forKeyPath:@"hlsearch"];
        [XVim.instance.options removeObserver:self forKeyPath:@"ignorecase"]; 
        [XVim.instance.searcher removeObserver:self forKeyPath:@"lastSearchString"];
    }
    @catch (NSException* exception){
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    [base dealloc_];
    return;
}
#pragma GCC diagnostic pop

- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
    [(DVTSourceTextView*)self setSelectedRanges_:ranges affinity:affinity stillSelecting:flag];
    [(NSTextView*)self xvim_syncStateFromView];
}

-  (void)keyDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"Event:%@, XVimNotation:%@", theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        if( nil == window ){
            [base keyDown_:theEvent];
            return;
        }
        
        if( [window handleKeyEvent:theEvent] ){
            [base updateInsertionPointStateAndRestartTimer:YES];
            return;
        }
        // Call Original keyDown:
        [base keyDown_:theEvent];
        return;
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

-  (void)mouseDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"Event:%@", theEvent.description);
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        [base mouseDown_:theEvent];
        // When mouse down, NSTextView ( base in this case) takes the control of event loop internally
        // and the method call above does not return immidiately and block until mouse up. mouseDragged: method is called from inside it but
        // it never calls mouseUp: event. After mouseUp event is handled internally it returns the control.
        // So the code here is executed AFTER mouseUp event is handled.
        // At this point NSTextView changes its selectedRange so we usually have to sync XVim state.
        XVimWindow* window = [base xvimWindow];
        [window mouseDown:theEvent];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

- (void)drawRect:(NSRect)dirtyRect{
    @try{
        NSTextView* view = (NSTextView*)self;
        
        if( XVim.instance.options.hlsearch ){
            XVimMotion* lastSearch = [XVim.instance.searcher motionForRepeatSearch];
            if( nil != lastSearch.regex ){
                [view xvim_updateFoundRanges:lastSearch.regex withOption:lastSearch.option];
            }
        }else{
            [view xvim_clearHighlightText];
        }
       
        
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        [base drawRect_:dirtyRect];
        if( base.selectionMode != XVIM_VISUAL_NONE ){
            // NSTextView does not draw insertion point when selecting text. We have to draw insertion point by ourselves.
            NSUInteger glyphIndex = [base insertionPoint];
            NSRect glyphRect = [base xvim_boundingRectForGlyphIndex:glyphIndex];
            [[[base insertionPointColor] colorWithAlphaComponent:0.5] set];
            NSRectFillUsingOperation( glyphRect, NSCompositeSourceOver);
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
         XVimWindow* window = [base xvimWindow];
        
        // We do not call original _darawInsertionPointRect here
        // Because it uses NSRectFill to draw the caret which overrides the character entirely.
        // We want some tranceparency for the caret.
        
        // [base _drawInsertionPointInRect_:glyphRect color:aColor];
        
        // Call our drawing method
        [window drawInsertionPointInRect:aRect color:aColor];
        
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    // Call super class first.
    [base drawInsertionPointInRect_:rect color:color turnedOn:flag];
    // Then tell the view to redraw to clear a caret.
    if( !flag ){
        [base setNeedsDisplay:YES];
    }
}

- (void)didChangeText{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base setNeedsUpdateFoundRanges:YES];
    [base didChangeText_];
}

- (void)viewDidMoveToSuperview {
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        [base viewDidMoveToSuperview_];
        
        // Hide scroll bars according to options
        XVimOptions *options = [[XVim instance] options];
        NSString *guioptions = options.guioptions;
        NSScrollView * scrollView = [base enclosingScrollView];
        [scrollView setPostsBoundsChangedNotifications:YES];
        if ([guioptions rangeOfString:@"r"].location == NSNotFound) {
            [scrollView addObserver:self
                         forKeyPath:@"hasVerticalScroller"
                            options:NSKeyValueObservingOptionNew
                            context:nil];
            [scrollView setHasVerticalScroller:NO];
        }
        if ([guioptions rangeOfString:@"b"].location == NSNotFound) {
            [scrollView addObserver:self
                         forKeyPath:@"hasHorizontalScroller"
                            options:NSKeyValueObservingOptionNew
                            context:nil];
            [scrollView setHasHorizontalScroller:NO];
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context {
	if ([keyPath isEqualToString:@"hasVerticalScroller"]) {
		NSScrollView *scrollView = object;
		if ([scrollView hasVerticalScroller]) {
			[scrollView setHasVerticalScroller:NO];
		}
	}else  if ([keyPath isEqualToString:@"hasHorizontalScroller"]) {
		NSScrollView *scrollView = object;
		if ([scrollView hasHorizontalScroller]) {
			[scrollView setHasHorizontalScroller:NO];
		}
	}else if([keyPath isEqualToString:@"ignorecase"] || [keyPath isEqualToString:@"hlsearch"] || [keyPath isEqualToString:@"lastSearchString"]){
        NSTextView* view = (NSTextView*)self;
        [view setNeedsUpdateFoundRanges:YES];
        [view setNeedsDisplayInRect:[view visibleRect] avoidAdditionalLayout:YES];
    }
}

@end

