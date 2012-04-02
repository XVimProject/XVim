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

#define STATUS_BAR_HEIGHT 18

@implementation XVimCommandLine
@synthesize tag = _tag;
@synthesize xvim = _xvim;
@synthesize mode = _mode;
@synthesize additionalStatus = _additionalStatus;

- (id)init{
    self = [super initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
    if (self) {
        // Command View
        
        _command = [[XVimCommandField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
        _command.delegate = self;
        [_command setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0.0]];
        _command.stringValue = @"";
        [_command setEditable:NO];
        [_command setBordered:NO];
        [[_command cell] setFocusRingType:NSFocusRingTypeNone];
        [_command setFont:[NSFont fontWithName:@"Courier" size:[NSFont systemFontSize]]];
        [self addSubview:_command];
        
        // Status View
        _mode = @"";
        _additionalStatus = @"";
        NSMutableParagraphStyle* paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraph setAlignment:NSRightTextAlignment];
        [paragraph setTailIndent:-10.0];
        _status = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 0, STATUS_BAR_HEIGHT)];
        [_status setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0.0]];
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
    [super dealloc];
}

// Layout our statusbar in DVTSourceTextScrollView
// TODO: This process may be done in viewDidEndLiveResize of DVTSourceTextScrollView
// We can override the method and after the original method, we can relayout the subviews.
- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view{
    NSRect frame = [view frame];
    frame.size.width -= 35;
    [_command setFrameSize:NSMakeSize(frame.size.width/2, STATUS_BAR_HEIGHT)];
    [_command setFrameOrigin:NSMakePoint(10, 0)];
    [_status setFrameSize:NSMakeSize(frame.size.width/2-20, STATUS_BAR_HEIGHT)];
    [_status setFrameOrigin:NSMakePoint(frame.size.width/2,0)];
    
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
            
            barFrame.origin.y = bounds.origin.y + bounds.size.height -STATUS_BAR_HEIGHT-12;
            barFrame.origin.x = 28; // TODO Get DVTTextSidebarView width to specify correct value
            barFrame.size.width = bounds.size.width - 20 -28;
            barFrame.size.height = STATUS_BAR_HEIGHT;
            [v setFrame:barFrame];
        }
        else{
            //r.size.height = parentRect.size.height - STATUS_BAR_HEIGHT;
            //[v setFrame:r];
        }
    }
}

- (void)viewWillDraw{
    [self layoutDVTSourceTextScrollViewSubviews:(NSScrollView*)[self superview]];
    [super viewWillDraw];
}

- (void)drawRect:(NSRect)dirtyRect{
    NSString *statusString = [self.xvim modeName];
    if ([self.additionalStatus length] > 0){
        statusString = [statusString stringByAppendingFormat:@" --%@", self.additionalStatus];
    }
    [_status setStringValue:statusString];
    id fontAndColors = [[[self.xvim sourceView] textStorage] fontAndColorTheme];
    
    NSColor* color;
    if( [_command.stringValue isEqualToString:@""] ){
        color = [NSColor colorWithSRGBRed:0 green:0.0 blue:0.0 alpha:0.0]; // not visible
        [_status setTextColor:[fontAndColors sourcePlainTextColor]];

    }else{
        color = [[fontAndColors sourcePlainTextColor] colorWithAlphaComponent:0.8];
        [_command setTextColor:[fontAndColors sourceTextBackgroundColor]];
        [_status setTextColor:[fontAndColors sourceTextBackgroundColor]];
    }
    [color set];
    NSBezierPath* path= [NSBezierPath bezierPathWithRect:dirtyRect];
    [path fill];
    [super drawRect:dirtyRect];
}

- (void)didFrameChanged:(NSNotification*)notification{
    [self layoutDVTSourceTextScrollViewSubviews:[notification object]];
    [self setNeedsDisplay:YES];
}

- (void)didClipViewFrameChanged:(NSNotification*)notification{
}

- (void)setFocusOnCommandWithFirstLetter:(NSString*)first{
    [_command setEditable:YES];
    [[self window] makeFirstResponder:_command];
    _command.stringValue = first;
    NSText* textEditor = [[self window] fieldEditor:YES forObject:_command];
    [textEditor moveToEndOfLine:self];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command{
    TRACE_LOG(@"Command : %@", NSStringFromSelector(command));
    if( @selector(insertNewline:) == command ){
        [self.xvim commandDetermined:[_command stringValue]];
        return YES;
    }else if( @selector(complete:) == command || @selector(cancelOperation:) == command){
        [self.xvim commandCanceled];
        return YES;
    }else if( @selector(deleteBackward:) ){
        if( 1 == [[_command stringValue] length] ){
            return YES;
        }
    }
    return NO; 
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
    METHOD_TRACE_LOG();  
    _command.stringValue = @"";
    [_command setEditable:NO];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification{
    METHOD_TRACE_LOG();  
}

@end
