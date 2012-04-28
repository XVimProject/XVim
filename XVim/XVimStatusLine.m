//
//  XVimStatusLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimStatusLine.h"
#import "DVTChooserView.h"
#import "IDESourceCodeEditor.h"


@implementation XVimStatusLine{
    DVTChooserView* _background;
    NSTextView* _status;
    NSTextView* _argument;
}

@synthesize tag;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _background = [[NSClassFromString(@"DVTChooserView") performSelector:@selector(alloc)] init];
        _background.gradientStyle = 2;  // Style number 2 looks like IDEGlassBarView   
        [_background setBorderSides:12]; // See DVTBorderedView.h for the meaning of the number
        _status = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        _status.backgroundColor = [NSColor clearColor];
        
        [self addSubview:_background];
        [self addSubview:_status];
        
		// Argument View
		_argument = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        [_argument setEditable:NO];
        [_argument setSelectable:NO];
        [_argument setBackgroundColor:[NSColor clearColor]];
        [_argument alignRight:self];
        [self addSubview:_argument];
        
        self.tag = XVIM_STATUSLINE_TAG;
    }
    
    return self;
}

- (void)dealloc
{
    [_background release];
    [_status release];
    [super dealloc];
}

#define STATUS_LINE_HEIGHT 18
- (void)layoutStatus:(NSView*)container{
    NSRect parent = [container frame];
    [self setFrame:NSMakeRect(0, 0, parent.size.width, STATUS_LINE_HEIGHT)];
    [_background setFrame:NSMakeRect(0, 0, parent.size.width, STATUS_LINE_HEIGHT)];
    [_status setFrame:NSMakeRect(0, 0, parent.size.width, STATUS_LINE_HEIGHT)];
    [_argument setFrame:NSMakeRect(0, 0, parent.size.width, STATUS_LINE_HEIGHT)];
    [[[container subviews] objectAtIndex:0] setFrame:NSMakeRect(0, STATUS_LINE_HEIGHT, parent.size.width, parent.size.height-STATUS_LINE_HEIGHT)];
}
    
- (void)didContainerFrameChanged:(NSNotification*)notification{
    // TODO: Find the way to get scrollView from IDESourceCodeEditor class.
    // Now it is assumed that container view has the scrollView at index 0 of subviews.
    NSView* container = [notification object];
    [self layoutStatus:container];
     
}
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
}

@end
