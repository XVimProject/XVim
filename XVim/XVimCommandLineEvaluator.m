//
//  XVimCommandEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Logger.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimKeymapProvider.h"
#import "XVimWindow.h"
#import "XVimCommandField.h"
#import "XVimKeyStroke.h"
#import "XVimHistoryHandler.h"
#import "XVim.h"

@interface XVimCommandLineEvaluator() {
	XVimHistoryHandler *_history;
	NSString *_currentCmd;
	NSString *_firstLetter;
	OnCompleteHandler _onComplete;
	OnKeyPressHandler _onKeyPress;
	NSUInteger _historyNo;
}

- (XVimEvaluator*) Up;
- (XVimEvaluator*) Down;

@end

@implementation XVimCommandLineEvaluator

- (id)initWithWindow:(XVimWindow *)window
		 firstLetter:(NSString*)firstLetter
			 history:(XVimHistoryHandler*)history
		  completion:(OnCompleteHandler)completeHandler
		  onKeyPress:(OnKeyPressHandler)keyPressHandler
{
    if (self = [super initWithWindow:window]){
		_firstLetter = [firstLetter retain];
		_history = [history retain];
		_onComplete = [completeHandler copy];
		_onKeyPress = [keyPressHandler copy];
		_historyNo = 0;
	}
	return self;
}

- (void)dealloc{
    [_firstLetter release];
    [_history release];
    [_onComplete release];
    [_onKeyPress release];
    [super dealloc];
}

- (void)takeFocusFromWindow{
	XVimCommandField *commandField = self.window.commandLine.commandField;
	[commandField setDelegate:self.window];
	[[[[self.window sourceView] view] window] makeFirstResponder:commandField];
}

- (void)relinquishFocusToWindow{
	XVimCommandField *commandField = self.window.commandLine.commandField;
	[commandField absorbFocusEvent];
	[commandField setDelegate:nil];
    [self.window setForcusBackToSourceView];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
	XVimEvaluator* next = self;

	XVimCommandField *commandField = self.window.commandLine.commandField;
	if ([keyStroke instanceResponds:self]) {
		next = [self performSelector:[keyStroke selector]];
	}
	else{
		[commandField handleKeyStroke:keyStroke inWindow:self.window];
		
		// If the user deletes the : (or /?) character, bail
		NSString *text = [commandField string];
		if ([text length] == 0){
			next = nil;
        }
		_historyNo = 0; // Typing always resets history
	}
	
	if (next != self){
		[self relinquishFocusToWindow];
    } else if (_onKeyPress != nil) {
        _onKeyPress([[commandField string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
    }
            
	return next;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
	return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (void)becameHandler{
	[super becameHandler];

	XVimCommandField *commandField = self.window.commandLine.commandField;
    [commandField setString:_firstLetter];
    [commandField moveToEndOfLine:self];
	[self takeFocusFromWindow];
}

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window{
	return nil;
}

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event{
	[self relinquishFocusToWindow];
	return nil;
}

- (void)drawRect:(NSRect)rect{
	[self.parent drawRect:rect];
}

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window{
	return NO;
}

- (float)insertionPointHeightRatio{
    return 0.0;
}

- (NSString*)modeString{
	return [self.parent modeString];
}

- (XVIM_MODE)mode{
	return MODE_CMDLINE;
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other{
	return [super isRelatedTo:other] || other == self.parent;
}

- (XVimEvaluator*)C_p{
    return [self Up];
}

- (XVimEvaluator*)C_n{
    return [self Down];
}

- (XVimEvaluator*)CR{
	XVimCommandField *commandField = self.window.commandLine.commandField;
	NSString *command = [[commandField string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[_history addEntry:command];
    [[XVim instance] writeToLogfile:[@"ExCommand " stringByAppendingFormat:@"%@\n", command]];
	return _onComplete(command);
}

- (XVimEvaluator*)ESC{
    XVimSourceView *sourceView = [self sourceView];
    [sourceView scrollTo:[self.window insertionPoint]];
	return nil;
}

- (XVimEvaluator*)C_LSQUAREBRACKET{
    return [self ESC];
}

- (XVimEvaluator*)C_c{
  return [self ESC];
}

- (XVimEvaluator*)Up{
	XVimCommandField *commandField = self.window.commandLine.commandField;
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

- (XVimEvaluator*)Down{
	XVimCommandField *commandField = self.window.commandLine.commandField;
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