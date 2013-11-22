//
//  XVimView.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <objc/runtime.h>
#import "XVim.h"
#import "XVimView.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "NSObject+XVimAdditions.h"
#import "NSTextView+VimOperation.h"
#import "XVimOptions.h"
#import "XVimSearch.h"
#import "Utils.h"

@interface XVimView ()

- (NSRect)_glyphRectAtIndex:(NSUInteger)index length:(NSUInteger)length;

@end

// disgusting copy, get rid of it eventually
@interface NSTextView(VimOperationPrivate)
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState; // update self's properties with our variables
- (NSArray*)xvim_selectedRanges;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)xvim_indentCharacterRange:(NSRange)range;
- (NSRange)xvim_search:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward;
- (void)xvim_swapCaseForRange:(NSRange)range;
- (void)xvim_registerInsertionPointForUndo;
- (void)xvim_registerIndexForUndo:(NSUInteger)index;
@end
static char const * const XVIM_KEY_VIEW = "xvim_view";

@implementation NSTextView (XVimView)

+ (void)xvim_initialize
{
    if (self == [NSTextView class]) {
        DEBUG_LOG("Swizzling NSTextView");

#define swizzle(sel) \
        [self xvim_swizzleInstanceMethod:@selector(sel) with:@selector(xvim_##sel)]

        swizzle(dealloc);

        swizzle(setSelectedRanges:affinity:stillSelecting:);
        swizzle(selectAll:);
        swizzle(paste:);
        swizzle(delete:);
        swizzle(keyDown:);
        swizzle(mouseDown:);
        swizzle(drawRect:);
        swizzle(_drawInsertionPointInRect:color:);
        swizzle(drawInsertionPointInRect:color:turnedOn:);
        swizzle(didChangeText);
        swizzle(viewDidMoveToSuperview);
        swizzle(observeValueForKeyPath:ofObject:change:context:);
    }

#undef swizzle
}

- (XVimView *)xvim_view
{
    return objc_getAssociatedObject(self, XVIM_KEY_VIEW);
}

- (XVimView *)xvim_makeXVimViewInWindow:(XVimWindow *)window
{
    return [[[XVimView alloc] initWithView:self window:window] autorelease];
}

- (void)xvim_setupForXVimView:(XVimView *)view
{
    if (!self.xvim_view) {
        [XVim.instance.options addObserver:self forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.options addObserver:self forKeyPath:@"ignorecase" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [XVim.instance.searcher addObserver:self forKeyPath:@"lastSearchString" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    objc_setAssociatedObject(self, XVIM_KEY_VIEW, view, OBJC_ASSOCIATION_RETAIN);
}

- (void)xvim_dealloc
{
    if (self.xvim_view) {
        @try {
            [XVim.instance.options removeObserver:self forKeyPath:@"hlsearch"];
            [XVim.instance.options removeObserver:self forKeyPath:@"ignorecase"];
            [XVim.instance.searcher removeObserver:self forKeyPath:@"lastSearchString"];
        }
        @catch (NSException* exception){
            ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
            [Logger logStackTrace:exception];
        }
    }
    [self xvim_dealloc];
}


- (void)xvim_setSelectedRanges:(NSArray *)ranges
                      affinity:(NSSelectionAffinity)affinity
                stillSelecting:(BOOL)flag
{
    [self xvim_setSelectedRanges:ranges affinity:affinity stillSelecting:flag];
    if (self.xvim_view && !XVim.instance.disabled) {
        [self xvim_syncStateFromView];
    }
}

- (void)xvim_selectAll:(id)sender
{
    [self xvim_selectAll:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_paste:(id)sender
{
    [self xvim_paste:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_delete:(id)sender
{
    [self xvim_delete:sender];
    if (!XVim.instance.disabled) {
        [self.xvim_view.window syncEvaluatorStack];
    }
}

- (void)xvim_keyDown:(NSEvent *)theEvent
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim_keyDown:theEvent];
    }

    @try {
        TRACE_LOG(@"Event:%@, XVimNotation:%@", theEvent.description, XVimKeyNotationFromXVimString([theEvent toXVimString]));
        if ([window handleKeyEvent:theEvent]) {
            [self updateInsertionPointStateAndRestartTimer:YES];
            return;
        }
        // Call Original keyDown:
        [self xvim_keyDown:theEvent];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_mouseDown:(NSEvent *)theEvent
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim_mouseDown:theEvent];
    }

    @try {
        TRACE_LOG(@"Event:%@", theEvent.description);


        // When mouse down, NSTextView ( base in this case) takes the control of event loop internally
        // and the method call above does not return immidiately and block until mouse up. mouseDragged: method is called from inside it but
        // it never calls mouseUp: event. After mouseUp event is handled internally it returns the control.
        // So the code here is executed AFTER mouseUp event is handled.
        // At this point NSTextView changes its selectedRange so we usually have to sync XVim state.

        // TODO: To make it simple we should forward mouse events
        //       to handleKeyStroke as a special key stroke
        //       and the key stroke should be handled by the current evaluator.

        [self xvim_mouseDown:theEvent];
        [window syncEvaluatorStack];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_drawRect:(NSRect)dirtyRect
{
    if (XVim.instance.disabled || !self.xvim_view) {
        return [self xvim_drawRect:dirtyRect];
    }

    @try {
        if (XVim.instance.options.hlsearch) {
            XVimMotion *lastSearch = [XVim.instance.searcher motionForRepeatSearch];

            if (nil != lastSearch.regex) {
                [self xvim_updateFoundRanges:lastSearch.regex withOption:lastSearch.option];
            }
        } else {
            [self xvim_clearHighlightText];
        }

        [self xvim_drawRect:dirtyRect];

        if (self.selectionMode != XVIM_VISUAL_NONE) {
            // NSTextView does not draw insertion point when selecting text.
            // We have to draw insertion point by ourselves.
            NSRect glyphRect = [self.xvim_view _glyphRectAtIndex:self.insertionPoint length:1];
            [[[self insertionPointColor] colorWithAlphaComponent:0.5] set];
            NSRectFillUsingOperation(glyphRect, NSCompositeSourceOver);
        }
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

// Drawing Caret
- (void)xvim__drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor
{
    XVimWindow *window = self.xvim_view.window;

    if (!window || XVim.instance.disabled) {
        return [self xvim__drawInsertionPointInRect:aRect color:aColor];
    }

    @try {
        // We do not call original _darawInsertionPointRect here
        // Because it uses NSRectFill to draw the caret which overrides the character entirely.
        // We want some tranceparency for the caret.

        // Call our drawing method
        [window drawInsertionPointInRect:aRect color:aColor];

    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag
{
    [self xvim_drawInsertionPointInRect:rect color:color turnedOn:flag];

    if (!flag && self.xvim_view && !XVim.instance.disabled) {
        // Then tell the view to redraw to clear a caret.
        [self setNeedsDisplay:YES];
    }
}

- (void)xvim_didChangeText
{
    if (self.xvim_view && !XVim.instance.disabled) {
        [self setNeedsUpdateFoundRanges:YES];
    }
    [self xvim_didChangeText];
}

- (void)xvim_viewDidMoveToSuperview
{
    if (!self.xvim_view || XVim.instance.disabled) {
        return [self xvim_viewDidMoveToSuperview];
    }

    @try {
        // Hide scroll bars according to options
        [self xvim_viewDidMoveToSuperview];
        [self.enclosingScrollView setPostsBoundsChangedNotifications:YES];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                             change:(NSDictionary *)change  context:(void *)context
{
	if ([@[ @"ignorecase", @"hlsearch", @"lastSearchString"] containsObject:keyPath]) {
        [self setNeedsUpdateFoundRanges:YES];
        [self setNeedsDisplayInRect:self.visibleRect avoidAdditionalLayout:YES];
    }
}

@end

@implementation XVimView {
    NSTextView *__unsafe_unretained _textView;
}
@synthesize window = _window;
@synthesize textView = _textView;

+ (void)initialize
{
    if (self == [XVimView class]) {
        [NSTextView xvim_initialize];
    }
}

- (instancetype)initWithView:(NSTextView *)view window:(XVimWindow *)window
{
    if ((self = [super init])) {
        DEBUG_LOG("View %p created for %@", self, view);

        _textView = view;
        _window   = [window retain];
        [view xvim_setupForXVimView:self];
        [self _xvim_statusChanged:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_xvim_statusChanged:)
                                                     name:XVimEnabledStatusChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    DEBUG_LOG("View %p deleted", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_window release];
    [super dealloc];
}

- (void)_xvim_statusChanged:(id)sender
{
    if (!XVim.instance.disabled) {
        [_textView xvim_syncStateFromView];
    }
    [_textView setNeedsDisplay:YES];
}

#pragma mark *** Drawing ***

- (NSRect)_glyphRectAtIndex:(NSUInteger)index length:(NSUInteger)length
{
    if (length && index + length >= _textView.textStorage.length) {
        // When the index is EOF the range to specify here can not be grater than 0.
        // If it is greater than 0 it returns (0,0) as a glyph rect.
        length = 0;
    }
    return [_textView.layoutManager boundingRectForGlyphRange:NSMakeRange(index, length)
                                              inTextContainer:_textView.textContainer];
}

- (NSUInteger)_glyphHeightAtIndex:(NSUInteger)index
{
    return NSHeight([self _glyphRectAtIndex:index length:0]);
}

- (NSUInteger)_lineNumberAtPoint:(NSPoint)point
{
    NSUInteger index;

    index = [_textView.enclosingScrollView.documentView characterIndexForInsertionAtPoint:point];
    return [_textView.textStorage.xvim_buffer lineNumberAtIndex:index];
}

- (NSUInteger)lineNumberInScrollView:(CGFloat)ratio offset:(NSInteger)offset
{
    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSRect visibleRect = scrollView.contentView.bounds;
    NSPoint point = visibleRect.origin;
    CGFloat glyphHeight = [self _glyphHeightAtIndex:_textView.insertionPoint];

    NSInteger minLine, line, maxLine;

    minLine  = (NSInteger)[self _lineNumberAtPoint:point];
    point.y += ratio * (NSHeight(visibleRect) - glyphHeight);
    line     = (NSInteger)[self _lineNumberAtPoint:point];
    point.y  = NSMaxY(visibleRect) - glyphHeight;
    maxLine  = (NSInteger)[self _lineNumberAtPoint:point];

    return (NSUInteger)MIN(maxLine, MAX(minLine, line + offset));
}

- (NSUInteger)_glyphIndexForPoint:(NSPoint)point
{
    return [_textView.layoutManager glyphIndexForPoint:point inTextContainer:_textView.textContainer];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color
                     heightRatio:(CGFloat)heightRatio
                      widthRatio:(CGFloat)widthRatio
                           alpha:(CGFloat)alpha
{
    NSUInteger glyphIndex = [_textView insertionPoint];
	NSRect glyphRect = [self _glyphRectAtIndex:glyphIndex length:1];

	[[color colorWithAlphaComponent:alpha] set];
	rect.size.width = rect.size.height/2;
	if (glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width)  {
		rect.size.width = glyphRect.size.width;
    }

	rect.origin.y += (1 - heightRatio) * rect.size.height;
	rect.size.height *= heightRatio;
    rect.size.width *= widthRatio;

	NSRectFillUsingOperation(rect, NSCompositeSourceOver);
}

#pragma mark *** Scrolling ***

- (void)_lineUp:(NSUInteger)index count:(NSUInteger)count
{
    [_textView scrollLineUp:_textView];

    NSRect visibleRect = _textView.enclosingScrollView.contentView.bounds;
    NSRect cursorRect  = [self _glyphRectAtIndex:index length:0];
    if (NSMaxY(cursorRect) > NSMaxY(visibleRect)) {
        [_textView moveUp:self];
    }
}

- (void)scrollLineBackward:(NSUInteger)count
{
    [self _lineUp:_textView.insertionPoint count:count];
}

- (void)_lineDown:(NSUInteger)index count:(NSUInteger)count
{
    [_textView scrollLineDown:_textView];

    NSRect visibleRect = _textView.enclosingScrollView.contentView.bounds;
    NSRect cursorRect  = [self _glyphRectAtIndex:index length:0];
    if (NSMinY(cursorRect) < NSMinY(visibleRect)) {
        [_textView moveDown:_textView];
    }
}

- (void)scrollLineForward:(NSUInteger)count
{
    [self _lineDown:_textView.insertionPoint count:count];
}

- (void)_scroll:(CGFloat)ratio count:(NSUInteger)count
{
    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSClipView   *clipView   = scrollView.contentView;
    XVimBuffer   *buffer     = _textView.textStorage.xvim_buffer;

    NSRect  visibleRect = clipView.bounds;
    CGFloat scrollSize  = NSHeight(visibleRect) * ratio * count;
    // This may be beyond the beginning or end of document (intentionally)
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize);

    // Cursor position relative to left-top origin shold be kept after scroll
    // (Exception is when it scrolls beyond the beginning or end of document)

    NSRect  currentInsertionRect = [self _glyphRectAtIndex:_textView.insertionPoint length:1];
    NSPoint relativeInsertionPoint = SubPoint(currentInsertionRect.origin, visibleRect.origin);

    // Cursor Position after scroll
    NSPoint cursorAfterScroll = AddPoint(scrollPoint, relativeInsertionPoint);

    // Nearest character index to the cursor position after scroll
    // TODO: consider blank-EOF line. Xcode does not return blank-EOF index with following method...
    NSUInteger cursorIndexAfterScroll = [self _glyphIndexForPoint:cursorAfterScroll];

    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [self _glyphRectAtIndex:cursorIndexAfterScroll length:1];
    NSPoint relativeInsertionPointAfterScroll = SubPoint(insertionRectAfterScroll.origin, scrollPoint);
    CGFloat maxScrollY = NSHeight([scrollView.documentView frame]) - NSHeight(visibleRect);

    scrollPoint.y += relativeInsertionPointAfterScroll.y - relativeInsertionPoint.y;
    if (scrollPoint.y > maxScrollY) {
        // Prohibit scroll beyond the bounds of document
        scrollPoint.y = maxScrollY;
    } else if (scrollPoint.y < 0.0) {
        scrollPoint.y = 0.0;
    }

    [[scrollView contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];

    cursorIndexAfterScroll = [buffer firstNonblankInLineAtIndex:cursorIndexAfterScroll allowEOL:YES];
    [_textView xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [_textView xvim_syncState];
}

- (void)scrollPageForward:(NSUInteger)count
{
	[self _scroll:1.0 count:count];
}

- (void)scrollPageBackward:(NSUInteger)count
{
	[self _scroll:-1.0 count:count];
}

- (void)scrollHalfPageForward:(NSUInteger)count
{
	[self _scroll:0.5 count:count];
}

- (void)scrollHalfPageBackward:(NSUInteger)count
{
	[self _scroll:-0.5 count:count];
}

- (void)_scrollCommon_moveCursorPos:(NSUInteger)lineNumber
                              ratio:(CGFloat)ratio
                      firstNonblank:(BOOL)fnb
{
    XVimBuffer *buffer = _textView.textStorage.xvim_buffer;
    NSUInteger pos = _textView.insertionPoint;

    if (lineNumber) {
        if ((pos = [buffer indexOfLineNumber:lineNumber]) == NSNotFound) {
            pos = buffer.length;
        }
    }
    if (fnb) {
        pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
    }
    [_textView xvim_moveCursor:pos preserveColumn:NO];
    [_textView xvim_syncState];

    NSRect glyphRect = [self _glyphRectAtIndex:_textView.insertionPoint length:0];

    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSClipView *clipView = scrollView.contentView;

    NSPoint point  = NSMakePoint(0., NSMaxY(glyphRect));
    CGFloat deltay = ratio * NSHeight(_textView.enclosingScrollView.contentView.bounds);
    point.y = point.y > deltay ? point.y - deltay : 0.;

    [clipView scrollToPoint:point];
    [scrollView reflectScrolledClipView:clipView];
}

- (void)scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb  // zb / z-
{
    [self _scrollCommon_moveCursorPos:lineNumber ratio:1. firstNonblank:fnb];
}

- (void)scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb // zz / z.
{
    [self _scrollCommon_moveCursorPos:lineNumber ratio:.5 firstNonblank:fnb];
}

- (void)scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb // zt / z<CR>
{
    [self _scrollCommon_moveCursorPos:lineNumber ratio:0. firstNonblank:fnb];
}

- (void)scrollTo:(NSUInteger)location
{
    // Update: I do not know if we really need Following block.
    //         It looks that they need it to call ensureLayoutForGlyphRange but do not know when it needed
    //         What I changed was the way calc "glyphRec". Not its using [self boundingRectForGlyphIndex] which coniders
    //         text folding when calc the rect.
    /*
     BOOL isBlankline =
     (location == [[self string] length] || isNewline([[self string] characterAtIndex:location])) &&
     (location == 0 || isNewline([[self string] characterAtIndex:location-1]));

     NSRange characterRange;
     characterRange.location = location;
     characterRange.length = isBlankline ? 0 : 1;

     // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
     // to the appropriate glyph due to non contiguous layout
     NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
     [[self layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
     */

    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSClipView   *clipView   = scrollView.contentView;

    NSRect  glyphRect   = [self _glyphRectAtIndex:location length:1];
    CGFloat glyphLeft   = NSMinX(glyphRect);
    CGFloat glyphRight  = NSMaxX(glyphRect);
    CGFloat glyphBottom = NSMaxY(glyphRect);
    CGFloat glyphTop    = NSMinY(glyphRect);

    NSRect  contentRect = clipView.bounds;
    CGFloat viewLeft    = NSMinX(contentRect);
    CGFloat viewRight   = NSMaxX(contentRect);
    CGFloat viewTop     = NSMinY(contentRect);
    CGFloat viewBottom  = NSMaxY(contentRect);

    NSPoint scrollPoint = contentRect.origin;
    if (glyphRight > viewRight) {
        scrollPoint.x = glyphLeft - NSWidth(contentRect) / 2.;
    } else if (glyphLeft < viewLeft) {
        scrollPoint.x = glyphRight - NSWidth(contentRect) / 2.;
    }
    scrollPoint.x = MAX(0, scrollPoint.x);

    if (glyphTop < viewTop) {
        if (viewTop - glyphTop > NSHeight(contentRect)){
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.;
        } else {
            scrollPoint.y = glyphTop;
        }
    } else if (glyphBottom > viewBottom) {
        if (glyphBottom - viewBottom > NSHeight(contentRect)) {
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.;
        } else {
            scrollPoint.y = glyphBottom - NSHeight(contentRect);
        }
    }
    scrollPoint.y = MAX(0, scrollPoint.y);

    [clipView scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:clipView];
}

@end
