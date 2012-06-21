#import "XVimSourceView.h"
#import "NSString+VimHelper.h"
#import "Logger.h"

@interface XVimSourceView() {
	__weak NSTextView *_view;
}
@end

@implementation XVimSourceView

- (id)initWithView:(NSView*)view
{
	if (self = [super init])
	{
		_view = (NSTextView*)view;
	}
	return self;
}

- (NSView*)view
{
	return _view;
}
    
- (NSString *)string
{
	return [_view string];
}


////////////////
// Scrolling  //
////////////////
#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

- (void)pageUp
{
	[_view pageUp:self];
}

- (void)pageDown
{
	[_view pageDown:self];
}

- (NSUInteger)lineUp:(NSUInteger)index count:(NSUInteger)count
{ // C-y
  [_view scrollLineUp:self];
  NSRect visibleRect = [[_view enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[_view textContainer]];
  NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
  if (relativeInsertionPoint.y > visibleRect.size.height) {
    [_view moveUp:self];
    NSPoint newPoint = [[_view layoutManager] boundingRectForGlyphRange:[_view selectedRange] inTextContainer:[_view textContainer]].origin;
    index = [[_view layoutManager] glyphIndexForPoint:newPoint inTextContainer:[_view textContainer]];
  }
  return index;
}

- (NSUInteger)lineDown:(NSUInteger)index count:(NSUInteger)count
{ // C-e
  [_view scrollLineDown:self];
  NSRect visibleRect = [[_view enclosingScrollView] contentView].bounds;
  NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:[_view textContainer]];
  if (currentInsertionRect.origin.y < visibleRect.origin.y) {
    [_view moveDown:self];
    NSPoint newPoint = NSMakePoint(currentInsertionRect.origin.x, visibleRect.origin.y);
    index = [[_view layoutManager] glyphIndexForPoint:newPoint inTextContainer:[_view textContainer]];
  }
  return index;
}

