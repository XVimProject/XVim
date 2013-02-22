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
    [self hook:@"setSelectedRange:"];
    [self hook:@"setSelectedRange:affinity:stillSelecting:"];
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
    [self unhook:@"setSelectedRange:"];
    [self unhook:@"setSelectedRange:affinity:stillSelecting:"];
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
    DEBUG_LOG(@"Obj:%p keyDown : keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self,[theEvent keyCode], [theEvent characters], [theEvent charactersIgnoringModifiers], charcode);
    
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
            window.sourceView = [[[XVimSourceView alloc] initWithView:base] autorelease];
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
	if ([keyPath isEqualToString:@"hasVerticalScroller"])
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasVerticalScroller])
		{
			[scrollView setHasVerticalScroller:NO];
		}
	}
	if ([keyPath isEqualToString:@"hasHorizontalScroller"])
	{
		NSScrollView *scrollView = object;
		if ([scrollView hasHorizontalScroller])
		{
			[scrollView setHasHorizontalScroller:NO];
		}
	}
}

@end

