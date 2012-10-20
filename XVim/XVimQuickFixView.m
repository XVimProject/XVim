//
//  XVimQuickFixView.m
//  XVim
//
//  Created by Ant on 16/10/2012.
//
//

#import "XVimQuickFixView.h"
#import "Logger.h"

NSString* XVimNotificationQuickFixDidComplete = @"XVimNotificationQuickFixDidComplete" ;

@interface XVimQuickFixTextView : NSTextView
@end

@implementation XVimQuickFixView
@dynamic textView;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSSize contentSize = [self contentSize];
        NSTextView* _quickFixTextView = [[XVimQuickFixTextView alloc] initWithFrame:[[self documentView] frame] ];
        
        [self setBorderType:NSNoBorder];
        [self setHasVerticalScroller:YES];
        [self setHasHorizontalScroller:NO];
        [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_quickFixTextView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [_quickFixTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [_quickFixTextView setVerticallyResizable:YES];
        [_quickFixTextView setHorizontallyResizable:NO];
        [_quickFixTextView setAutoresizingMask:NSViewWidthSizable];
        [_quickFixTextView setSelectable:YES];
        [_quickFixTextView setEditable:NO];
        [_quickFixTextView setBackgroundColor:[NSColor redColor]];
        NSMutableParagraphStyle *style = [[ [NSParagraphStyle defaultParagraphStyle] mutableCopy ] autorelease];
        [ style setTabStops:[NSArray array]];
        [ style setDefaultTabInterval:70.0 ];
        [_quickFixTextView setDefaultParagraphStyle:style];
        [_quickFixTextView setTypingAttributes:[NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName]];
        
        [[_quickFixTextView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[_quickFixTextView textContainer] setWidthTracksTextView:YES];
        // Quickfix
        [self setDocumentView:_quickFixTextView];
        [_quickFixTextView release];
    }
    
    return self;
}

-(NSTextView*)textView
{
    return [ self documentView];
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}
@end
static const unichar USEFUL_KEYS[]={NSUpArrowFunctionKey,NSDownArrowFunctionKey,NSPageUpFunctionKey,NSPageDownFunctionKey, 0};

@implementation XVimQuickFixTextView

-(void)keyDown:(NSEvent *)theEvent
{
    // Pass-through keys to scroll up and down. Otherwise notify that we should exit quickfix
    const unichar*i=USEFUL_KEYS;
    unichar keyChar = [[ theEvent characters ] length]>0?[[theEvent characters] characterAtIndex:0]:0;
    for (; *i!=0 && *i!=keyChar; ++i){;}
    if (*i==(unichar)0)
    {
        [[ NSNotificationCenter defaultCenter ] postNotificationName:XVimNotificationQuickFixDidComplete object:[self enclosingScrollView] ];
    }
    else
    {
        [ super keyDown:theEvent];
    }
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(BOOL)resignFirstResponder
{
    [[ NSNotificationCenter defaultCenter ] postNotificationName:XVimNotificationQuickFixDidComplete object:[self enclosingScrollView] ];
    return YES;
}

@end
