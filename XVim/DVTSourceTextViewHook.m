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

+ (void)hook:(NSString*)method{
    NSString* cls = @"DVTSourceTextView";
    NSString* thisCls = NSStringFromClass([self class]);
    [Hooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void)unhook:(NSString*)method{
    NSString* cls = @"DVTSourceTextView";
    [Hooker unhookClass:cls method:method];
}

+ (void)hook
{
    [self hook:@"becomeFirstResponder"];
    [self hook:@"keyDown:"];
    [self hook:@"mouseDown:"];
    [self hook:@"mouseDragged:"];
    [self hook:@"drawRect:"];
    [self hook:@"performKeyEquivalent:"];
    [self hook:@"shouldDrawInsertionPoint"];
    [self hook:@"drawInsertionPointInRect:color:turnedOn:"];
    [self hook:@"_drawInsertionPointInRect:color:"];
    [self hook:@"viewDidMoveToSuperview"];
    [self hook:@"observeValueForKeyPath:ofObject:change:context:"];
}

+ (void)unhook
{
    [self unhook:@"becomeFirstResponder"];
    [self unhook:@"keyDown:"];
    [self unhook:@"mouseDown:"];
    [self unhook:@"mouseDragged:"];
    [self unhook:@"drawRect:"];
    [self unhook:@"performKeyEquivalent:"];
    [self unhook:@"shouldDrawInsertionPoint"];
    [self unhook:@"drawInsertionPointInRect:color:turnedOn:"];
    [self unhook:@"_drawInsertionPointInRect:color:"];
    [self unhook:@"viewDidMoveToSuperview"];
    [self unhook:@"observeValueForKeyPath:ofObject:change:context:"];
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
    // Since XVimWindow manages multiple DVTSourceTextView
    // we have to switch current text view when the first responder changed.
    DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [base xvimWindow];
    BOOL b = [base becomeFirstResponder_];
    @try{
        if (b) {
            DEBUG_LOG(@"DVTSourceTextView:%p became first responder", self);
            window.sourceView = [[[XVimSourceView alloc] initWithView:base] autorelease];
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

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{	
	if ([keyPath isEqualToString:@"hasVerticalScroller"])
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasVerticalScroller]) {
			[scrollView setHasVerticalScroller:NO];
		}
	}
	if ([keyPath isEqualToString:@"hasHorizontalScroller"])
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasHorizontalScroller]) {
			[scrollView setHasHorizontalScroller:NO];
		}
	}
}

@end

