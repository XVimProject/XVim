//
//  XVimQuickFixView.m
//  XVim
//
//  Created by Ant on 16/10/2012.
//
//

#import "XVimQuickFixView.h"

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

@implementation XVimQuickFixTextView

-(void)keyDown:(NSEvent *)theEvent
{
    [[ NSNotificationCenter defaultCenter ] postNotificationName:XVimNotificationQuickFixDidComplete object:[self enclosingScrollView] ];
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
