#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "DVTKit.h"
#import "NSString+VimHelper.h"
#import "Logger.h"

/*
 * XVimSourceView represent a text view used in XVim.
 * This is a layer above the actuall text view used in Xcode(DVTSourceTextView)
 * XVimSourceView keeps consistensy between VIM state and DVTSourceTextView.
 * All the evaluators(event handlers) send a request to XVimSourceView via XVimWindow
 * and complete its event.
 * So evaluators should NOT directly operate on DVTSourceTextView.
 */

#define LOG_STATE TRACE_LOG(@"_view.range loc:%d len:%d | mode %d | ip %d | begin %d | areaS %d | areaE %d", \
                            [_view selectedRange].location, \
                            [_view selectedRange].length,  \
                            _selectionMode,            \
                            _insertionPoint,           \
                            _selectionBegin,           \
                            _selectionAreaStart,       \
                            _selectionAreaEnd)


@interface XVimSourceView() {
	__weak NSTextView *_view;
}
- (NSRange)_currentSelection;
- (void)_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (NSUInteger)_getPositionFrom:(NSUInteger)current Motion:(XVimMotion*)motion;
@end

@implementation XVimSourceView
@synthesize insertionPoint = _insertionPoint;
@synthesize selectionBegin = _selectionBegin;
@synthesize selectionAreaStart = _selectionAreaStart;
@synthesize selectionAreaEnd = _selectionAreaEnd;
@synthesize selectionMode = _selectionMode;
@synthesize preservedColumn = _preservedColumn;

- (id)initWithView:(NSView*)view {
	if (self = [super init]) {
		_view = (NSTextView*)view;
        _selectionBegin = NSNotFound;
        _selectionAreaStart = NSNotFound;
        _selectionAreaEnd = NSNotFound;
        _selectionMode = MODE_VISUAL_NONE;
        _insertionPoint = [_view selectedRange].location + [_view selectedRange].length;
	}
	return self;
}

////////////////
// Properties //
////////////////
- (NSView*)view {
	return _view;
}
    
- (NSString *)string {
	return [_view string];
}

- (NSArray*)selectedRanges{
    return [_view selectedRanges];
}

- (NSUInteger)insertionColumn{
    return [(XVimSourceView*)_view columnNumber:_insertionPoint];
}

- (NSUInteger)insertionLine{
    return [(XVimSourceView*)_view lineNumber:_insertionPoint];
}

- (NSRange)_currentSelection{
    if( _selectionMode == MODE_VISUAL_NONE){
        return NSMakeRange(_insertionPoint, 1);
    }else{
        return NSMakeRange(_selectionAreaStart, _selectionAreaStart);
    }
}

//////////////////
// Operations   //
//////////////////
- (void)moveCursor:(NSUInteger)pos{
    [self _moveCursor:pos preserveColumn:NO];
}

