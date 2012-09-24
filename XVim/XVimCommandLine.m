//
//  XVimCommandLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandLine.h"
#import "XVimCommandField.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "DVTKit.h"
#import "NS(Attributed)String+Geometrics.h"
#import <objc/runtime.h>

#define DEFAULT_COMMAND_FIELD_HEIGHT 18.0


@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSInsetTextView* _static;
    NSInsetTextView* _error;
    NSInsetTextView* _argument;
    NSInsetTextView* _quickfix;
    NSString* _quickfixString;
    
    NSTimer* _errorTimer;
}
- (void)layoutCmdline:(NSView*)view;
@end

@implementation XVimCommandLine

- (id)init
{
    self = [super initWithFrame:NSMakeRect(0, 0, 100, DEFAULT_COMMAND_FIELD_HEIGHT)];
    if (self) {
        [self setBoundsOrigin:NSMakePoint(0,0)];

        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, DEFAULT_COMMAND_FIELD_HEIGHT)];
        [_static setEditable:NO];
        [_static setSelectable:NO];
        [_static setBackgroundColor:[NSColor textBackgroundColor]];
        [_static setHidden:NO];
        _static.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_static];

        // Error Message
        _error = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, DEFAULT_COMMAND_FIELD_HEIGHT)];
        [_error setEditable:NO];
        [_error setSelectable:NO];
        [_error setBackgroundColor:[NSColor redColor]];
        [_error setHidden:YES];
        _error.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_error];

        // Quickfix
        _quickfix = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, DEFAULT_COMMAND_FIELD_HEIGHT)];
        [_quickfix setEditable:NO];
        [_quickfix setSelectable:NO];
        [_quickfix setBackgroundColor:[NSColor redColor]];
        [_quickfix setHidden:YES];
        _quickfix.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_quickfix];
        
        // Command View
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 100, DEFAULT_COMMAND_FIELD_HEIGHT)];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        [_command setTextColor:[NSColor textColor]];
        [_command setBackgroundColor:[NSColor textBackgroundColor]];
        [_command setHidden:YES];
        _command.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_command];

		// Argument View
		_argument = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 0, DEFAULT_COMMAND_FIELD_HEIGHT)];
        [_argument setEditable:NO];
        [_argument setSelectable:NO];
        [_argument setBackgroundColor:[NSColor clearColor]];
        [_argument setHidden:NO];
        _argument.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_argument];

        self.autoresizesSubviews = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontAndColorSourceTextSettingsChanged:) name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
        
    }
    return self;
}

- (void)dealloc{
    [_command release];
    [_static release];
    [_error release];
    [_quickfix release];
    [_argument release];
    [ _quickfixString release ];
    [super dealloc];
}

- (void)viewDidMoveToSuperview
{
    [self layoutCmdline:[self superview]];
}

- (void)errorMsgExpired
{
    [_error setHidden:YES];
}

- (void)setModeString:(NSString*)string
{
    [_static setString:string];
    [self layoutCmdline:[self superview]];
}

- (void)setArgumentString:(NSString*)string{
    [_argument setString:string];
}

- (void)errorMessage:(NSString*)string
{
	NSString* msg = string;
	if( [msg length] != 0 ){
		[_error setString:msg];
		[_error setHidden:NO];
		[_errorTimer invalidate];
		_errorTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(errorMsgExpired) userInfo:nil repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:_errorTimer forMode:NSDefaultRunLoopMode];
	}else{
		[_errorTimer invalidate];
		[_error setHidden:YES];
	}
}

-(void)quickFixWithString:(NSString*)string
{
	if( string && [string length] != 0 ){
        [ _quickfixString release ];
        _quickfixString = [ [ NSString stringWithFormat:@"%@\n\nPress a key to return to Xcode...",string ] copy ];
		[_quickfix setString:_quickfixString ];
		[_quickfix setHidden:NO];
        [ self layoutCmdline:[self superview]];
	}else{
		[_quickfix setHidden:YES];
        [ self layoutCmdline:[self superview]];
	}
}

- (XVimCommandField*)commandField
{
	return _command;
}

