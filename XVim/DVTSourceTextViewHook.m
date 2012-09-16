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
    
    // Hook setSelectedRange:
    [Hooker hookMethod:@selector(setSelectedRange:) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(setSelectedRange:) ) keepingOriginalWith:@selector(setSelectedRange_:)];
    
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

- (void)setSelectedRange:(NSRange)charRange {
    // Call original method
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base setSelectedRange_:charRange];
    return;
}

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
    if (window) 
	{
		charRange = [window restrictSelectedRange:charRange];
	}
    [base setSelectedRange_:charRange affinity:affinity stillSelecting:flag];
    return;
}

-  (void)keyDown:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
    if( nil == window ){
        [base keyDown_:theEvent];
        return;
    }
   
    unichar charcode = [theEvent unmodifiedKeyCode];
    [Logger logWithLevel:LogDebug format:@"Obj:%p keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode];
    
    if( [window handleKeyEvent:theEvent] ){
        return;
    }
    // Call Original keyDown:
    [base keyDown_:theEvent];
    return;
}

-  (void)mouseDown:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
	if (window)
	{
		[window beginMouseEvent:theEvent];
	}
   
	[base mouseDown_:theEvent]; // this loops until it gets a mouse up

    if (window)
	{
		[window endMouseEvent:theEvent];
    }
	
	return;
}

-  (void)mouseUp:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base mouseUp_:theEvent];
	return;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base mouseDragged_:theEvent];
    return;
}

- (void)drawRect:(NSRect)dirtyRect{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
    [base drawRect_:dirtyRect];
	[window drawRect:dirtyRect];
}

- (BOOL) performKeyEquivalent:(NSEvent *)theEvent{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    
    METHOD_TRACE_LOG();
    unichar charcode = [theEvent unmodifiedKeyCode];
    TRACE_LOG(@"keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ ASCII:%d", [theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
    if( [[base window] firstResponder] != base){
        return NO;
    }
    
    return [base performKeyEquivalent_:theEvent];
}

- (BOOL)shouldDrawInsertionPoint{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
	return [window shouldDrawInsertionPoint];
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
	[window drawInsertionPointInRect:aRect color:aColor];
	[base setNeedsDisplayInRect:[base visibleRect] avoidAdditionalLayout:NO];
}

// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];
	if (flag)
	{
		[window drawInsertionPointInRect:rect color:color];
	}
	[base setNeedsDisplayInRect:[base visibleRect] avoidAdditionalLayout:NO];
}

- (BOOL)becomeFirstResponder{
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    XVimWindow* window = [XVimWindow associateOf:base];

    BOOL b = [base becomeFirstResponder_];
    if (b) {
        if (!window.sourceView)
            window.sourceView = [[XVimSourceView alloc] initWithView:base];
        window.commandLine = [base commandLine];
    }
    return b;
}

- (void)viewDidMoveToSuperview {
	DVTSourceTextView *base = (DVTSourceTextView*)self;
    [base viewDidMoveToSuperview_];
	
    // Create XVimWindow object
    XVimWindow* window = [XVimWindow associateOf:base];
    if( nil == window ){
        window = [[[XVimWindow alloc] init] autorelease];
		[window associateWith:base];
    }
	
	// Hide scroll bars according to options
	XVimOptions *options = [[XVim instance] options];
	NSString *guioptions = options.guioptions;
	NSScrollView * scrollView = [base enclosingScrollView];
	if ([guioptions rangeOfString:@"r"].location == NSNotFound)
	{
		[scrollView addObserver:self
					 forKeyPath:@"hasVerticalScroller"
						options:NSKeyValueObservingOptionNew
						context:nil];
		[scrollView setHasVerticalScroller:NO];
	}
	if ([guioptions rangeOfString:@"b"].location == NSNotFound)
	{
		[scrollView addObserver:self
					 forKeyPath:@"hasHorizontalScroller"
						options:NSKeyValueObservingOptionNew
						context:nil];
		[scrollView setHasHorizontalScroller:NO];
	}

}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{	
	if (keyPath == @"hasVerticalScroller")
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasVerticalScroller])
		{
			[scrollView setHasVerticalScroller:NO];
		}
	}
	if (keyPath == @"hasHorizontalScroller")
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasHorizontalScroller])
		{
			[scrollView setHasHorizontalScroller:NO];
		}
	}
}

@end