- (NSUInteger)_getPositionFrom:(NSUInteger)current Motion:(XVimMotion*)motion{
    NSUInteger nextPos = current;
    XVimWordInfo info;
    switch (motion.motion) {
        case MOTION_FORWARD:
            nextPos = [self next:current count:motion.count option:motion.option];
            break;
        case MOTION_BACKWARD:
            nextPos = [self prev:_insertionPoint count:motion.count option:motion.option ];
            break;
        case MOTION_WORD_FORWARD:
            nextPos = [self wordsForward:current count:motion.count option:motion.option info:&info];
            break;
        case MOTION_WORD_BACKWARD:
            nextPos = [self wordsBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_FORWARD:
            nextPos = [self endOfWordsForward:current count:motion.count option:motion.option];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            nextPos = [self endOfWordsBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_LINE_FORWARD:
            nextPos = [self nextLine:current column:_preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_LINE_BACKWARD:
            nextPos = [self prevLine:current column:_preservedColumn count:motion.count option:motion.option];
            break;
        case MOTION_BEGINNING_OF_LINE:
            nextPos = [self firstOfLine:current];
            if( nextPos == NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_END_OF_LINE:
            nextPos = [self endOfLine:current];
            if( nextPos != NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_SENTENCE_FORWARD:
            nextPos = [self sentencesForward:current count:motion.count option:motion.option];
            break;
        case MOTION_SENTENCE_BACKWARD:
            nextPos = [self sentencesBackward:current count:motion.count option:motion.option];
            break;
        case MOTION_PARAGRAPH_FORWARD:
            nextPos = [self paragraphsForward:current count:motion.count option:motion.option];
            if( nextPos != NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_PARAGRAPH_BACKWARD:
            nextPos = [self paragraphsBackward:current count:motion.count option:motion.option];
            if( nextPos != NSNotFound){
                nextPos = current;
            }
            break;
        case MOTION_NEXT_CHARACTER:
            break;
        case MOTION_PREV_CHARACTER:
            break;
        case MOTION_POSITION:
            nextPos = motion.position;
            break;
    }
    return nextPos;
}

- (void)_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve{
    if( pos > [_view string].length){
        DEBUG_LOG(@"Position specified exceeds the length of the text");
        pos = [_view string].length;
    }
    
    _insertionPoint = pos;
    if (_selectionMode == MODE_VISUAL_NONE) { // its not in selecting mode
        _selectionBegin = NSNotFound;
        _selectionAreaStart = NSNotFound;
        _selectionAreaEnd = NSNotFound;
        [_view setSelectedRange:NSMakeRange(_insertionPoint,0)];
    }
    else { // its in selecting mode
        if( _selectionMode == MODE_CHARACTER){
            _selectionAreaStart = MIN(_insertionPoint,_selectionBegin);
            _selectionAreaEnd = MAX(_insertionPoint,_selectionBegin);
            [_view setSelectedRange:NSMakeRange(_selectionAreaStart,_selectionAreaEnd-_selectionAreaStart)];
        }else if(_selectionMode == MODE_LINE ){
            NSUInteger min = MIN(_insertionPoint,_selectionBegin);
            NSUInteger max = MAX(_insertionPoint,_selectionBegin);
            _selectionAreaStart = [self firstOfLine:min];
            _selectionAreaEnd = [self tailOfLine:max];
            [_view setSelectedRange:NSMakeRange(_selectionAreaStart,_selectionAreaEnd-_selectionAreaStart)];
        }else if( _selectionMode == MODE_BLOCK){
            // Find Out Block Rect
            // We have to compare the line number and column number of start and end postion of selection.
            NSUInteger columnBegin = [self columnNumber:_selectionBegin];
            NSUInteger lineBegin = [self lineNumber:_selectionBegin];
            NSUInteger columnEnd = [self columnNumber:_insertionPoint];
            NSUInteger lineEnd= [self lineNumber:_insertionPoint];
            
            // Define the block as a rect by line and column number
            NSUInteger top = MIN(lineBegin,lineEnd);
            NSUInteger bottom = MAX(lineBegin,lineEnd);
            NSUInteger left = MIN(columnBegin, columnEnd);
            NSUInteger right = MAX(columnBegin, columnEnd);
            
            // Set _selectionAreaStart as left-top position of the block. But we do not use them in block selection
            _selectionAreaStart = [self positionAtLineNumber:top column:left];
            // Set _selectionAreaEnd as right-bottom position of the block. But we do not use them in block selection
            _selectionAreaEnd = [self positionAtLineNumber:bottom column:right];
            
            // For each line select the area (columnBegi,columnEnd) unless it does not excceds tail of line.
            // NASelectionArray seems to be definded in Xcode but can't find it in Cocoa library... make it manually.
            // This is an argument of setSelectedRanges method.
            NSRange* ranges = malloc((bottom-top+1) * sizeof(NSRange));
            NSUInteger count = 0;
            for( NSUInteger i = 0; i < bottom-top+1 ; i++ ){
                NSUInteger maxColumn = [self maxColumnAtLineNumber:top+i];
                if( maxColumn != NSNotFound && maxColumn >= left){ // Only when the line has a column inside the rect add the range
                    NSUInteger start = [self positionAtLineNumber:top+i column:left];
                    NSUInteger end = [self positionAtLineNumber:top+i column:right];
                    ranges[count].location = start;
                    ranges[count].length = end - start + 1;
                    count++;
                }
            }
            if( 0 == count ){
                DEBUG_LOG(@"Something wrong. There must be at lease one range in ranges");
            }
            id rangeArray = [[[NSClassFromString(@"NSSelectionArray") alloc] initWithRanges:ranges count:count] autorelease];
            [(DVTSourceTextView*)_view setSelectedRanges:rangeArray affinity:1 stillSelecting:YES];
            free(ranges);
        }
    }
    
    if( !preserve ){
        _preservedColumn = [self columnNumber:_insertionPoint];
    }
    [(DVTSourceTextView*)_view scrollRangeToVisible:NSMakeRange(_insertionPoint,0)];
}

////////// Top level operation interface/////////
- (void)move:(XVimMotion*)motion{
    switch( motion.motion ){
        case MOTION_LINE_BACKWARD:
        case MOTION_LINE_FORWARD:
            [self _moveCursor:[self _getPositionFrom:_insertionPoint Motion:motion] preserveColumn:YES];
            break;
        default:
            [self _moveCursor:[self _getPositionFrom:_insertionPoint Motion:motion] preserveColumn:NO];
            break;
    }
    
}

- (void)delete:(XVimMotion*)motion{
    
}

- (void)deleteLines:(XVimMotion*)motion{
    
}

- (void)yunk:(XVimMotion*)motion{
    
}

- (void)yunkLines:(XVimMotion*)motion{
    
}

- (void)swapCase:(XVimMotion*)motion{

}

- (void)makeLowerCase:(XVimMotion*)motion{
    
}

- (void)makeUpperCase:(XVimMotion*)motion{
    
}

- (void)filter:(XVimMotion*)motion{
    
}

- (void)shiftRight:(XVimMotion*)motion{
    
}

- (void)shiftLeft:(XVimMotion*)motion{
    
}

////////// Premitive Operations ///////////
- (void)moveBack:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self prev:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
    _preservedColumn = [self columnNumber:_insertionPoint];
}

- (void)moveFoward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self next:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
    _preservedColumn = [self columnNumber:_insertionPoint];
}

- (void)moveDown:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self nextLine:_insertionPoint column:_preservedColumn count:count option:opt];
    [self moveCursor:nextPos];
}

- (void)moveUp:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self prevLine:_insertionPoint column:_preservedColumn count:count option:opt];
    [self moveCursor:nextPos];
}

