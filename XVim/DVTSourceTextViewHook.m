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

#import "XVimInsertEvaluator.h"
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

    [self hook:@"setSelectedRanges:affinity:stillSelecting:"];
    [self hook:@"selectAll:"];
    // [self hook:@"cut:"];  // Cut calls delete: after all. Do not need to hook
    // [self hook:@"copy:"];  // Does not change any state. Do not need to hook
    [self hook:@"paste:"];  
    [self hook:@"delete:"];  
    [self hook:@"keyDown:"];
    [self hook:@"mouseDown:"];
    [self hook:@"drawRect:"];
    [self hook:@"_drawInsertionPointInRect:color:"];
    [self hook:@"drawInsertionPointInRect:color:turnedOn:"];
    [self hook:@"didChangeText"];
    [self hook:@"viewDidMoveToSuperview"];
    [self hook:@"shouldChangeTextInRange:replacementString"];
    [self hook:@"observeValueForKeyPath:ofObject:change:context:"];
    [self hook:@"shouldAutoCompleteAtLocation:"];
}

+ (void)unhook{
    // We never unhook these two methods.
    // This is because we always have to control observers for XVimOptions
    // If we unhook these, these may be a memory leak or it leads crash when a removing observer which has not been added as a observer in dealloc method.
    // [self unhook:@"initWithCoder:"];
    // [self unhook:@"initWithFrame:textContainer:"];
    // [self unhook:@"dealloc"]; 
    [self unhook:@"setSelectedRanges:affinity:stillSelecting"];
    [self unhook:@"selectAll:"];
    //[self unhook:@"cut:"]; 
    //[self unhook:@"copy:"]; 
    [self unhook:@"paste:"];  
    [self unhook:@"delete:"];  
    [self unhook:@"keyDown:"];
    [self unhook:@"mouseDown:"];
    [self unhook:@"drawRect:"];
    [self unhook:@"_drawInsertionPointInRect:color:"];
    [self unhook:@"drawInsertionPointInRect:color:turnedOn:"];
    [self unhook:@"didChangeText"];
    [self unhook:@"viewDidMoveToSuperview"];
    [self unhook:@"shouldChangeTextInRange:replacementString"];
    // We do not unhook this too. Since "addObserver" is called in initWithCoder we should keep this hook
    // (Calling observerValueForKeyPath in NSObject results in throwing exception)
    //[self unhook:@"observeValueForKeyPath:ofObject:change:context:"];
    [self unhook:@"shouldAutoCompleteAtLocation:"];
}

#ifdef __XCODE5__

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


- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
    [(DVTSourceTextView*)self setSelectedRanges_:ranges affinity:affinity stillSelecting:flag];
    [(NSTextView*)self xvim_syncStateFromView];
    [(NSTextView*)self setNeedsDisplay:YES];
}

- (void)selectAll:(id)sender{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    [base selectAll_:sender];
    [window syncEvaluatorStack];  
}

- (void)paste:(id)sender{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    [base paste_:sender];
    [window syncEvaluatorStack];  
    
}

- (void)delete:(id)sender{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    [base delete_:sender];
    [window syncEvaluatorStack];  
}

-  (void)keyDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"[%p]Event:%@, XVimNotation:%@", self, theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
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
        
        // TODO: To make it simple we should forward mouse events
        //       to handleKeyStroke as a special key stroke
        //       and the key stroke should be handled by the current evaluator.
        XVimWindow* window = [base xvimWindow];
        [window syncEvaluatorStack];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

NSRect s_lastCaret;
- (void)drawRect:(NSRect)dirtyRect{ 
    TRACE_LOG(@"drawRect");
    @try{
        NSTextView* view = (NSTextView*)self;
        
        NSGraphicsContext* context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
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
        
        // Caret Drawing
        XVimWindow* window = [base xvimWindow];
        if( [base performSelector:@selector(_isLayerBacked)] && ![[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
            // Erase Cursor 
            [[NSBezierPath bezierPathWithRect:[base visibleRect]] setClip];
            [base drawRect_:s_lastCaret];
            if( ![[[XVim instance] options] blinkcursor] ){
                // Only when not blinkcursor, draw caret
                NSUInteger glyphIndex = [base insertionPoint];
                NSRect glyphRect = [base xvim_boundingRectForGlyphIndex:glyphIndex];
                //glyphRect.origin.x -= 1.0f;
                [self _drawInsertionPointInRect:glyphRect color:[base insertionPointColor]];
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
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    TRACE_LOG(@"%f %f %f %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
            // Use original behavior when insert mode.
            return [base _drawInsertionPointInRect_:aRect color:aColor];
        }
        
        NSUInteger glyphIndex = [base insertionPoint];
        NSRect glyphRect = [base xvim_boundingRectForGlyphIndex:glyphIndex];
        s_lastCaret = glyphRect;
        [[NSBezierPath bezierPathWithRect:[base visibleRect]] setClip];
        [window drawInsertionPointInRect:glyphRect color:aColor];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    if( [[[window currentEvaluator] class] isSubclassOfClass:[XVimInsertEvaluator class]]){
        // Use original behavior when insert mode.
        return [base drawInsertionPointInRect_:rect color:color turnedOn:flag];
    }
    
    if( ![base performSelector:@selector(_isLayerBacked)] ){
        if( [[[XVim instance] options] blinkcursor] ){
            [self drawRect:s_lastCaret];
            if( flag ) {
                [self _drawInsertionPointInRect:rect color:color];
            }
        }else{
            [self drawRect:s_lastCaret];
            [self _drawInsertionPointInRect:rect color:color];
        }
    }
    else{
        if( [[[XVim instance] options] blinkcursor] ){
            [self drawRect:s_lastCaret];
            [self _drawInsertionPointInRect:rect color:color];
        }
    }
    return;
}
- (void)didChangeText{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base setNeedsUpdateFoundRanges:YES];
    [base didChangeText_];
}

- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)location{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    return [window shouldAutoCompleteAtLocation:(unsigned long long)location];
}
static NSString* XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW = @"XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW";

- (void)viewDidMoveToSuperview {
    @try{
        if ( ![ self boolForName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW ] ) {
            [XVim.instance.options addObserver:self forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [XVim.instance.options addObserver:self forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            [XVim.instance.searcher addObserver:self forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
            __unsafe_unretained DVTSourceTextView* weakSelf = (DVTSourceTextView*)self;
            [ self xvim_performOnDealloc:^{
                DVTSourceTextView *base = (DVTSourceTextView*)weakSelf;
                @try{
                    [XVim.instance.options removeObserver:base forKeyPath:@"hlsearch"];
                    [XVim.instance.options removeObserver:base forKeyPath:@"ignorecase"];
                    [XVim.instance.searcher removeObserver:base forKeyPath:@"lastSearchString"];
                }
                @catch (NSException* exception){
                    ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
                    [Logger logStackTrace:exception];
                }
            }];
            [ self setBool:YES forName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTVIEW ];
        }
        
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        [base viewDidMoveToSuperview_];
        
        // Hide scroll bars according to options
        NSScrollView * scrollView = [base enclosingScrollView];
        [scrollView setPostsBoundsChangedNotifications:YES];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context {
	if([keyPath isEqualToString:@"ignorecase"] || [keyPath isEqualToString:@"hlsearch"] || [keyPath isEqualToString:@"lastSearchString"]){
        NSTextView* view = (NSTextView*)self;
        [view setNeedsUpdateFoundRanges:YES];
        [view setNeedsDisplayInRect:[view visibleRect] avoidAdditionalLayout:YES];
    }
}

@end

