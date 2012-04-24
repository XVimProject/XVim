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
#import "DVTSourceTextView.h"
#import "DVTFoldingTextStorage.h"
#import "DVTFontAndColorsTheme.h"
#import "DVTBorderedView.h"

#define STATUS_BAR_HEIGHT 24
#define COMMAND_FIELD_HEIGHT 18


@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSTextField* _static;
    DVTBorderedView* _status;
    NSTextField* _statusString;
    NSTextField* _argument;
    NSTextField* _error;
	NSBox* _statusBarBackgroundBox;
    NSTimer* _errorTimer;
}
@end

@implementation XVimCommandLine
@synthesize tag = _tag;
- (id) init{
    self = [super initWithFrame:NSMakeRect(0, 0, 100, STATUS_BAR_HEIGHT+COMMAND_FIELD_HEIGHT)];
    if (self) {
        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSTextField alloc] init];
        [_static setEditable:NO];
        [_static setBordered:NO];
        [_static setSelectable:NO];
        [[_static cell] setFocusRingType:NSFocusRingTypeNone];
        [_static setBackgroundColor:[NSColor textBackgroundColor]]; 
        [self addSubview:_static];
        
        // Error Message
        _error = [[NSTextField alloc] init];
        [_error setEditable:NO];
        [_error setBordered:NO];
        [_error setSelectable:NO];
        [[_error cell] setFocusRingType:NSFocusRingTypeNone];
        [_error setBackgroundColor:[NSColor redColor]]; 
        [_error setHidden:YES];
        [self addSubview:_error];
        
        // Command View
        _command = [[XVimCommandField alloc] init];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        [_command setTextColor:[NSColor textColor]];
        [_command setBackgroundColor:[NSColor textBackgroundColor]]; 
        [_command setHidden:YES];
        [self addSubview:_command];
        
        _status= [NSClassFromString(@"IDEGlassBarView") performSelector:@selector(alloc)];
        _status = [_status init];
        [_status setAllBordersToColor:[NSColor clearColor]];
        _status.borderSides = 0;
        _status.shadowSides = 0;
        [_status setAllInactiveBordersToColor:[NSColor clearColor]];
        
		// Box
		_statusBarBackgroundBox = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
		[_statusBarBackgroundBox setBorderType:NSNoBorder];
		[_statusBarBackgroundBox setBoxType:NSBoxCustom];
		[_statusBarBackgroundBox setFillColor:[NSColor clearColor]];
		[self addSubview:_statusBarBackgroundBox];
        
        // Status View
        NSMutableParagraphStyle* paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSRightTextAlignment];
        _statusString = [[NSTextField alloc] init];
        [_status addSubview:_statusString];
        [self addSubview:_status];
        [_statusString setAlignment:NSLeftTextAlignment];
        [_statusString setEditable:NO];
        [_statusString setSelectable:NO];
        [_statusString setTextColor:[NSColor windowFrameTextColor]];
        [_statusString setBackgroundColor:[NSColor clearColor]];
        
		// Argument View
		_argument = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_argument setAlignment:NSLeftTextAlignment];
        [_argument setEditable:NO];
        [_argument setBordered:NO];
        [_argument setSelectable:NO];
        [[_argument cell] setFocusRingType:NSFocusRingTypeNone];
        [_argument setBackgroundColor:[NSColor clearColor]];
        [self addSubview:_argument];
        self.tag = XVIM_CMDLINE_TAG;
    }
    return self;
}

- (void)dealloc{
	[_statusBarBackgroundBox release];
    [_command release];
	[_argument release];
    [_status release];
    [_static release];
    [_error release];
    [super dealloc];
}

- (void)errorMsgExpired{
    [_error setHidden:YES];
}

- (void)setStatusString:(NSString*)string
{
    [_statusString setStringValue:string];
}

- (void)setArgumentString:(NSString*)string
{
	[_argument setStringValue:string];
}

- (void)setStaticString:(NSString*)string
{
	[_static setStringValue:string];
}

- (void)errorMessage:(NSString*)string
{
	NSString* msg = string;
	if( [msg length] != 0 ){
		[_error setStringValue:msg];
		[_error setHidden:NO];
		[_errorTimer invalidate];
		_errorTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(errorMsgExpired) userInfo:nil repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:_errorTimer forMode:NSDefaultRunLoopMode];
	}else{
		[_errorTimer invalidate];
		[_error setHidden:YES];
	}
}

- (XVimCommandField*)commandField
{
	return _command;
}

- (void)layoutCmdline:(NSView*) parent{
    NSRect frame = [parent frame];
	CGFloat statusMargin = 2;
	CGFloat argumentSize = 100;
    
    [_static setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_error setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_error setFrameOrigin:NSMakePoint(0, COMMAND_FIELD_HEIGHT)];
    [_statusBarBackgroundBox setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT)];
    [_statusBarBackgroundBox setFrameOrigin:NSMakePoint(0,COMMAND_FIELD_HEIGHT)];
    [_status setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT)];
    [_status setFrameOrigin:NSMakePoint(0,COMMAND_FIELD_HEIGHT)];
    [[[_status subviews] objectAtIndex:0] setFrame:NSMakeRect(statusMargin,0,frame.size.width,STATUS_BAR_HEIGHT)]; 
    [_argument setFrameSize:NSMakeSize(argumentSize, COMMAND_FIELD_HEIGHT)];
    [_argument setFrameOrigin:NSMakePoint(frame.size.width - argumentSize,STATUS_BAR_HEIGHT)];
    
    NSView *border,*nsview;
    for( NSView* v in [parent subviews] ){
        if( [NSStringFromClass([v class]) isEqualToString:@"DVTBorderedView"] ){
            border = v;
        }else if( [NSStringFromClass([v class]) isEqualToString:@"NSView"] ){
            nsview = v;
        }
    }
    if( [border isHidden] ){
        self.frame = NSMakeRect(0, 0, parent.frame.size.width, STATUS_BAR_HEIGHT+COMMAND_FIELD_HEIGHT);
        nsview.frame = NSMakeRect(0, STATUS_BAR_HEIGHT+COMMAND_FIELD_HEIGHT, parent.frame.size.width, parent.frame.size.height-STATUS_BAR_HEIGHT-COMMAND_FIELD_HEIGHT);
    }else{
        self.frame = NSMakeRect(0, border.frame.size.height, parent.frame.size.width, STATUS_BAR_HEIGHT+COMMAND_FIELD_HEIGHT);
        nsview.frame = NSMakeRect(0, border.frame.size.height+STATUS_BAR_HEIGHT+COMMAND_FIELD_HEIGHT, parent.frame.size.width, parent.frame.size.height-border.frame.size.height-STATUS_BAR_HEIGHT-COMMAND_FIELD_HEIGHT);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"hidden"]) {
        [self layoutCmdline:[self superview]];
    }
}

- (void)didFrameChanged:(NSNotification*)notification
{
    [self layoutCmdline:[notification object]];
}

@end
