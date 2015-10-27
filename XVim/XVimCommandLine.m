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

@interface XVimCommandLine() {
@private
    XVimCommandField* _command;
    NSTextField* _static;
    NSTextField* _error;
    NSTextField* _argument;

    XVimQuickFixView* _quickFixScrollView;
    id _quickFixObservation;
    NSTimer* _errorTimer;
}
@end

@implementation XVimCommandLine

-(void)updateFontAndColors{
        NSColor* textColor = [NSColor textColor];
        NSFont* textFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        NSColor* textBackgroundColor = [NSColor textBackgroundColor]; 
        DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
        if( nil != theme ){
            textColor = [theme sourcePlainTextColor];
            textFont = [theme sourcePlainTextFont];
            textBackgroundColor = [theme sourceTextBackgroundColor];
        }
        [_static setFont:textFont];
        [_static setTextColor:textColor];
        [_static invalidateIntrinsicContentSize];
    
        [_command setFont:textFont];
        [_command setTextColor:textColor];
        [_command invalidateIntrinsicContentSize];
    
        [_argument setFont:textFont];
        [_argument setTextColor:textColor];
        [_argument invalidateIntrinsicContentSize];
    
        [_error setFont:textFont];
        [_error setTextColor:textColor];
        [_error setBackgroundColor:textBackgroundColor];
        [_error invalidateIntrinsicContentSize];
    
        [self invalidateIntrinsicContentSize];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Static Message ( This is behind the command view if the command is active)
        _static = [[NSTextField alloc] init];
        [_static setEditable:NO];
        [_static setSelectable:NO];
        [_static setBackgroundColor:[NSColor clearColor]];
        [_static setHidden:NO];
        [_static setBordered:NO];
        [_static setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Width (fill the command line)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_static 
                                                         attribute:NSLayoutAttributeWidth 
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeWidth 
                                                        multiplier:1.0
                                                          constant:0.0]];
        // Left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_static 
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_static 
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Bottom edge (Superview's bottom is greater than _static bottom)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_static
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0 
                                                          constant:0.0]];
        [self addSubview:_static];

        // Error Message
        _error = [[NSTextField alloc] init];
        [_error setEditable:NO];
        [_error setSelectable:NO];
        [_error setBackgroundColor:[NSColor redColor]];
        [_error setHidden:YES];
        [_error setBordered:NO];
        [_error setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Width
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_error
                                                         attribute:NSLayoutAttributeWidth 
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeWidth 
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_error
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_error
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Bottom edge 
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_error
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0 
                                                          constant:0.0]];
        
        [self addSubview:_error];
        
        
        // TODO: QuickFix view(height) doesn't show properly now
        // Quickfix View
        _quickFixScrollView = [[XVimQuickFixView alloc] init];
        [_quickFixScrollView setHidden:YES];
        [_quickFixScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Width
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeWidth 
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeWidth 
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Bottom edge (Superview's bottom is greater than _command bottom)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0 
                                                          constant:0.0]];
       [self addSubview:_quickFixScrollView];
        

        
        // Command View
        _command = [[XVimCommandField alloc] init];
        [_command setEditable:NO];
        [_command setSelectable:NO];
        [_command setBackgroundColor:[NSColor clearColor]];
        [_command setHidden:YES];
        [_command setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Width
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_command
                                                         attribute:NSLayoutAttributeWidth 
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeWidth 
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_command
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_command
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Bottom edge (Superview's bottom is greater than _command bottom)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_command
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0 
                                                          constant:0.0]];
        [self addSubview:_command];
        
		// Argument View
        _argument = [[NSTextField alloc] init];
        [_argument setEditable:NO];
        [_argument setSelectable:NO];
        [_argument setBackgroundColor:[NSColor clearColor]];
        [_argument setHidden:NO];
        [_argument setBordered:NO];
        // TODO: Text alignment here doesn't work as I expected.
        // I want to show the latest input even when the argument string exceeds the max width of the field
        // but now it only shows head of arguments
        [_argument setAlignment:NSRightTextAlignment]; //
        [_argument setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        // Right edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_argument
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_argument
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual 
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0 
                                                          constant:0.0]];
        // Width limitation (half of command line)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_argument
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:0.5 
                                                          constant:0.0]];
        // Bottom edge (Superview's bottom is greater than _argument bottom)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_argument
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self 
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0 
                                                          constant:0.0]];
        
        [self addSubview:_argument];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontAndColorSourceTextSettingsChanged:) name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
        
        [self updateFontAndColors];
    }
    return self;
}

-(void)drawRect:(NSRect)dirtyRect{
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    // set any NSColor for filling, say white:
    [[theme sourceTextBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

-(void)dealloc
{
    [[ NSNotificationCenter defaultCenter ] removeObserver:self name:@"DVTFontAndColorSourceTextSettingsChangedNotification" object:nil];
    [[ NSNotificationCenter defaultCenter ] removeObserver:_quickFixObservation];
}

- (void)errorMsgExpired
{
    [_error setHidden:YES];
}

- (void)setModeString:(NSString*)string
{
    [_static setStringValue:string];
}

- (void)setArgumentString:(NSString*)string{
    if(nil != string){
        [_argument setStringValue:string];
    }
}
/**
 * (BOOL)aRedColorSetting
 *      YES: red color background
 *      NO : default color background
 */
- (void)errorMessage:(NSString*)string Timer:(BOOL)aTimer RedColorSetting:(BOOL)aRedColorSetting
{
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    if( aRedColorSetting ){
        _error.backgroundColor = [NSColor redColor];
    } else {
        _error.backgroundColor = [theme sourceTextBackgroundColor];
    }
	NSString* msg = string;
	if( [msg length] != 0 ){
		[_error setStringValue:msg];
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
        [[_quickFixScrollView window] performSelector:@selector(makeFirstResponder:) withObject:_quickFixScrollView.textView afterDelay:0 ];
        [_quickFixScrollView.textView performSelector:@selector(scrollToEndOfDocument:) withObject:self afterDelay:0 ];
	}else{
        [[ NSNotificationCenter defaultCenter ] removeObserver:_quickFixObservation];
        [ _quickFixScrollView setString:@"" withPrompt:@""];
        _quickFixObservation = nil;
        [_quickFixScrollView setHidden:YES];
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

- (void)fontAndColorSourceTextSettingsChanged:(NSNotification*)notification{
    [self updateFontAndColors];
    [self setNeedsDisplay:YES];
}

@end