//- (void)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info;

- (void)moveWordsBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self wordsBackward:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
}

- (void)moveSentencesForward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self sentencesForward:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
}

- (void)moveSentencesBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self sentencesBackward:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
}

- (void)moveParagraphsForward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self paragraphsForward:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
}

- (void)moveParagraphsBackward:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSUInteger nextPos = [self paragraphsBackward:_insertionPoint count:count option:opt];
    [self moveCursor:nextPos];
}


// Scrolls
- (void)scrollPageForward:(NSUInteger)count{
    [self pageForward:_insertionPoint count:count];
}

- (void)scrollPageBackward:(NSUInteger)count{
    [self pageBackward:_insertionPoint count:count];
}

- (void)scrollHalfPageForward:(NSUInteger)count{
    [self halfPageForward:_insertionPoint count:count];
}

- (void)scrollHalfPageBackward:(NSUInteger)count{
    [self halfPageBackward:_insertionPoint count:count];
}

- (void)scrollLineForward:(NSUInteger)count{
    [self lineForward:_insertionPoint count:count];
}

- (void)scrollLineBackward:(NSUInteger)count{
    [self lineBackward:_insertionPoint count:count];
}

//
- (void)toggleCase{
    [self toggleCaseForRange:[self _currentSelection]];
}

- (void)upperCase{
    [self upperCaseForRange:[self _currentSelection]];
}

- (void)lowerCase{
    [self lowerCaseForRange:[self _currentSelection]];
}

- (void)toggleCaseForRange:(NSRange)range {
    NSString* text = [self string];
	
	NSMutableString *substring = [[text substringWithRange:range] mutableCopy];
	for (NSUInteger i = 0; i < range.length; ++i) {
		NSRange currentRange = NSMakeRange(i, 1);
		NSString *currentCase = [substring substringWithRange:currentRange];
		NSString *upperCase = [currentCase uppercaseString];
		
		NSRange replaceRange = NSMakeRange(i, 1);
		if ([currentCase isEqualToString:upperCase]){
			[substring replaceCharactersInRange:replaceRange withString:[currentCase lowercaseString]];
		}else{
			[substring replaceCharactersInRange:replaceRange withString:upperCase];
		}	
	}
	
	[self insertText:substring replacementRange:range];
}

- (void)upperCaseForRange:(NSRange)range {
    NSString* s = [self string];
	[self insertText:[[s substringWithRange:range] uppercaseString] replacementRange:range];
}

- (void)lowerCaseForRange:(NSRange)range {
    NSString* s = [self string];
	[self insertText:[[s substringWithRange:range] lowercaseString] replacementRange:range];
}

//////////////////////////////
// Selection (Visual Mode)  //
//////////////////////////////

- (void)startSelection:(VISUAL_MODE)mode{
    //NSAssert(_selectionBegin== NSNotFound, @"beginSelection should be called after endSelection");
    _selectionBegin= _insertionPoint;
    _selectionMode = mode;
    if( [_view selectedRange].length != 0 ){
        _selectionAreaStart = [_view selectedRange].location;
        _selectionBegin = _selectionAreaStart;
        _selectionAreaEnd = [_view selectedRange].length + [_view selectedRange].location;
    }else{
        [self moveCursor:_insertionPoint]; // Update selection;
    }
    TRACE_LOG( @"Selection Started: mode:%d ip:%d begin:%d areaStart:%d areaEnd:%d", _selectionMode, _insertionPoint, _selectionBegin, _selectionAreaStart, _selectionAreaEnd);
}

