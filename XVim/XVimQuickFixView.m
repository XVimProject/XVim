//
//  XVimQuickFixView.m
//  XVim
//
//  Created by Ant on 16/10/2012.
//
//

#import "XVimQuickFixView.h"
#import "Logger.h"
#import "MemoryManagementMacros.h"
#import "DVTKit.h"

NSString* XVimNotificationQuickFixDidComplete = @"XVimNotificationQuickFixDidComplete" ;

@interface XVimQuickFixTextView : NSTextView {
    @public
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
        NSTextView* _quickFixTextView = [[XVimQuickFixTextView alloc] init];
        
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
        [_quickFixTextView setRichText:YES];
        [_quickFixTextView setBackgroundColor:[NSColor redColor]];
        NSMutableParagraphStyle *style = AUTORELEASE([ [NSParagraphStyle defaultParagraphStyle] mutableCopy ]);
        [ style setTabStops:[NSArray array]];
        [ style setDefaultTabInterval:70.0 ];
        [_quickFixTextView setDefaultParagraphStyle:style];
        
        [[_quickFixTextView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[_quickFixTextView textContainer] setWidthTracksTextView:YES];
        // Quickfix
        [self setDocumentView:_quickFixTextView];
        [self _syncConsoleAttributes];
        RELEASE(_quickFixTextView);
    }
    
    return self;
}

-(DVTFontAndColorTheme*)_currentTheme
{
    return [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
}

-(NSFont*)_consoleFont
{
    return [[self _currentTheme] consoleExecutableOutputTextFont];
}

-(NSColor*)_consoleBackgroundColor
{
    return [[self _currentTheme] consoleTextBackgroundColor];
}

-(NSColor*)_consoleForegroundColor
{
    return [[self _currentTheme] consoleDebuggerOutputTextColor];
}

-(void)_syncConsoleAttributes
{
    XVimQuickFixTextView* _quickFixTextView = self.documentView;
    [_quickFixTextView setBackgroundColor:[self _consoleBackgroundColor]];
    NSSize emSize = [ @"m" sizeWithAttributes:@{NSFontAttributeName:[self _consoleFont]}];
    _quickFixTextView->_quickFixEmWidthPixels = emSize.width ;
}

-(void)setString:(NSString*)str withPrompt:(NSString*)prompt
{
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:str
                                                                  attributes:@{NSFontAttributeName:[self _consoleFont]
                                                                               , NSForegroundColorAttributeName:[self _consoleForegroundColor]
                                                                               }];
    NSAttributedString* quickFixTrailingPrompt = [[ NSAttributedString alloc] initWithString:prompt
                                                                                  attributes:@{NSFontAttributeName:[self _consoleFont]
                                                                                               , NSForegroundColorAttributeName:NSColor.greenColor
                                                                                               }];
    [self.textView.textStorage setAttributedString:attrStr];
    [self.textView.textStorage appendAttributedString:quickFixTrailingPrompt ];
    RELEASE(quickFixTrailingPrompt);
    RELEASE(attrStr);
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