- (NSUInteger)halfPageScrollHelper:(NSUInteger)index count:(NSInteger)count
{
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat halfSize = visibleRect.size.height/2.0f;
    
    CGFloat scrollSize = halfSize*count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize ); // This may be beyond the beginning or end of document (intentionally)
    
    // Cursor position relative to left-top origin shold be kept after scroll ( Exception is when it scrolls beyond the beginning or end of document)
    NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:container];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    NSUInteger cursorIndexAfterScroll= [[_view layoutManager] glyphIndexForPoint:cursorAfterScroll inTextContainer:container fractionOfDistanceThroughGlyph:NULL];
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(cursorIndexAfterScroll,0) inTextContainer:container];
    NSPoint relativeInsertionPointAfterScroll = XVimSubPoint(insertionRectAfterScroll.origin, scrollPoint);
    CGFloat heightDiff = relativeInsertionPointAfterScroll.y - relativeInsertionPoint.y;
    scrollPoint.y += heightDiff;
    // Prohibit scroll beyond the bounds of document
    if( scrollPoint.y > [[scrollView documentView] frame].size.height - visibleRect.size.height ){
        scrollPoint.y = [[scrollView documentView] frame].size.height - visibleRect.size.height ;
    } else if (scrollPoint.y < 0.0) {
      scrollPoint.y = 0.0;
    }
  
    [[scrollView contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
	
	return cursorIndexAfterScroll;
}

- (NSUInteger)halfPageDown:(NSUInteger)index count:(NSUInteger)count
{
  return [self halfPageScrollHelper:index count:(NSInteger)count];
}

- (NSUInteger)halfPageUp:(NSUInteger)index count:(NSUInteger)count
{
  return [self halfPageScrollHelper:index count:-(NSInteger)count];
}

- (NSUInteger)scrollBottom:(NSNumber*)count
{ // zb / z-
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
    bottom.y -= NSHeight([[scrollView contentView] bounds]);
    if( bottom.y < 0.0 ){
        bottom.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:bottom];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollCenter:(NSNumber*)count
{ // zz / z.
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint center = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    center.y -= NSHeight([[scrollView contentView] bounds]) / 2.0f;
    if( center.y < 0.0 ){
        center.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:center];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollTop:(NSNumber*)count
{ // zt / z<CR>
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (void)scrollTo:(NSUInteger)location
{
	BOOL isBlankLine = 
		(location == [[self string] length] || isNewLine([[self string] characterAtIndex:location])) &&
		(location == 0 || isNewLine([[self string] characterAtIndex:location-1]));

    NSRange characterRange;
    characterRange.location = location;
    characterRange.length = isBlankLine ? 0 : 1;
    
    // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
    // to the appropriate glyph due to non contiguous layout
    NSRange glyphRange = [[_view layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
    [[_view layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
    
    NSTextContainer *container = [_view textContainer];
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:container];

    CGFloat glyphLeft = NSMidX(glyphRect) - NSWidth(glyphRect) / 2.0f;
    CGFloat glyphRight = NSMidX(glyphRect) + NSWidth(glyphRect) / 2.0f;

    NSRect contentRect = [[scrollView contentView] bounds];
    CGFloat viewLeft = contentRect.origin.x;
    CGFloat viewRight = contentRect.origin.x + NSWidth(contentRect);

    NSPoint scrollPoint = contentRect.origin;
    if (glyphRight > viewRight){
        scrollPoint.x = glyphLeft - NSWidth(contentRect) / 2.0f;
    }else if (glyphLeft < viewLeft){
        scrollPoint.x = glyphRight - NSWidth(contentRect) / 2.0f;
    }

    CGFloat glyphBottom = NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f;
    CGFloat glyphTop = NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f;

    CGFloat viewTop = contentRect.origin.y;
    CGFloat viewBottom = contentRect.origin.y + NSHeight(contentRect);

    if (glyphTop < viewTop){
        if (viewTop - glyphTop > NSHeight(contentRect)){
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphTop;
        }
    }else if (glyphBottom > viewBottom){
        if (glyphBottom - viewBottom > NSHeight(contentRect)) {
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphBottom - NSHeight(contentRect);
        }
    }

    scrollPoint.x = MAX(0, scrollPoint.x);
    scrollPoint.y = MAX(0, scrollPoint.y);

    [[scrollView  contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (NSUInteger)cursorBottom:(NSNumber*)count
{ // L
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height - NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorCenter:(NSNumber*)count
{ // M
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:center], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorTop:(NSNumber*)count
{ // H
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = [[scrollView contentView] bounds].origin;
    top.y += NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:top], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)glyphIndexForPoint:(NSPoint)point
{
	NSUInteger glyphIndex = [[_view layoutManager] glyphIndexForPoint:point inTextContainer:[_view textContainer]];
	return glyphIndex;
}

- (NSRect)boundingRectForGlyphIndex:(NSUInteger)glyphIndex
{
	NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[_view textContainer]];
	return glyphRect;
}

- (void)deleteText
{
	[_view delete:self];
}

- (void)cutText
{
	[_view cut:self];
}

- (void)copyText
{
	[_view copy:self];
}

- (void)moveUp
{
	[_view moveUp:self];
}

- (void)moveDown
{
	[_view moveDown:self];
}

- (void)moveForward
{
	[_view moveForward:self];
}

- (void)moveForwardAndModifySelection
{
	[_view moveForwardAndModifySelection:self];
}

- (void)moveBackward
{
	[_view moveBackward:self];
}

- (void)moveBackwardAndModifySelection
{
	[_view moveBackwardAndModifySelection:self];
}
	 
- (void)moveToBeginningOfLine
{
	[_view moveToBeginningOfLine:self];
}

- (void)moveToEndOfLine
{
	[_view moveToEndOfLine:self];
}

- (void)deleteForward
{
	[_view deleteForward:self];
}

- (void)insertText:(NSString*)text
{
	[_view insertText:text];
}

- (void)insertText:(NSString*)text replacementRange:(NSRange)range
{
	[_view insertText:text replacementRange:range];
}

- (void)insertNewline
{
	[_view insertNewline:self];
}

- (void)undo
{
	[[_view undoManager] undo];
}

- (void)redo
{
	[[_view undoManager] redo];
}

- (NSColor*)insertionPointColor
{
	return [_view insertionPointColor];
}

- (void)showFindIndicatorForRange:(NSRange)range
{
	[_view showFindIndicatorForRange:range];
}

- (NSRange)selectedRange
{
	return [_view selectedRange];
}

- (void)setSelectedRange:(NSRange)range
{
	[_view setSelectedRange:range];
}

@end