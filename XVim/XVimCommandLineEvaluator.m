//
//  XVimCommandEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimCommandLineEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimKeymapProvider.h"
#import "XVimWindow.h"
#import "DVTSourceTextView.h"
#import "XVimCommandField.h"
#import "XVimKeyStroke.h"
#import "XVimHistoryHandler.h"
#import "XVim.h"

@interface XVimCommandLineEvaluator() {
	XVimEvaluator *_parent;
	XVimHistoryHandler *_history;
	NSString *_currentCmd;
	NSString *_firstLetter;
	OnCompleteHandler _onComplete;
	OnKeyPressHandler _onKeyPress;
	NSUInteger _historyNo;
}
@end

@implementation XVimCommandLineEvaluator

- (id)initWithParent:(XVimEvaluator*)parent 
		 firstLetter:(NSString*)firstLetter 
			 history:(XVimHistoryHandler*)history
		  onComplete:(OnCompleteHandler)completeHandler
		  onKeyPress:(OnKeyPressHandler)keyPressHandler
{
	if (self = [super init])
	{
		_parent = parent;
		_firstLetter = firstLetter;
		_history = history;
		_onComplete = [completeHandler copy];
		_onKeyPress = [keyPressHandler copy];
		_historyNo = 0;
	}
	return self;
}

- (void)takeFocusFromWindow:(XVimWindow*)window
{
	XVimCommandField *commandField = [window commandField];
	[[window window] makeFirstResponder:commandField];
}

- (void)relinquishFocusToWindow:(XVimWindow*)window
{
	XVimCommandField *commandField = [window commandField];
	[commandField absorbFocusEvent];
	[[window window] makeFirstResponder:[window sourceView]];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window
{
	XVimEvaluator* next = self;
	
	XVimCommandField *commandField = [window commandField];
	if ([keyStroke instanceResponds:self])
	{
		next = [self performSelector:[keyStroke selector] withObject:window];
	}
	else
	{
		[commandField handleKeyStroke:keyStroke inWindow:window];
		
		// If the user deletes the : (or /?) character, bail
		NSString *text = [commandField string];
		if ([text length] == 0)
		{
			next = nil;
        }
		
		_historyNo = 0; // Typing always resets history
	}
	
	if (next != self)
	{
		[self relinquishFocusToWindow:window];
    } else if (_onKeyPress != nil) {
        _onKeyPress([[commandField string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
    }
            
	return next;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister
{
	return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (void)becameHandlerInWindow:(XVimWindow*)window
{
	[super becameHandlerInWindow:window];
	
	XVimCommandField *commandField = [window commandField];
    [commandField setString:_firstLetter];
    [commandField moveToEndOfLine:self];
	[self takeFocusFromWindow:window];
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window
{
	return _parent;
}

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event inWindow:(XVimWindow*)window
{
	[self relinquishFocusToWindow:window];
	return nil;
}

- (NSRange)restrictSelectedRange:(NSRange)range inWindow:(XVimWindow*)window
{
	return [super restrictSelectedRange:range inWindow:window];
}

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window
{
	return [_parent insertionPointInWindow:window];
}

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window
{
	[_parent drawRect:rect inWindow:window];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window
{
	return NO;
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio
{
}

- (NSString*)modeString
{
	return [_parent modeString];
}

- (NSUInteger)numericArg
{
	return 1;
}

- (XVimEvaluator*)CR:(XVimWindow*)window
{
	XVimCommandField *commandField = [window commandField];
	NSString *command = [[commandField string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[_history addEntry:command];
	return _onComplete(command);
}

- (XVimEvaluator*)ESC:(XVimWindow*)window
{
    DVTSourceTextView *sourceView = [window sourceView];
    [sourceView scrollTo:[window cursorLocation]];
	return _parent;
}

- (XVimEvaluator*)Up:(XVimWindow*)window
{
	XVimCommandField *commandField = window.commandField;
	XVim *xvim = [XVim instance];
	
	if (_historyNo == 0) {
		_currentCmd = [[commandField string] copy];
	}
	
	_historyNo++;
	NSString* cmd = [_history entry:_historyNo withPrefix:_currentCmd];
	if( nil == cmd ) {
		[xvim ringBell];
		_historyNo--;
		[commandField moveToEndOfLine:self];
	} else {
		[commandField setString:cmd];
		[commandField moveToEndOfLine:self];
	}
	
	return self;
}

- (XVimEvaluator*)Down:(XVimWindow*)window
{
	XVimCommandField *commandField = window.commandField;
	XVim *xvim = [XVim instance];
	
	if (_historyNo == 0) {
		// Nothing
	} else {
		_historyNo--;
		if( _historyNo == 0 ) {
			[commandField setString:_currentCmd];
			[commandField moveToEndOfLine:self];
		}else{
			NSString* cmd = [_history entry:_historyNo withPrefix:_currentCmd];
			if( nil == cmd ){
				[xvim ringBell];
			}else{
				[commandField setString:cmd];
				[commandField moveToEndOfLine:self];
			}
		}
	}
	
	return self;
}

@end