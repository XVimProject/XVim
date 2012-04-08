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
#import "XVim.h"
#import "DVTSourceTextView.h"
#import "DVTFoldingTextStorage.h"
#import "DVTFontAndColorsTheme.h"

#define STATUS_BAR_HEIGHT 36 


@interface XVimCommandLine() {
@private
    XVim* _xvim;
    XVimCommandField* _command;
    NSTextField* _static;
    NSTextField* _status;
    NSTextField* _error;
    NSTimer* _errorTimer;
}
@end

@implementation XVimCommandLine
@synthesize tag = _tag;
@synthesize staticMessage = _staticMessage;

- (id)initWithXVim:(XVim *)xvim{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
    if (self) {
        [xvim addObserver:self forKeyPath:@"mode" options:NSKeyValueObservingOptionNew context:nil];
        [xvim addObserver:self forKeyPath:@"staticMessage" options:NSKeyValueObservingOptionNew context:nil];
        [xvim addObserver:self forKeyPath:@"errorMessage" options:NSKeyValueObservingOptionNew context:nil];
        _xvim = [xvim retain];
        
        id fontAndColors = [[[_xvim sourceView] textStorage] fontAndColorTheme];
        
        // Static Massage ( This is behind the command view if the command is active)
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
        [_command setString: @""];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        _command.delegate = xvim;
        [_command setTextColor:[fontAndColors sourcePlainTextColor]];
        [_command setBackgroundColor:[fontAndColors sourceTextBackgroundColor]]; 
        [_command setHidden:YES];
        [self addSubview:_command];
        
        // Status View
        NSMutableParagraphStyle* paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSRightTextAlignment];
        _status = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_status setAlignment:NSRightTextAlignment];
        [_status setEditable:NO];
        [_status setBordered:NO];
        [_status setSelectable:NO];
        [[_status cell] setFocusRingType:NSFocusRingTypeNone];
        [_status setTextColor:[fontAndColors sourcePlainTextColor]];
        [_status setBackgroundColor:[fontAndColors sourceTextInvisiblesColor]];
        [self addSubview:_status];
    }
    return self;
}

- (void)dealloc{
    [_command release];
    [_status release];
    [_static release];
    [_error release];
    [_xvim release];
    [super dealloc];
}

- (void)errorMsgExpired{
    [_error setHidden:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"mode"] ){
        [_status setStringValue:MODE_STRINGS[[((NSNumber*)[change valueForKey:NSKeyValueChangeNewKey]) integerValue]]];
    }
    else if( [keyPath isEqualToString:@"staticMessage"] ){
        [_static setStringValue:[change valueForKey:NSKeyValueChangeNewKey]];
    }
    else if( [keyPath isEqualToString:@"errorMessage"] ){
        NSString* msg = [change valueForKey:NSKeyValueChangeNewKey];
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
}
// Layout our statusbar in DVTSourceTextScrollView
// TODO: This process may be done in viewDidEndLiveResize of DVTSourceTextScrollView
// We can override the method and after the original method, we can relayout the subviews.
- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view{
    NSRect frame = [view frame];
    [_static setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_static setFrameOrigin:NSMakePoint(0, 0)];
    [_command setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
    [_error setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_error setFrameOrigin:NSMakePoint(0, 0)];
    [_status setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_status setFrameOrigin:NSMakePoint(0,STATUS_BAR_HEIGHT/2)];
    
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

- (void)viewWillDraw{
    [self layoutDVTSourceTextScrollViewSubviews:(NSScrollView*)[self superview]];
    [super viewWillDraw];
}


- (void)didFrameChanged:(NSNotification*)notification{
    [self layoutDVTSourceTextScrollViewSubviews:[notification object]];
    [self setNeedsDisplay:YES];
}

- (void)setFocusOnCommandWithFirstLetter:(NSString*)first{
    [_command setEditable:YES];
    [_command setHidden:NO];
    [[self window] makeFirstResponder:_command];
    [_command setString:first];
    [_command moveToEndOfLine:self];
}

- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt{
    [_command ask:msg owner:owner handler:selector option:opt];
}
@end
