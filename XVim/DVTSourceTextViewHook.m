//
//  DVTSourceTextView.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DVTSourceTextViewHook.h"
#import "XVimEvaluator.h"
#import "XVimWindow.h"
#import "Hooker.h"
#import "Logger.h"
#import "XVimSourceView.h"
#import "DVTKit.h"
#import "XVimSourceView.h"
#import "XVimStatusLine.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "IDEKit.h"
#import "IDEEditorArea+XVim.h"
#import "DVTSourceTextView+XVim.h"
#import "NSEvent+VimHelper.h"

@implementation DVTSourceTextViewHook

+ (void)hook
{
    Class c = NSClassFromString(@"DVTSourceTextView");
    
    // Hook setSelectedRange:affinity:stillSelecting:
    [Hooker hookMethod:@selector(setSelectedRange:affinity:stillSelecting:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(setSelectedRange:affinity:stillSelecting:) ) keepingOriginalWith:@selector(setSelectedRange_:affinity:stillSelecting:)];
    
    // Hook becomeFirstResponder  
    [Hooker hookMethod:@selector(becomeFirstResponder) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(becomeFirstResponder) ) keepingOriginalWith:@selector(becomeFirstResponder_)];
    
    // Hook keyDown:
    [Hooker hookMethod:@selector(keyDown:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(keyDown:) ) keepingOriginalWith:@selector(keyDown_:)];   
    
    // Hook mouseDown:
    [Hooker hookMethod:@selector(mouseDown:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(mouseDown:) ) keepingOriginalWith:@selector(mouseDown_:)];
	
    // Hook mouseUp:
    [Hooker hookMethod:@selector(mouseUp:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(mouseUp:) ) keepingOriginalWith:@selector(mouseDragged_:)];    
	
    // Hook mouseDragged:
    [Hooker hookMethod:@selector(mouseDragged:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(mouseDragged:) ) keepingOriginalWith:@selector(mouseUp_:)];    
	
    // Hook drawRect:
    [Hooker hookMethod:@selector(drawRect:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(drawRect:)) keepingOriginalWith:@selector(drawRect_:)];
    
    // Hook performKeyEquivalent:
    [Hooker hookMethod:@selector(performKeyEquivalent:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(performKeyEquivalent:)) keepingOriginalWith:@selector(performKeyEquivalent_:)];
    
    // Hook shouldDrawInsertionPoint for Drawing Caret
    [Hooker hookMethod:@selector(shouldDrawInsertionPoint) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(shouldDrawInsertionPoint)) keepingOriginalWith:@selector(shouldDrawInsertionPoint_)];
    
    // Hook drawInsertionPointInRect for Drawing Caret
    [Hooker hookMethod:@selector(drawInsertionPointInRect:color:turnedOn:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(drawInsertionPointInRect:color:turnedOn:)) keepingOriginalWith:@selector(drawInsertionPointInRect_:color:turnedOn:)];
    
    // Hook _drawInsertionPointInRect for Drawing Caret       
    [Hooker hookMethod:@selector(_drawInsertionPointInRect:color:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(_drawInsertionPointInRect:color:)) keepingOriginalWith:@selector(_drawInsertionPointInRect_:color:)];
	
    [Hooker hookMethod:@selector(viewDidMoveToSuperview) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidMoveToSuperview) ) keepingOriginalWith:@selector(viewDidMoveToSuperview_)];
    [Hooker hookMethod:@selector(observeValueForKeyPath:ofObject:change:context:) 
			   ofClass:c withMethod:class_getInstanceMethod([self class], @selector(observeValueForKeyPath:ofObject:change:context:) ) 
   keepingOriginalWith:@selector(observeValueForKeyPath_:ofObject:change:context:)];
}

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        if (window){
            charRange = [window restrictSelectedRange:charRange];
        }
        [base setSelectedRange_:charRange affinity:affinity stillSelecting:flag];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

-  (void)keyDown:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"Event:%@", theEvent.description);
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        if( nil == window ){
            [base keyDown_:theEvent];
            return;
        }
        
        unichar charcode = [theEvent unmodifiedKeyCode];
        DEBUG_LOG(@"DVTSourceTextView:%p keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
        
        if( [window handleKeyEvent:theEvent] ){
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
        XVimWindow* window = [base xvimWindow];
        [window mouseDown:theEvent];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

-  (void)mouseUp:(NSEvent *)theEvent{
    @try{
        TRACE_LOG(@"Event:%@", theEvent.description);
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        [window mouseUp:theEvent];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
	return;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    @try{
        TRACE_LOG(@"Event:%@", theEvent.description);
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        [window mouseDragged:theEvent];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

- (void)drawRect:(NSRect)dirtyRect{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        [base drawRect_:dirtyRect];
        [window drawRect:dirtyRect];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return;
}

- (BOOL) performKeyEquivalent:(NSEvent *)theEvent{
    TRACE_LOG(@"Event:%@", theEvent.description);
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    @try{
        METHOD_TRACE_LOG();
        unichar charcode = [theEvent unmodifiedKeyCode];
        TRACE_LOG(@"keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ ASCII:%d", [theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
        if( [[base window] firstResponder] != base){
            return NO;
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return [base performKeyEquivalent_:theEvent];
}

- (BOOL)shouldDrawInsertionPoint{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        return [window shouldDrawInsertionPoint];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return YES;
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        [window drawInsertionPointInRect:aRect color:aColor];
        [base setNeedsDisplayInRect:[base visibleRect] avoidAdditionalLayout:NO];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        XVimWindow* window = [base xvimWindow];
        if (flag) {
            [window drawInsertionPointInRect:rect color:color];
        }
        [base setNeedsDisplayInRect:[base visibleRect] avoidAdditionalLayout:NO];
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (BOOL)becomeFirstResponder{
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    BOOL b = [base becomeFirstResponder_];
    @try{
        if (b) {
            DEBUG_LOG(@"DVTSourceTextView:%p became first responder", self);
            window.sourceView = [[XVimSourceView alloc] initWithView:base];
            window.sourceView.delegate = [XVim instance];
        }
    }@catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    return b;
}

- (void)viewDidMoveToSuperview {
    @try{
        DVTSourceTextView *base = (DVTSourceTextView*)self;
        [base viewDidMoveToSuperview_];
        
        // Hide scroll bars according to options
        XVimOptions *options = [[XVim instance] options];
        NSString *guioptions = options.guioptions;
        NSScrollView * scrollView = [base enclosingScrollView];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (keyPath == @"hasVerticalScroller") {
		NSScrollView *scrollView = object;
		if ([scrollView hasVerticalScroller]) {
			[scrollView setHasVerticalScroller:NO];
		}
	}
	if (keyPath == @"hasHorizontalScroller") {
		NSScrollView *scrollView = object;
		if ([scrollView hasHorizontalScroller]) {
			[scrollView setHasHorizontalScroller:NO];
		}
	}
}

@end

