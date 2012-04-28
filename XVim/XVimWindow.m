//
//  XVimBuffer.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindow.h"
#import "XVim.h"
#import "XVimNormalEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "DVTSourceTextView.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"
#import "IDEWorkspaceController.h"
#import "IDEEditorArea.h"
#import "IDEEditorModeViewController.h"
#import "XVimSourceTextView.h"

@interface XVimWindow() {
	XVimEvaluator* _currentEvaluator;
	XVimKeymapContext* _keymapContext;
	NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
	BOOL _handlingMouseEvent;
}
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister;
- (void)setArgumentString:(NSString*)string;
@end

@implementation XVimWindow
@synthesize tag = _tag;
@synthesize commandLine = _commandLine;
@synthesize sourceView = _sourceView;

- (id) initWithFrame:(NSRect)frameRect{
    if (self = [super initWithFrame:frameRect]) {
        _tag = XVIM_TAG;
		[self setEvaluator:[[XVimNormalEvaluator alloc] init]];
        _localMarks = [[NSMutableDictionary alloc] init];
		_keymapContext = [[XVimKeymapContext alloc] init];
	}
	return self;
}

- (void)setEvaluator:(XVimEvaluator*)evaluator 
{
	if (!evaluator) {
		evaluator = [[XVimNormalEvaluator alloc] init];
	}
		
	if (evaluator != _currentEvaluator)
	{
		if (_currentEvaluator) {
			[_currentEvaluator endHandlerInWindow:self];
		}
		
		_currentEvaluator = evaluator;
		[evaluator becameHandlerInWindow:self];
		
		[_keymapContext clear];
		
		[self setModeString:[evaluator modeString]];
		[self setArgumentString:[evaluator argumentDisplayString]];
		[[self sourceView] updateInsertionPointStateAndRestartTimer:YES];
	}
}

- (XVimEvaluator*)currentEvaluator{
    return _currentEvaluator;
}

- (NSMutableDictionary *)getLocalMarks{
    return _localMarks;
}

- (NSString*)sourceText{
    return [[self sourceView] string];
}

- (NSRange)selectedRange{
    if( [self sourceView] == nil ){
        return NSMakeRange(0, 0);
    }else{
        return [[self sourceView] selectedRange];
    }
}

- (NSUInteger)cursorLocation 
{
	return [[self currentEvaluator] insertionPointInWindow:self];
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
	NSMutableArray *keyStrokeOptions = [[NSMutableArray alloc] init];
	XVimKeyStroke* primaryKeyStroke = [XVimKeyStroke keyStrokeOptionsFromEvent:event into:keyStrokeOptions];
	XVimKeymap* keymap = [_currentEvaluator selectKeymapWithProvider:[XVim instance]];
	
	NSArray *keystrokes = [keymap lookupKeyStrokeFromOptions:keyStrokeOptions 
												 withPrimary:primaryKeyStroke
												 withContext:_keymapContext];
	if (keystrokes)
	{
		for (XVimKeyStroke *keyStroke in keystrokes)
		{
			[self handleKeyStroke:keyStroke];
		}
	}
	
	NSString* argString = [_keymapContext toString];
	if ([argString length] == 0)
	{
		argString = [_currentEvaluator argumentDisplayString];
	}
    
	[self setArgumentString:argString];
    [self.commandLine setNeedsDisplay:YES];
    return YES;
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke {
    [self clearErrorMessage];
    XVim *xvim = [XVim instance];
	XVimEvaluator* nextEvaluator = [_currentEvaluator eval:keyStroke inWindow:self];
	[self recordEvent:keyStroke intoRegister:xvim.recordingRegister];
	[self recordEvent:keyStroke intoRegister:xvim.repeatRegister];
	[self setEvaluator:nextEvaluator];
}

- (void)handleTextInsertion:(NSString*)text {
	[[self sourceView] insertText:text];
}

- (void)setModeString:(NSString*)string
{
	XVimCommandLine *commandLine = self.commandLine;
	[commandLine setModeString:string];
}

- (void)setArgumentString:(NSString*)string
{
    // Where should we put arugment string? command line? or status line?
}

- (void)setStaticString:(NSString*)string
{
	XVimCommandLine *commandLine = self.commandLine;
	[commandLine setStaticString:string];
}

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell {
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:message];
    if (ringBell) {
        [[XVim instance] ringBell];
    }
    return;
}

- (void)clearErrorMessage
{
	XVimCommandLine *commandLine = self.commandLine;
    [commandLine errorMessage:@""];
}

- (XVimCommandField*)commandField 
{
	XVimCommandLine *commandLine = self.commandLine;
	return [commandLine commandField];
}

- (void)commandFieldLostFocus:(XVimCommandField*)commandField
{
	[self setEvaluator:nil];
}

- (void)recordIntoRegister:(XVimRegister*)xregister{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister == nil){
        xvim.recordingRegister = xregister;
        [self setStaticString:@"recording"];
        // when you record into a register you clear out any previous recording
        // unless it was capitalized
        [xvim.recordingRegister clear];
    }else{        
        [xvim ringBell];
    }
}

- (void)stopRecordingRegister:(XVimRegister*)xregister{
    XVim *xvim = [XVim instance];
    if (xvim.recordingRegister == nil){
        [xvim ringBell];
    }else{
        xvim.recordingRegister = nil;
        [self setStaticString: @""];
    }
}

- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister{
    switch ([_currentEvaluator shouldRecordEvent:keyStroke inRegister:xregister]) {
        case REGISTER_APPEND:
            [xregister appendKeyEvent:keyStroke];
            break;
            
        case REGISTER_REPLACE:
            [xregister clear];
            [xregister appendKeyEvent:keyStroke];
            break;
            
        case REGISTER_IGNORE:
        default:
            break;
    }
}

- (void)beginMouseEvent:(NSEvent*)event
{
	_handlingMouseEvent = YES;
}

- (void)endMouseEvent:(NSEvent*)event
{
	_handlingMouseEvent = NO;
	XVimEvaluator* next = [_currentEvaluator handleMouseEvent:event inWindow:self];
	[self setEvaluator:next];
}

- (NSRange)restrictSelectedRange:(NSRange)range
{
	if (_handlingMouseEvent)
	{
		range = [_currentEvaluator restrictSelectedRange:range inWindow:self];
	}
	return range;
}

- (void)drawRect:(NSRect)rect
{
	[_currentEvaluator drawRect:rect inWindow:self];
}

- (BOOL)shouldDrawInsertionPoint
{
	return [_currentEvaluator shouldDrawInsertionPointInWindow:self];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color
{
	[_currentEvaluator drawInsertionPointInRect:rect color:color inWindow:self heightRatio:1];
}

- (void)registerWithScrollView:(NSScrollView*)scrollView
{
	[scrollView addObserver:self
				 forKeyPath:@"hasHorizontalScroller"
					options:NSKeyValueObservingOptionNew
					context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change 
					   context:(void *)context
{
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