- (void)endSelection{
    //NSAssert(_selectionBegin!= NSNotFound, @"endSelection should be called after beginSelection");
    _selectionMode = MODE_VISUAL_NONE;
    [self moveCursor:_insertionPoint]; // turn selection off
}

- (void)changeSelectionMode:(VISUAL_MODE)mode{
    if( mode == MODE_VISUAL_NONE){
        [self endSelection];
    }
    _selectionMode = mode;
    [self moveCursor:_insertionPoint];
    return;
}

// Scrolling  //
////////////////
#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

- (void)pageUp {
	[_view pageUp:self];
}

- (void)pageDown {
	[_view pageDown:self];
}

- (NSUInteger)lineUp:(NSUInteger)index count:(NSUInteger)count { // C-y
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

- (NSUInteger)lineDown:(NSUInteger)index count:(NSUInteger)count { // C-e
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

- (NSUInteger)halfPageScrollHelper:(NSUInteger)index count:(NSInteger)count {
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

- (NSUInteger)halfPageDown:(NSUInteger)index count:(NSUInteger)count {
  return [self halfPageScrollHelper:index count:(NSInteger)count];
}

- (NSUInteger)halfPageUp:(NSUInteger)index count:(NSUInteger)count {
  return [self halfPageScrollHelper:index count:-(NSInteger)count];
}

- (NSUInteger)scrollBottom:(NSNumber*)count { // zb / z-
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

- (NSUInteger)scrollCenter:(NSNumber*)count { // zz / z.
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

- (NSUInteger)scrollTop:(NSNumber*)count { // zt / z<CR>
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (void)scrollTo:(NSUInteger)location {
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

- (NSUInteger)cursorBottom:(NSNumber*)count { // L
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height - NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorCenter:(NSNumber*)count { // M
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:center], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorTop:(NSNumber*)count { // H
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = [[scrollView contentView] bounds].origin;
    top.y += NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:top], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)glyphIndexForPoint:(NSPoint)point {
	NSUInteger glyphIndex = [[_view layoutManager] glyphIndexForPoint:point inTextContainer:[_view textContainer]];
	return glyphIndex;
}

- (NSRect)boundingRectForGlyphIndex:(NSUInteger)glyphIndex {
	NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[_view textContainer]];
	return glyphRect;
}

- (void)deleteText {
	[_view delete:self];
}

- (void)cutText {
	[_view cut:self];
}

- (void)copyText {
	[_view copy:self];
}

- (void)moveUp {
	[_view moveUp:self];
}

- (void)moveDown {
	[_view moveDown:self];
}

- (void)moveForward {
    [self move:XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)moveForwardAndModifySelection {
	[_view moveForwardAndModifySelection:self];
}

- (void)moveBackward {
    [self move:XVIM_MAKE_MOTION(MOTION_BACKWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)moveBackwardAndModifySelection {
	[_view moveBackwardAndModifySelection:self];
}
	 
- (void)moveToBeginningOfLine {
    [self move:XVIM_MAKE_MOTION(MOTION_BEGINNING_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)moveToEndOfLine {
    [self move:XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 0)];
}

- (void)deleteForward {
	[_view deleteForward:self];
}

- (void)insertText:(NSString*)text {
	[_view insertText:text];
}

- (void)insertText:(NSString*)text replacementRange:(NSRange)range {
	[_view insertText:text replacementRange:range];
}

- (void)insertNewline {
	[_view insertNewline:self];
}

- (void)undo {
	[[_view undoManager] undo];
}

- (void)redo {
	[[_view undoManager] redo];
}

- (NSColor*)insertionPointColor {
	return [_view insertionPointColor];
}

- (void)showFindIndicatorForRange:(NSRange)range {
	[_view showFindIndicatorForRange:range];
}

- (NSRange)selectedRange {
    LOG_STATE;
    return NSMakeRange(_insertionPoint, 0);
}

- (void)setSelectedRange:(NSRange)range {
    LOG_STATE;
    @try{
        [self moveCursor:range.location];
        //[_view setSelectedRange:range];
        _insertionPoint = range.location + range.length;
    }@catch (NSException *exception) {
        ERROR_LOG(@"main:Caught %@:%@", [exception name], [exception reason]);
    }
    LOG_STATE;
}

@end