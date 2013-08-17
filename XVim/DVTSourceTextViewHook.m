//
//  DVTSourceTextView.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
    [self hook:@"setSelectedRanges:affinity:stillSelecting:"];
    [self hook:@"becomeFirstResponder"];
    [self hook:@"keyDown:"];
    [self hook:@"mouseDown:"];
    [self hook:@"mouseDragged:"];
    [self hook:@"drawRect:"];
    [self hook:@"shouldDrawInsertionPoint"];
    [self hook:@"_drawInsertionPointInRect:color:"];
    [self hook:@"viewDidMoveToSuperview"];
    [self hook:@"observeValueForKeyPath:ofObject:change:context:"];
}

+ (void)unhook{
    [self unhook:@"setSelectedRanges:affinity:stillSelecting"];
    [self unhook:@"becomeFirstResponder"];
    [self unhook:@"keyDown:"];
    [self unhook:@"mouseDown:"];
    [self unhook:@"mouseDragged:"];
    [self unhook:@"drawRect:"];
    [self unhook:@"shouldDrawInsertionPoint"];
    [self unhook:@"_drawInsertionPointInRect:color:"];
    [self unhook:@"viewDidMoveToSuperview"];
    [self unhook:@"observeValueForKeyPath:ofObject:change:context:"];
}

- (void)setSelectedRanges:(NSArray *)ranges affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
    for( NSValue* v in ranges ){
        TRACE_LOG(@"Array:%d   affinity:%d   stillSelectiong:%@", ranges.count, affinity, flag?@"YES":@"NO");
        TRACE_LOG(@"Range:(%d,%d)", v.rangeValue.location, v.rangeValue.length);
    }
    [(DVTSourceTextView*)self setSelectedRanges_:ranges affinity:affinity stillSelecting:flag];
    [(NSTextView*)self xvim_syncStateFromView];
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
        
        unichar charcode __unused = [theEvent unmodifiedKeyCode];
        DEBUG_LOG(@"Obj:%p keyDown : keyCode:%d firstCharacter:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [[theEvent characters] characterAtIndex:0], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
        
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
        
        // We do not call original _darawInsertionPointRect here
        // Because it uses NSRectFill to draw the caret which overrides the character entirely.
        // We want some tranceparency for the caret.
        
        // [base _drawInsertionPointInRect_:glyphRect color:aColor];
        
        // Call our drawing method
        NSRect rect = [window drawInsertionPointInRect:aRect color:aColor];
        
        // Change NSTextView internal variable named "_insertionPointRect"
        // NSTextView has a instance of NSTextViewIvars class.
        // NSTextViewIvars class has various varibles to keep private variables for NSTextView
        // _insertionPointRect in the class is used when clearing the caret we draw.
        // We are not writing any code to clear caret but NSTextView does it automatically if we set
        // this internal varible properly.
        id nsTextViewIvars;
        object_getInstanceVariable(base, "_ivars", (void**)&nsTextViewIvars);
        [nsTextViewIvars setValue:[NSValue valueWithRect:rect] forKey:@"_insertionPointRect"];
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
            TRACE_LOG(@"DVTSourceTextView:%p became first responder", self);
            window.sourceView = (NSTextView*)base;
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

