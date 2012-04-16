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

#define STATUS_BAR_HEIGHT 36 


@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSTextField* _static;
    NSTextField* _status;
    NSTextField* _argument;
    NSTextField* _error;
	NSBox* _statusBarBackgroundBox;
    NSTimer* _errorTimer;
}
@end

@implementation XVimCommandLine
@synthesize tag = _tag;

- (id)initWithWindow:(XVimWindow*)window
{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
    if (self) {
        
        id fontAndColors = [[[window sourceView] textStorage] fontAndColorTheme];
        
        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_static setEditable:NO];
        [_static setBordered:NO];
        [_static setSelectable:NO];
        [[_static cell] setFocusRingType:NSFocusRingTypeNone];
        [_static setBackgroundColor:[fontAndColors sourceTextBackgroundColor]]; 
        [self addSubview:_static];
        
        // Error Message
        _error = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_error setEditable:NO];
        [_error setBordered:NO];
        [_error setSelectable:NO];
        [[_error cell] setFocusRingType:NSFocusRingTypeNone];
        [_error setBackgroundColor:[NSColor redColor]]; 
        [_error setHidden:YES];
        [self addSubview:_error];
        
        // Command View
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        [_command setTextColor:[fontAndColors sourcePlainTextColor]];
        [_command setBackgroundColor:[fontAndColors sourceTextBackgroundColor]]; 
        [_command setHidden:YES];
        [self addSubview:_command];
		[_command setDelegate:window];
		
		// Box
		_statusBarBackgroundBox = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
		[_statusBarBackgroundBox setBorderType:NSNoBorder];
		[_statusBarBackgroundBox setBoxType:NSBoxCustom];
		[_statusBarBackgroundBox setFillColor:[fontAndColors sourceTextInvisiblesColor]];
		[self addSubview:_statusBarBackgroundBox];
        
        // Status View
        _status = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_status setAlignment:NSLeftTextAlignment];
        [_status setEditable:NO];
        [_status setBordered:NO];
        [_status setSelectable:NO];
        [[_status cell] setFocusRingType:NSFocusRingTypeNone];
        [_status setTextColor:[fontAndColors sourcePlainTextColor]];
        [_status setBackgroundColor:[fontAndColors sourceTextInvisiblesColor]];
        [self addSubview:_status];
        
		// Argument View
		_argument = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_argument setAlignment:NSLeftTextAlignment];
        [_argument setEditable:NO];
        [_argument setBordered:NO];
        [_argument setSelectable:NO];
        [[_argument cell] setFocusRingType:NSFocusRingTypeNone];
        [_argument setTextColor:[fontAndColors sourcePlainTextColor]];
        [_argument setBackgroundColor:[fontAndColors sourceTextInvisiblesColor]];
        [self addSubview:_argument];
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
	[_status setStringValue:string];
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

// Layout our statusbar in DVTSourceTextScrollView
// TODO: This process may be done in viewDidEndLiveResize of DVTSourceTextScrollView
// We can override the method and after the original method, we can relayout the subviews.
- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view
{
    NSRect frame = [view frame];
	
	CGFloat statusMargin = 2;
	CGFloat argumentSize = 100;
	
    [_static setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_error setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_error setFrameOrigin:NSMakePoint(0, 0)];
    [_statusBarBackgroundBox setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_statusBarBackgroundBox setFrameOrigin:NSMakePoint(0,STATUS_BAR_HEIGHT/2)];
    [_status setFrameSize:NSMakeSize(frame.size.width/2, STATUS_BAR_HEIGHT/2)];
    [_status setFrameOrigin:NSMakePoint(statusMargin,STATUS_BAR_HEIGHT/2)];
    [_argument setFrameSize:NSMakeSize(argumentSize, STATUS_BAR_HEIGHT/2)];
    [_argument setFrameOrigin:NSMakePoint(frame.size.width - argumentSize,STATUS_BAR_HEIGHT/2)];
    
    NSScrollView* parent = view;
    NSArray* views = [parent subviews];
   
    for( NSView* v in views ){
        NSString* viewClass = NSStringFromClass([v class]);
        NSRect r = [v frame];
        // layout subviews in DVTSourceScrollTextView

        if( [viewClass isEqualToString:@"NSScroller"] &&  r.size.width > r.size.height){
            // There is not officail way to detect its horizontal or vertical scroller. ( It looks that NSScroller has hidden flag like "sFlag.isHoriz" )
            // Horizontal Scroller
            //r.origin.y = parentRect.size.height - r.size.height - STATUS_BAR_HEIGHT;
            //[v setFrame:r];
            //[v setNeedsDisplay:YES];
        }
        else if( [viewClass isEqualToString:@"XVimCommandLine"] ){
            NSRect bounds = [parent bounds];
            NSRect barFrame = bounds;
            barFrame.origin.y = bounds.origin.y + bounds.size.height-STATUS_BAR_HEIGHT;
            barFrame.origin.x = 0; // TODO Get DVTTextSidebarView width to specify correct value
            barFrame.size.width = bounds.size.width;
            barFrame.size.height = STATUS_BAR_HEIGHT;
            [v setFrame:barFrame];
        }
        else{
            r.size.height = frame.size.height - STATUS_BAR_HEIGHT;
            [v setFrame:r];
        }
    }
}

- (void)viewWillDraw
{
    [self layoutDVTSourceTextScrollViewSubviews:(NSScrollView*)[self superview]];
    [super viewWillDraw];
}

- (void)didFrameChanged:(NSNotification*)notification
{
    [self layoutDVTSourceTextScrollViewSubviews:[notification object]];
    [self setNeedsDisplay:YES];
}

@end
