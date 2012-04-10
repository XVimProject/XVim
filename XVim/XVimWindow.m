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
#import "XVimExCommand.h"
#import "XVimSearch.h"
#import "XVimOptions.h"
#import "DVTSourceTextView.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"

@interface XVimWindow() {
	XVimEvaluator* _currentEvaluator;
	NSMutableDictionary* _localMarks; // key = single letter mark name. value = NSRange (wrapped in a NSValue) for mark location
}
- (void)recordEvent:(XVimKeyStroke*)keyStroke intoRegister:(XVimRegister*)xregister;
@end

@implementation XVimWindow
@synthesize tag = _tag;
@synthesize cmdLine = _cmdLine;
@synthesize sourceView = _sourceView;
@synthesize mode = _mode;
@synthesize recordingRegister = _recordingRegister;
@synthesize handlingMouseClick = _handlingMouseClick;
@synthesize staticMessage = _staticMessage;
@synthesize errorMessage = _errorMessage;

- (id) initWithFrame:(NSRect)frameRect{
    if (self = [super initWithFrame:frameRect]) {
        _mode = MODE_NORMAL;
        _tag = XVIM_TAG;
        _currentEvaluator = [[XVimNormalEvaluator alloc] init];
        [_currentEvaluator becameHandlerInWindow:self];
        _localMarks = [[NSMutableDictionary alloc] init];
        
		_recordingRegister = nil;
        _handlingMouseClick = NO;
	}
	return self;
}

- (void)setMode:(NSInteger)mode{
    _mode = mode;
}

- (NSString*)modeName{
    return MODE_STRINGS[self.mode];
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
    return [[self sourceView] selectedRange];
}

- (NSUInteger)cursorLocation 
{
	return [[self currentEvaluator] insertionPointInWindow:self];
}

- (BOOL)handleKeyEvent:(NSEvent*)event{
	NSMutableArray *keyStrokeOptions = [[NSMutableArray alloc] init];
	XVimKeyStroke* primaryKeyStroke = [XVimKeyStroke keyStrokeOptionsFromEvent:event into:keyStrokeOptions];
	XVimKeymap* keymap = [_currentEvaluator selectKeymapWithProvider:[XVim instance]];
	NSArray *keystrokes = [keymap lookupKeyStrokeFromOptions:keyStrokeOptions withPrimary:primaryKeyStroke];
	
	for (XVimKeyStroke *keyStroke in keystrokes)
	{
		[self handleKeyStroke:keyStroke];
	}
    
    [self.cmdLine setNeedsDisplay:YES];
    return YES;
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke {
    [self setErrorMessage:@""];
	XVimEvaluator* nextEvaluator = [_currentEvaluator eval:keyStroke inWindow:self];
	[self recordEvent:keyStroke intoRegister:_recordingRegister];
	[self recordEvent:keyStroke intoRegister:[[XVim instance] findRegister:@"repeat"]];
	if( nil == nextEvaluator ){
		nextEvaluator = [[XVimNormalEvaluator alloc] init];
	}
	
	if( _currentEvaluator != nextEvaluator ){
		[_currentEvaluator release];
		_currentEvaluator = nextEvaluator;
		
		XVIM_MODE newMode = [_currentEvaluator becameHandlerInWindow:self];
		if (self.mode != MODE_CMDLINE){
			// Special case for cmdline mode. I don't like this, but
			// don't have time to refactor cmdline mode.
			self.mode = newMode;
		}
		
		[[self sourceView] updateInsertionPointStateAndRestartTimer:YES];
	}
}

- (void)handleTextInsertion:(NSString*)text {
	[[self sourceView] insertText:text];
}

- (void)commandModeWithFirstLetter:(NSString*)first{
    self.mode = MODE_CMDLINE;
    [self.cmdLine setFocusOnCommandWithFirstLetter:first];
}

// Should move to separated file.
- (BOOL)commandFixed:(NSString*)command{
    NSString* c = [command stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    DVTSourceTextView* srcView = (DVTSourceTextView*)[self superview]; // DVTTextSourceView
    TRACE_LOG(@"command : %@", c);
    if( [c length] == 0 ){
        // Something wrong
        ERROR_LOG(@"command string empty");
    }
    else if( [c characterAtIndex:0] == ':' ){
		XVimExCommand *excmd = [[XVim instance] excmd];
        [excmd executeCommand:c inWindow:self];
    }
    else if ([c characterAtIndex:0] == '/' || [c characterAtIndex:0] == '?') 
	{
		XVimSearch *searcher = [[XVim instance] searcher];
        NSRange found = [searcher executeSearch:c from:[self cursorLocation] inWindow:self];
        //Move cursor and show the found string
        if( found.location != NSNotFound ){
            [srcView setSelectedRange:NSMakeRange(found.location, 0)];
			[srcView scrollTo:[self cursorLocation]];
            [srcView showFindIndicatorForRange:found];
        }else{
            [self errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",searcher.lastSearchString] ringBell:TRUE];
        }
    }
	
    [[self window] makeFirstResponder:srcView]; // Since XVim is a subview of DVTSourceTextView;
    self.mode = MODE_NORMAL;
    return YES;
}

- (BOOL)commandCanceled{
    self.mode = MODE_NORMAL;
    [[self window] makeFirstResponder:[self superview]]; // Since XVim is a subview of DVTSourceTextView;
    return YES;
}

- (void)ringBell {
	XVimOptions *options = [[XVim instance] options];
    if (options.errorbells) 
	{
        NSBeep();
    }
    return;
}

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell {
    [self setErrorMessage:message];
    if (ringBell) {
        [self ringBell];
    }
    return;
}

- (void)playbackRegister:(XVimRegister*)xregister withRepeatCount:(NSUInteger)count{
    [xregister playbackWithHandler:self withRepeatCount:count];
}

- (void)recordIntoRegister:(XVimRegister*)xregister{
    if (_recordingRegister == nil){
        _recordingRegister = xregister;
        [self setStaticMessage:@"recording"];
        // when you record into a register you clear out any previous recording
        // unless it was capitalized
        [_recordingRegister clear];
    }else{        
        [self ringBell];
    }
}

- (void)stopRecordingRegister:(XVimRegister*)xregister{
    if (_recordingRegister == nil){
        [self ringBell];
    }else{
        _recordingRegister = nil;
        [self setStaticMessage: @""];
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

@end
