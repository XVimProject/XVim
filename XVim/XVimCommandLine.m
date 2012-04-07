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
}
@end

@implementation XVimCommandLine
@synthesize tag = _tag;
@synthesize mode = _mode;
@synthesize additionalStatus = _additionalStatus;

- (id)initWithXVim:(XVim *)xvim{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
    if (self) {
        [xvim addObserver:self forKeyPath:@"mode" options:NSKeyValueObservingOptionNew context:nil];
        _xvim = [xvim retain];
        
        // Command View
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_command setBackgroundColor:[NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:0.0]];
        [_command setString: @""];
        [_command setEditable:NO];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        _command.delegate = xvim;
        [self addSubview:_command];
        
        // Status View
        _mode = @"";
        _additionalStatus = @"";
        NSMutableParagraphStyle* paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSRightTextAlignment];
        [paragraph setTailIndent:0];
        _status = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT/2)];
        [_status setBackgroundColor:[NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:0.0]];
        _status.stringValue = _mode;
        [_status setAlignment:NSRightTextAlignment];
        [_status setEditable:NO];
        [_status setBordered:NO];
        [_status setSelectable:NO];
        [[_status cell] setFocusRingType:NSFocusRingTypeNone];
        [self addSubview:_status];
    }
    return self;
}

- (void)dealloc{
    [_command release];
    [_status release];
    [_xvim release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"mode"] ){
        [_status setStringValue:MODE_STRINGS[[((NSNumber*)[change valueForKey:NSKeyValueChangeNewKey]) integerValue]]];
    }
}
// Layout our statusbar in DVTSourceTextScrollView
// TODO: This process may be done in viewDidEndLiveResize of DVTSourceTextScrollView
// We can override the method and after the original method, we can relayout the subviews.
- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view{
    NSRect frame = [view frame];
    [_command setFrameSize:NSMakeSize(frame.size.width, STATUS_BAR_HEIGHT/2)];
    [_command setFrameOrigin:NSMakePoint(0, 0)];
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
            //barFrame.origin.y = bounds.origin.y + bounds.size.height -STATUS_BAR_HEIGHT;
            //barFrame.size.height = STATUS_BAR_HEIGHT;
            
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


- (void)drawRect:(NSRect)dirtyRect{
    NSString *statusString = [_xvim modeName];
    if ([self.additionalStatus length] > 0){
        statusString = [statusString stringByAppendingFormat:@" --%@", self.additionalStatus];
    }
    [_status setStringValue:statusString];
    id fontAndColors = [[[_xvim sourceView] textStorage] fontAndColorTheme];
    
    [_status setTextColor:[fontAndColors sourcePlainTextColor]];
    [_status setBackgroundColor:[fontAndColors sourceTextInvisiblesColor]];
    [_command setTextColor:[fontAndColors sourcePlainTextColor]];
    [_command setBackgroundColor:[fontAndColors sourceTextBackgroundColor]]; 
    
    [super drawRect:dirtyRect];
}

- (void)didFrameChanged:(NSNotification*)notification{
    [self layoutDVTSourceTextScrollViewSubviews:[notification object]];
    [self setNeedsDisplay:YES];
}

- (void)setFocusOnCommandWithFirstLetter:(NSString*)first{
    [_command setEditable:YES];
    [[self window] makeFirstResponder:_command];
    [_command setString:first];
    [_command moveToEndOfLine:self];
}


- (void)statusMessage:(NSString*)msg{
    
}

- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt{
    [_command ask:msg owner:owner handler:selector option:opt];
}
@end
