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

@interface XVimQuickFixTextView : NSTextView {
    CGFloat _quickFixEmWidthPixels;
}
@property (readonly) CGFloat emWidth;
@end

@implementation XVimQuickFixView
@dynamic textView;
@dynamic colWidth;

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

-(void)setString:(NSString*)str withPrompt:(NSString*)prompt
{
    NSDictionary* quickFixTrailingAttributes = [ NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSColor greenColor], NSForegroundColorAttributeName
                                                    , nil];
    NSAttributedString* quickFixTrailingPrompt = [[ NSAttributedString alloc] initWithString:prompt attributes:quickFixTrailingAttributes ];
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:str attributes:[self.textView typingAttributes]];
    [[self.textView textStorage ] setAttributedString:attrStr ];
    [self.textView setTypingAttributes:quickFixTrailingAttributes];
    [[self.textView textStorage] appendAttributedString:quickFixTrailingPrompt ];
    [quickFixTrailingPrompt release];
    [attrStr release];
}

-(NSTextView*)textView
{
    return [ self documentView];
}

-(NSUInteger)colWidth
{
    return NSWidth([ self.textView bounds ])/ [(XVimQuickFixTextView*)[self textView] emWidth];
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}
@end
static const unichar USEFUL_KEYS[]={NSUpArrowFunctionKey,NSDownArrowFunctionKey,NSPageUpFunctionKey,NSPageDownFunctionKey, 0};

@implementation XVimQuickFixTextView
@dynamic emWidth;


-(CGFloat)emWidth
{
    return _quickFixEmWidthPixels ;
}

-(void)setFont:(NSFont *)obj
{
    NSSize emSize = [ @"m" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:obj, NSFontAttributeName, nil]];
    _quickFixEmWidthPixels = emSize.width ;
    [super setFont:obj];
}

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
