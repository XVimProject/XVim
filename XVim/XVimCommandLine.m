//
//  XVimCommandLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandLine.h"
#import "XVimCommandField.h"
#import "XVimQuickFixView.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "DVTKit.h"
#import "NSAttributedString+Geometrics.h"
#import <objc/runtime.h>

#define COMMAND_FIELD_HEIGHT 18.0
#define MAX_COMMAND_TEXT_SIZE 14.0

@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSInsetTextView* _static;
    NSInsetTextView* _error;
    NSInsetTextView* _argument;

    XVimQuickFixView* _quickFixScrollView;
    id _quickFixObservation;
    NSResponder __weak* previousFirstResponder;
    NSTimer* _errorTimer;
}
- (void)layoutCmdline:(NSView*)view;
@end

@implementation XVimCommandLine

- (id)init
{
    self = [super initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
    if (self) {
        [self setBoundsOrigin:NSMakePoint(0,0)];

        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_static setEditable:NO];
        [_static setSelectable:NO];
        [_static setBackgroundColor:[NSColor textBackgroundColor]];
        [_static setHidden:NO];
        _static.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_static];

        // Error Message
        _error = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_error setEditable:NO];
        [_error setSelectable:NO];
        [_error setBackgroundColor:[NSColor redColor]];
        [_error setHidden:YES];
        _error.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_error];

        // Quickfix View
        _quickFixScrollView = [[XVimQuickFixView alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_quickFixScrollView setHidden:YES];
        [self addSubview:_quickFixScrollView];

        
        // Command View
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 100, COMMAND_FIELD_HEIGHT)];
        [_command setEditable:NO];
        
        NSFont *commandFont =[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]];
        if (commandFont.pointSize > MAX_COMMAND_TEXT_SIZE) {
            commandFont = [NSFont fontWithName:[commandFont fontName] size:MAX_COMMAND_TEXT_SIZE];
        }
        
        [_command setFont:commandFont];
        [_command setTextColor:[NSColor textColor]];
        [_command setBackgroundColor:[NSColor textBackgroundColor]];
        [_command setHidden:YES];
        _command.autoresizingMask = NSViewWidthSizable;
        [self addSubview:_command];

		// Argument View
		_argument = [[NSInsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 0, COMMAND_FIELD_HEIGHT)];
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

-(void)dealloc
{
    [[ NSNotificationCenter defaultCenter ] removeObserver:_quickFixObservation];
}

- (NSInteger)tag
{
    return XVimCommandLineTag;
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
    if(nil != string){
        [_argument setString:string];
    }
}
/**
 * (BOOL)aRedColorSetting
 *      YES: red color background
 *      NO : white color background
 */
- (void)errorMessage:(NSString*)string Timer:(BOOL)aTimer RedColorSetting:(BOOL)aRedColorSetting
{
    if( aRedColorSetting ){
        _error.backgroundColor = [NSColor redColor];
    } else {
        _error.backgroundColor = [NSColor whiteColor];
    }
	NSString* msg = string;
	if( [msg length] != 0 ){
		[_error setString:msg];
		[_error setHidden:NO];
		[_errorTimer invalidate];
        if( aTimer ){
            
            _errorTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(errorMsgExpired) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:_errorTimer forMode:NSDefaultRunLoopMode];
        }
	}else{
		[_errorTimer invalidate];
		[_error setHidden:YES];
	}
}

static NSString* QuickFixPrompt = @"\nPress a key to continue...";

-(void)quickFixWithString:(NSString*)string completionHandler:(void(^)(void))completionHandler
{
	if( string && [string length] != 0 ){
        // Set up observation to close the quickfix window when a key is pressed, or it loses focus
        __weak XVimCommandLine* this = self;
        void (^completionHandlerCopy)(void) = [completionHandler copy];
        _quickFixObservation = [ [ NSNotificationCenter defaultCenter ] addObserverForName:XVimNotificationQuickFixDidComplete
                                                             object:_quickFixScrollView
                                                              queue:nil
                                                         usingBlock:^(NSNotification *note) {
                                                             [this quickFixWithString:nil completionHandler:completionHandlerCopy ];
                                                         }];
        [ _quickFixScrollView setString:string withPrompt:QuickFixPrompt];
		[ _quickFixScrollView setHidden:NO ];
        [ self layoutCmdline:[self superview]];
        [[_quickFixScrollView window] performSelector:@selector(makeFirstResponder:) withObject:_quickFixScrollView.textView afterDelay:0 ];
        [_quickFixScrollView.textView performSelector:@selector(scrollToEndOfDocument:) withObject:self afterDelay:0 ];
	}else{
        [[ NSNotificationCenter defaultCenter ] removeObserver:_quickFixObservation];
        _quickFixObservation = nil;
		[_quickFixScrollView setHidden:YES];
        [ self layoutCmdline:[self superview]];
        if (completionHandler) { completionHandler(); }
	}
}

-(NSUInteger)quickFixColWidth
{
    return _quickFixScrollView.colWidth;
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

        if (sourceFont.pointSize > MAX_COMMAND_TEXT_SIZE) {
            sourceFont = [NSFont fontWithName:[sourceFont fontName] size:MAX_COMMAND_TEXT_SIZE];
        }
	// Calculate inset
	CGFloat horizontalInset = 0;
	CGFloat verticalInset = MAX((COMMAND_FIELD_HEIGHT - [sourceFont pointSize]) / 2, 0);
	CGSize inset = CGSizeMake(horizontalInset, verticalInset);
    
    CGFloat tallestSubviewHeight = COMMAND_FIELD_HEIGHT ;
    
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
	
	CGFloat argumentSize = MIN(frame.size.width, 100);
    
    // Layout command area
    [_error setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_error setFrameOrigin:NSMakePoint(0, 0)];
    [_quickFixScrollView setFrameOrigin:NSMakePoint(0, 0)];
    if ( [_quickFixScrollView isHidden])
    {
        [_quickFixScrollView setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT ) ];
    }
    else
    {
        NSSize idealQuickfixSize = [ [_quickFixScrollView.textView string] sizeForWidth:frame.size.width height:(frame.size.height*0.5) font:[theme consoleExecutableOutputTextFont]];
        idealQuickfixSize.width = frame.size.width ;
        [_quickFixScrollView setFrameSize:idealQuickfixSize ];
        tallestSubviewHeight = idealQuickfixSize.height ;
    }
    [_static setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, COMMAND_FIELD_HEIGHT)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_argument setFrameSize:NSMakeSize(argumentSize, COMMAND_FIELD_HEIGHT)];
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

@end