- (void)layoutCmdline:(NSView*) parent{
    NSRect frame = [parent frame];
    [NSClassFromString(@"DVTFontAndColorTheme") addObserver:self forKeyPath:@"currentTheme" options:NSKeyValueObservingOptionNew context:nil];
    [self setBoundsOrigin:NSMakePoint(0,0)];
	
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
	NSFont *sourceFont = [theme sourcePlainTextFont];
	
	// Calculate inset
	CGFloat horizontalInset = 0;
	CGFloat verticalInset = MAX((DEFAULT_COMMAND_FIELD_HEIGHT - [sourceFont pointSize]) / 2, 0);
	CGSize inset = CGSizeMake(horizontalInset, verticalInset);
    
    CGFloat tallestSubviewHeight = DEFAULT_COMMAND_FIELD_HEIGHT ;
    
    // Set colors
	[_static setTextColor:[theme sourcePlainTextColor]];
    [_static setBackgroundColor:[theme sourceTextBackgroundColor]];
	[_static setFont:sourceFont];
    [_command setTextColor:[theme sourcePlainTextColor]];
    [_command setBackgroundColor:[theme sourceTextBackgroundColor]];
    [_command setInsertionPointColor:[theme sourceTextInsertionPointColor]];
	[_command setFont:sourceFont];
    [_argument setTextColor:[theme sourcePlainTextColor]];
	[_argument setFont:sourceFont];
	[_error setFont:sourceFont];
	[_quickfix setTextColor:[theme consoleDebuggerOutputTextColor]];
    [_quickfix setBackgroundColor:[theme consoleTextBackgroundColor]];
	[_quickfix setFont:[theme consoleExecutableOutputTextFont]];
	
	CGFloat argumentSize = MIN(frame.size.width, 100);
    
    // Layout command area
    [_error setFrameSize:NSMakeSize(frame.size.width, DEFAULT_COMMAND_FIELD_HEIGHT)];
    [_error setFrameOrigin:NSMakePoint(0, 0)];
    [_quickfix setFrameOrigin:NSMakePoint(0, 0)];
    if ( [_quickfix isHidden])
    {
        [_quickfix setFrameSize:NSMakeSize(frame.size.width, DEFAULT_COMMAND_FIELD_HEIGHT ) ];
    }
    else
    {
        NSSize idealQuickfixSize = [ _quickfixString sizeForWidth:frame.size.width height:(frame.size.height*0.75) font:[theme consoleExecutableOutputTextFont]];
        idealQuickfixSize.width = frame.size.width ;
        [_quickfix setFrameSize:idealQuickfixSize ];
        tallestSubviewHeight = idealQuickfixSize.height ;
    }
    [_static setFrameSize:NSMakeSize(frame.size.width, DEFAULT_COMMAND_FIELD_HEIGHT)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, DEFAULT_COMMAND_FIELD_HEIGHT)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_argument setFrameSize:NSMakeSize(argumentSize, DEFAULT_COMMAND_FIELD_HEIGHT)];
    [_argument setFrameOrigin:NSMakePoint(frame.size.width - argumentSize, 0)];
    
    NSView *border = nil;
    NSView *nsview = nil;
    for( NSView* v in [parent subviews] ){
        if( [NSStringFromClass([v class]) isEqualToString:@"DVTBorderedView"] ){
            border = v;
        }else if( [NSStringFromClass([v class]) isEqualToString:@"NSView"] ){
            nsview = v;
        }
    }
    if( nsview != nil && border != nil && [border isHidden] ){
        self.frame = NSMakeRect(0, 0, parent.frame.size.width, +tallestSubviewHeight);
        nsview.frame = NSMakeRect(0, tallestSubviewHeight, parent.frame.size.width, parent.frame.size.height-tallestSubviewHeight);
    }else{
        self.frame = NSMakeRect(0, border.frame.size.height, parent.frame.size.width, tallestSubviewHeight);
        nsview.frame = NSMakeRect(0, border.frame.size.height+tallestSubviewHeight, parent.frame.size.width, parent.frame.size.height-border.frame.size.height-tallestSubviewHeight);
    }
	
	[_static setInset:inset];
	[_error setInset:inset];
	[_quickfix setInset:NSZeroSize];
	[_argument setInset:inset];
	[_command setInset:inset];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"hidden"]) {
        [self layoutCmdline:[self superview]];
    }else if( [keyPath isEqualToString:@"DVTFontAndColorCurrentTheme"] ){
        [self layoutCmdline:[self superview]];
    }
}

- (void)didFrameChanged:(NSNotification*)notification
{
    [self layoutCmdline:[notification object]];
}

- (void)fontAndColorSourceTextSettingsChanged:(NSNotification*)notification{
    [self layoutCmdline:[self superview]];
}

static char s_associate_key = 0;

+ (XVimCommandLine*)associateOf:(id)object
{
	return (XVimCommandLine*)objc_getAssociatedObject(object, &s_associate_key);
}

- (void)associateWith:(id)object
{
	objc_setAssociatedObject(object, &s_associate_key, self, OBJC_ASSOCIATION_RETAIN);
}

@end
