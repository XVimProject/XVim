//
//  XVimView.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

// FIXME: layering issue
#if XVIM_XCODE_VERSION == 5
#define __XCODE5__
#endif
#define __USE_DVTKIT__
#import "DVTKit.h"
#import "XVimUndo.h"
#import "NSTextStorage+VimOperation.h"
// END FIXME

#import <objc/runtime.h>
#import "Logger.h"
#import "NSObject+XVimAdditions.h"
#import "NSString+VimHelper.h"
#import "Utils.h"
#import "XVim.h"
#import "XVimMotion.h"
#import "XVimOptions.h"
#import "XVimSearch.h"
#import "XVimView.h"
#import "XVimWindow.h"


@interface XVimView ()
@property (nonatomic, readwrite) BOOL needsUpdateFoundRanges;

- (NSRect)_glyphRectAtIndex:(NSUInteger)index length:(NSUInteger)length;
- (void)_syncStateFromView;

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
        [self.xvim_view _syncStateFromView];
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

    [self xvim_mouseDown:theEvent];

    if (!window || XVim.instance.disabled) {
        return;
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

        [window syncEvaluatorStack];
    }
    @catch (NSException* exception) {
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
}

- (void)xvim_drawRect:(NSRect)dirtyRect
{
    XVimView *xview = self.xvim_view;

    if (XVim.instance.disabled || !xview) {
        return [self xvim_drawRect:dirtyRect];
    }

    @try {
        if (XVim.instance.options.hlsearch) {
            XVimMotion *lastSearch = [XVim.instance.searcher motionForRepeatSearch];

            if (nil != lastSearch.regex) {
                [xview xvim_updateFoundRanges:lastSearch.regex withOption:lastSearch.option];
            }
        } else {
            [xview xvim_clearHighlightText];
        }

        [self xvim_drawRect:dirtyRect];

        if (xview.inVisualMode) {
            // NSTextView does not draw insertion point when selecting text.
            // We have to draw insertion point by ourselves.
            NSRect glyphRect = [xview _glyphRectAtIndex:xview.insertionPoint length:1];
            [[self.insertionPointColor colorWithAlphaComponent:0.5] set];
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
        self.xvim_view.needsUpdateFoundRanges = YES;
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
        self.xvim_view.needsUpdateFoundRanges = YES;
        [self setNeedsDisplayInRect:self.visibleRect avoidAdditionalLayout:YES];
    }
}

@end

@implementation XVimView {
    NSTextView     *__unsafe_unretained _textView;

    NSUInteger      _preservedColumn;
    BOOL            _syncStateLock;
    CURSOR_MODE     _cursorMode;

    NSString       *_lastYankedText;
    TEXT_TYPE       _lastYankedType;

    NSMutableArray *_foundRanges;
}
@synthesize window = _window;
@synthesize textView = _textView;
@synthesize delegate = _delegate;

@synthesize insertionPoint = _insertionPoint;
@synthesize selectionBegin = _selectionBegin;
@synthesize selectionMode  = _selectionMode;

@synthesize needsUpdateFoundRanges = _needsUpdateFoundRanges;
@synthesize foundRanges = _foundRanges;

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
    [_foundRanges release];
    [_lastYankedText release];
    [_window release];
    [super dealloc];
}

- (void)_xvim_statusChanged:(id)sender
{
    if (!XVim.instance.disabled) {
        [self _syncStateFromView];
        [self scrollTo:_insertionPoint];
    }
    [_textView setNeedsDisplay:YES];
}

- (void)_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger  length = buffer.length;

    // This method only update the internal state(like _insertionPoint)
    if (pos > length) {
        ERROR_LOG(@"Position specified exceeds the length of the text");
        pos = length;
    }

    _insertionPoint = pos;
    if (_cursorMode == CURSOR_MODE_COMMAND && _selectionMode == XVIM_VISUAL_NONE) {
        if (![buffer isNormalCursorPositionValidAtIndex:pos]) {
            _insertionPoint = pos - 1;
        }
    }

    if (!preserve) {
        _preservedColumn = [buffer columnOfIndex:_insertionPoint];
    }

    DEBUG_LOG(@"New Insertion Point:%d  Preserved Column:%d", _insertionPoint, _preservedColumn);
}

- (void)_syncStateFromView
{
    // TODO: handle block selection (if selectedRanges have multiple ranges )
    if (_syncStateLock || self.buffer.isEditing) {
        return;
    }

    NSRange r = [_textView selectedRange];
    DEBUG_LOG(@"Selected Range(TotalLen:%d): Loc:%d Len:%d", self.buffer.length, r.location, r.length);
    [self _moveCursor:r.location preserveColumn:NO];
    _selectionBegin = _insertionPoint;
    self.selectionMode = XVIM_VISUAL_NONE;
}

/**
 * Applies internal state to underlying view (self).
 * This update self's property and applies the visual effect on it.
 * All the state need to express Vim is held by this class and
 * we use self to express it visually.
 **/
- (void)_syncState
{
    DEBUG_LOG(@"IP:%d", _insertionPoint);

    _syncStateLock = YES;

    if (_cursorMode == CURSOR_MODE_COMMAND) {
        if (![self.buffer isNormalCursorPositionValidAtIndex:_insertionPoint]) {
            NSRange placeholder = [(DVTSourceTextView *)_textView rangeOfPlaceholderFromCharacterIndex:_insertionPoint forward:NO wrap:NO limit:0];
            if (placeholder.location != NSNotFound && _insertionPoint == (placeholder.location + placeholder.length)) {
                // The condition here means that just before current insertion point is a placeholder.
                // So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
                [self _moveCursor:placeholder.location preserveColumn:YES];
            } else {
                [self _moveCursor:_insertionPoint - 1 preserveColumn:YES];
            }
        }
    }

    TRACE_LOG(@"mode:%d length:%d cursor:%d ip:%d begin:%d line:%d column:%d preservedColumn:%d", \
              _selectionMode, self.buffer.length, _cursorMode, _insertionPoint, _selectionBegin,
              self.insertionLine, self.insertionColumn, _preservedColumn);

#ifndef __XCODE5__
    [(DVTFoldingTextStorage*)_textView.textStorage increaseUsingFoldedRanges];
#endif
    [_textView xvim_setSelectedRanges:[self _selectedRanges] affinity:NSSelectionAffinityDownstream stillSelecting:NO];
#ifndef __XCODE5__
    [(DVTFoldingTextStorage*)_textView.textStorage decreaseUsingFoldedRanges];
#endif

    [self scrollTo:_insertionPoint];
    _syncStateLock = NO;
}

#pragma mark *** Properties ***

- (XVimBuffer *)buffer
{
    return _textView.textStorage.xvim_buffer;
}

- (XVimPosition)insertionPosition
{
    return [self.buffer positionOfIndex:_insertionPoint];
}

- (NSUInteger)insertionColumn
{
    return [self.buffer columnOfIndex:_insertionPoint];
}

- (NSUInteger)insertionLine
{
    return [self.buffer lineNumberAtIndex:_insertionPoint];
}

- (XVimPosition)selectionPosition
{
    return [self.buffer positionOfIndex:_selectionBegin];
}

- (NSUInteger)selectionColumn
{
    return [self.buffer columnOfIndex:_selectionBegin];
}

- (NSUInteger)selectionLine
{
    return [self.buffer lineNumberAtIndex:_selectionBegin];
}

- (BOOL)inVisualMode
{
    return _selectionMode != XVIM_VISUAL_NONE;
}

- (BOOL)inBlockMode
{
    return _selectionMode == XVIM_VISUAL_BLOCK;
}

- (void)setSelectionMode:(XVimVisualMode)mode
{
    if (_selectionMode != mode) {
        if (mode == XVIM_VISUAL_NONE) {
            _selectionBegin = NSNotFound;
        } else if (_selectionMode == XVIM_VISUAL_NONE) {
            _selectionBegin = _insertionPoint;
        }
        _selectionMode = mode;
        [self _syncState];
    }
}


#pragma mark *** Visual Mode and Cursor Position ***

- (XVimRange)_selectedLines
{
    if (_selectionMode == XVIM_VISUAL_NONE) { // its not in selecting mode
        return (XVimRange){ NSNotFound, NSNotFound };
    } else {
        NSUInteger l1 = self.insertionLine;
        NSUInteger l2 = self.selectionLine;

        return (XVimRange){ MIN(l1, l2), MAX(l1, l2) };
    }
}

- (NSRange)_selectedRange
{
    XVimBuffer *buffer = self.buffer;

    if (_selectionMode == XVIM_VISUAL_NONE) {
        return NSMakeRange(_insertionPoint, 0);
    }

    if (_selectionMode == XVIM_VISUAL_CHARACTER) {
        XVimRange xvr = XVimMakeRange(_selectionBegin, _insertionPoint);

        if (xvr.begin > xvr.end) {
            xvr = XVimRangeSwap(xvr);
        }
        if (xvr.end >= buffer.length) {
            xvr.end--;
        }
        return XVimMakeNSRange(xvr);
    }

    if (_selectionMode == XVIM_VISUAL_LINE) {
        XVimRange   lines  = [self _selectedLines];
        NSUInteger  begin  = [buffer indexOfLineNumber:lines.begin];
        NSUInteger  end    = [buffer indexOfLineNumber:lines.end];

        end = [buffer endOfLine:end];
        if (end >= buffer.length) {
            end--;
        }
        return NSMakeRange(begin, end - begin + 1);
    }

    return NSMakeRange(NSNotFound, 0);
}

- (XVimSelection)_selectedBlock
{
    XVimSelection result = { };

    if (_selectionMode == XVIM_VISUAL_NONE) {
        result.top = result.bottom = result.left = result.right = NSNotFound;
        return result;
    }

    XVimBuffer *buffer = self.buffer;
    NSUInteger l1, c11, c12;
    NSUInteger l2, c21, c22;
    NSUInteger tabWidth = buffer.tabWidth;
    NSUInteger pos;

    pos = _selectionBegin;
    l1  = [buffer lineNumberAtIndex:pos];
    c11 = [buffer columnOfIndex:pos];
    if (!tabWidth || pos >= buffer.length || [buffer.string characterAtIndex:pos] != '\t') {
        c12 = c11;
    } else {
        c12 = c11 + tabWidth - (c11 % tabWidth) - 1;
    }

    pos = _insertionPoint;
    l2  = [buffer lineNumberAtIndex:pos];
    c21 = [buffer columnOfIndex:pos];
    if (!tabWidth || pos >= buffer.length || [buffer.string characterAtIndex:pos] != '\t') {
        c22 = c21;
    } else {
        c22 = c21 + tabWidth - (c21 % tabWidth) - 1;
    }

    if (l1 <= l2) {
        result.corner |= _XVIM_VISUAL_BOTTOM;
    }
    if (c11 <= c22) {
        result.corner |= _XVIM_VISUAL_RIGHT;
    }
    result.top     = MIN(l1, l2);
    result.bottom  = MAX(l1, l2);
    result.left    = MIN(c11, c21);
    result.right   = MAX(c12, c22);
    if (_preservedColumn == XVimSelectionEOL) {
        result.right = XVimSelectionEOL;
    }
    return result;
}

- (NSArray *)_selectedRanges
{
    XVimBuffer *buffer = self.buffer;

    if (_selectionMode != XVIM_VISUAL_BLOCK) {
        return [NSArray arrayWithObject:[NSValue valueWithRange:[self _selectedRange]]];
    }

    NSMutableArray *rangeArray = [[[NSMutableArray alloc] init] autorelease];
    XVimSelection   sel    = [self _selectedBlock];
    NSUInteger      length = buffer.length;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger begin = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger end   = [buffer indexOfLineNumber:line column:sel.right];

        if (begin >= length) {
            continue;
        }
        if (end >= length) {
            end--;
        } else if (sel.right != XVimSelectionEOL && [buffer isIndexAtEndOfLine:end]) {
            end--;
        }
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(begin, end - begin + 1)]];
    }
    return rangeArray;
}

- (void)selectSwapCorners:(BOOL)onSameLine
{
    if (_selectionMode == XVIM_VISUAL_BLOCK) {
        XVimBuffer *buffer = self.buffer;
        XVimPosition start, end;
        XVimSelection sel;
        NSUInteger pos;

        sel = [self _selectedBlock];
        if (onSameLine) {
            sel.corner ^= _XVIM_VISUAL_RIGHT;
        } else {
            sel.corner ^= _XVIM_VISUAL_RIGHT | _XVIM_VISUAL_BOTTOM;
        }

        if (sel.corner & _XVIM_VISUAL_BOTTOM) {
            start.line = sel.top;
            end.line   = sel.bottom;
        } else {
            end.line   = sel.top;
            start.line = sel.bottom;
        }

        if (sel.corner & _XVIM_VISUAL_RIGHT) {
            start.column = sel.left;
            end.column   = sel.right;
        } else {
            end.column   = sel.left;
            start.column = sel.right;
        }

        _selectionBegin = [buffer indexOfLineNumber:start.line column:start.column];
        pos = [buffer indexOfLineNumber:end.line column:end.column];
        [self _moveCursor:pos preserveColumn:NO];
    } else if (_selectionMode != XVIM_VISUAL_NONE) {
        NSUInteger begin = _selectionBegin;

        _selectionBegin = _insertionPoint;
        [self _moveCursor:begin preserveColumn:NO];
    }
    [_textView setNeedsDisplay:YES];
    [self _syncState];
}

- (void)escapeFromInsertAndMoveBack:(BOOL)moveBack
{
    if (_cursorMode == CURSOR_MODE_INSERT) {
        _cursorMode = CURSOR_MODE_COMMAND;
        if (moveBack && ![self.buffer isIndexAtStartOfLine:_insertionPoint]) {
            [self _moveCursor:_insertionPoint - 1 preserveColumn:NO];
        }
        [self _syncState];
    }
}

- (void)saveVisualInfoForBuffer:(XVimBuffer *)buffer
{
    XVimVisualInfo *vi = &buffer->visualInfo;

    vi->mode    = _selectionMode;
    vi->end     = self.insertionPosition;
    vi->start   = self.selectionPosition;
    vi->colwant = _preservedColumn;
}

- (void)selectNextPlaceholder
{
#ifdef __USE_DVTKIT__
    if ([_textView isKindOfClass:[DVTSourceTextView class]]) {
        [(DVTSourceTextView *)_textView selectNextPlaceholder:self];
    }
#endif
}

- (void)selectPreviousPlaceholder {
#ifdef __USE_DVTKIT__
    if ([_textView isKindOfClass:[DVTSourceTextView class]]) {
        [(DVTSourceTextView *)_textView selectPreviousPlaceholder:self];
    }
#endif
}

/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
 */
- (void)adjustCursorPosition
{
    NSRange range = _textView.selectedRange;

    // If the current cursor position is not valid for normal mode move it.
    if (![self.buffer isNormalCursorPositionValidAtIndex:range.location]) {
        [self selectPreviousPlaceholder];
        NSRange prevPlaceHolder = _textView.selectedRange;

        if (range.location != prevPlaceHolder.location && range.location == NSMaxRange(prevPlaceHolder)) {
            // The condition here means that just before current insertion point is a placeholder.
            // So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
        } else {
            _textView.selectedRange = NSMakeRange(range.location - 1, 0);
        }
    }
    return;
}

- (void)moveCursorToIndex:(NSUInteger)index
{
    [self _moveCursor:index preserveColumn:NO];
    [self _syncState];
}

- (void)moveCursorToPosition:(XVimPosition)pos
{
    NSUInteger index = [self.buffer indexOfLineNumber:pos.line column:pos.column];

    [self _moveCursor:index preserveColumn:NO];
    if (pos.column == XVimSelectionEOL) {
        _preservedColumn = XVimSelectionEOL;
    }
    [self _syncState];
}

- (NSUInteger)_fixupMotionEnd:(NSUInteger)end buffer:(XVimBuffer *)buffer motion:(XVimMotion *)motion
{
    NSUInteger search = end;
    NSRange r;

    if (end < buffer.length && [buffer.string characterAtIndex:end] == '#') {
        search++;
    }

    r = [(DVTSourceTextView *)_textView rangeOfPlaceholderFromCharacterIndex:search forward:NO wrap:NO limit:0];
    if (r.location != NSNotFound && end < NSMaxRange(r)) {
        if (motion.motion == MOTION_FORWARD) {
            end = NSMaxRange(r);
        } else {
            end = r.location;
        }
    }

    if (![buffer isNormalCursorPositionValidAtIndex:end]) {
        motion.info->reachedEndOfLine = YES;
        end--;
    }
    return end;
}

- (XVimRange)_getMotionRange:(NSUInteger)current motion:(XVimMotion*)motion
{
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSUInteger begin = current;
    NSUInteger end = NSNotFound;
    NSUInteger tmpPos = NSNotFound;
    NSUInteger start = NSNotFound;
    XVimBuffer *buffer = self.buffer;
    NSTextStorage *ts = buffer.textStorage;

    switch (motion.motion) {
    case MOTION_NONE:
        // Do nothing
        break;
    case MOTION_FORWARD:
        end = [buffer indexOfCharMotion:motion.scount index:begin options:motion.option];
        end = [self _fixupMotionEnd:end buffer:buffer motion:motion];
        break;
    case MOTION_BACKWARD:
        end = [buffer indexOfCharMotion:-motion.scount index:begin options:motion.option];
        end = [self _fixupMotionEnd:end buffer:buffer motion:motion];
        break;
    case MOTION_WORD_FORWARD:
        end = [ts wordsForward:begin count:motion.count option:motion.option info:motion.info];
        break;
    case MOTION_WORD_BACKWARD:
        end = [ts wordsBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_END_OF_WORD_FORWARD:
        end = [ts endOfWordsForward:begin count:motion.count option:motion.option];
        break;
    case MOTION_END_OF_WORD_BACKWARD:
        end = [ts endOfWordsBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_LINE_FORWARD:
        end = [buffer indexOfLineMotion:motion.scount index:begin column:_preservedColumn];
        break;
    case MOTION_LINE_BACKWARD:
        end = [buffer indexOfLineMotion:-motion.scount index:begin column:_preservedColumn];
        break;
    case MOTION_BEGINNING_OF_LINE:
        end = [buffer startOfLine:begin];
        break;
    case MOTION_COLUMN_OF_LINE:
        end = [buffer indexOfLineAtIndex:begin column:motion.count - 1];
        if (![buffer isNormalCursorPositionValidAtIndex:end]) {
            motion.info->reachedEndOfLine = YES;
            end--;
        }
        break;
    case MOTION_END_OF_LINE:
        end = [buffer indexOfLineMotion:motion.scount - 1 index:begin column:XVimSelectionEOL];
        break;
    case MOTION_SENTENCE_FORWARD:
        end = [ts sentencesForward:begin count:motion.count option:motion.option];
        break;
    case MOTION_SENTENCE_BACKWARD:
        end = [ts sentencesBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_PARAGRAPH_FORWARD:
        end = [ts moveFromIndex:begin paragraphs:motion.scount option:motion.option];
        break;
    case MOTION_PARAGRAPH_BACKWARD:
        end = [ts moveFromIndex:begin paragraphs:-motion.scount option:motion.option];
        break;
    case MOTION_NEXT_CHARACTER:
        end = [ts nextCharacterInLine:begin count:motion.count character:motion.character option:MOPT_NONE];
        break;
    case MOTION_PREV_CHARACTER:
        end = [ts prevCharacterInLine:begin count:motion.count character:motion.character option:MOPT_NONE];
        break;
    case MOTION_TILL_NEXT_CHARACTER:
        end = [ts nextCharacterInLine:begin count:motion.count character:motion.character option:MOPT_NONE];
        if (end != NSNotFound) {
            end--;
        }
        break;
    case MOTION_TILL_PREV_CHARACTER:
        end = [ts prevCharacterInLine:begin count:motion.count character:motion.character option:MOPT_NONE];
        if (end != NSNotFound) {
            end++;
        }
        break;
    case MOTION_NEXT_FIRST_NONBLANK:
        end = [buffer indexOfLineMotion:motion.scount index:begin column:0];
        end = [buffer firstNonblankInLineAtIndex:end allowEOL:YES];
        break;
    case MOTION_PREV_FIRST_NONBLANK:
        end = [buffer indexOfLineMotion:-motion.scount index:begin column:0 ];
        end = [buffer firstNonblankInLineAtIndex:end allowEOL:YES];
        break;
    case MOTION_FIRST_NONBLANK:
        end = [buffer firstNonblankInLineAtIndex:begin allowEOL:NO];
        break;
    case MOTION_LINENUMBER:
        end = [buffer indexOfLineNumber:motion.line column:_preservedColumn];
        if (NSNotFound == end) {
            end = [buffer indexOfLineMotion:0 index:buffer.length column:_preservedColumn];
        }
        break;
    case MOTION_PERCENT:
        end = [buffer indexOfLineNumber:1 + ([buffer numberOfLines]-1) * motion.count/100];
        break;
    case MOTION_NEXT_MATCHED_ITEM:
        end = [ts positionOfMatchedPair:begin];
        break;
    case MOTION_LASTLINE:
        end = [buffer indexOfLineMotion:0 index:buffer.length column:_preservedColumn];
        break;
    case MOTION_HOME:
        tmpPos = [self lineNumberInScrollView:0.0 offset:motion.scount - 1];
        end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
        break;
    case MOTION_MIDDLE:
        tmpPos = [self lineNumberInScrollView:0.5 offset:0];
        end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
        break;
    case MOTION_BOTTOM:
        tmpPos = [self lineNumberInScrollView:1.0 offset:1 - motion.scount];
        end    = [buffer firstNonblankInLineAtIndex:[buffer indexOfLineNumber:tmpPos] allowEOL:YES];
        break;
    case MOTION_SEARCH_FORWARD:
        end = [ts searchRegexForward:motion.regex from:_insertionPoint count:motion.count option:motion.option].location;
        break;
    case MOTION_SEARCH_BACKWARD:
        end = [ts searchRegexBackward:motion.regex from:_insertionPoint count:motion.count option:motion.option].location;
        break;
    case TEXTOBJECT_WORD:
        range = [ts currentWord:begin count:motion.count  option:motion.option];
        break;
    case TEXTOBJECT_BRACES:
        range = xv_current_block(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '{', '}');
        break;
    case TEXTOBJECT_PARAGRAPH:
        // Not supported
        start = [ts moveFromIndex:_insertionPoint paragraphs:-1 option:MOPT_PARA_BOUND_BLANKLINE];
        end   = [ts moveFromIndex:_insertionPoint paragraphs:motion.scount option:MOPT_PARA_BOUND_BLANKLINE];
        range = NSMakeRange(start, end - start);
        break;
    case TEXTOBJECT_PARENTHESES:
       range = xv_current_block(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '(', ')');
        break;
    case TEXTOBJECT_SENTENCE:
        // Not supported
        break;
    case TEXTOBJECT_ANGLEBRACKETS:
        range = xv_current_block(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '<', '>');
        break;
    case TEXTOBJECT_SQUOTE:
        range = xv_current_quote(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '\'');
        break;
    case TEXTOBJECT_DQUOTE:
        range = xv_current_quote(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '\"');
        break;
    case TEXTOBJECT_TAG:
        // Not supported
        break;
    case TEXTOBJECT_BACKQUOTE:
        range = xv_current_quote(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '`');
        break;
    case TEXTOBJECT_SQUAREBRACKETS:
        range = xv_current_block(buffer.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '[', ']');
        break;
    case MOTION_LINE_COLUMN:
        end = [buffer indexOfLineNumber:motion.line column:motion.column];
        if (NSNotFound == end) {
            end = current;
        }
        break;
    case MOTION_POSITION:
        end = motion.position;
        break;
    }

    if (range.location != NSNotFound) {// This block is for TEXTOBJECT
        begin = range.location;
        if (range.length == 0) {
            end = NSNotFound;
        }else{
            end = range.location + range.length - 1;
        }
    }

    TRACE_LOG(@"range location:%u  length:%u", begin, end);
    return XVimMakeRange(begin, end);
}

- (void)moveCursorWithMotion:(XVimMotion*)motion
{
    XVimRange r = [self _getMotionRange:_insertionPoint motion:motion];

    if (r.end == NSNotFound) {
        return;
    }

    if (_selectionMode != XVIM_VISUAL_NONE && [motion isTextObject]) {
        if( _selectionMode == XVIM_VISUAL_LINE) {
            // Motion with text object in VISUAL LINE changes visual mode to VISUAL CHARACTER
            self.selectionMode = XVIM_VISUAL_CHARACTER;
        }

        if (_insertionPoint < _selectionBegin) {
            // When insertionPoint < selectionBegin it only changes insertion point to begining of the text object
            [self _moveCursor:r.begin preserveColumn:NO];
        } else {
            // Text object expands one text object ( the text object under insertion point + 1 )
            if (_insertionPoint + 1 < self.buffer.length) {
                r = [self _getMotionRange:_insertionPoint + 1 motion:motion];
            }
            if (_selectionBegin > r.begin) {
                _selectionBegin = r.begin;
            }
            [self _moveCursor:r.end preserveColumn:NO];
        }
    } else {
        BOOL preserveColumn = YES;

        switch (motion.motion) {
        case MOTION_COLUMN_OF_LINE:
            _preservedColumn = motion.count - 1;
            break;
        case MOTION_END_OF_LINE:
            _preservedColumn = XVimSelectionEOL;
            break;
        case MOTION_LINE_BACKWARD:
        case MOTION_LINE_FORWARD:
        case MOTION_LASTLINE:
        case MOTION_LINENUMBER:
            break;
        default:
            preserveColumn = NO;
            break;
        }
        [self _moveCursor:r.end preserveColumn:preserveColumn];
    }
    [_textView setNeedsDisplay:YES];
    [self _syncState];
}

#pragma mark *** Operations ***

- (NSRange)_getOperationRange:(XVimRange)xrange type:(MOTION_TYPE)type
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger length  = buffer.length;

    if (buffer.length == 0) {
        return NSMakeRange(0, 0);
    }

    if (xrange.begin > xrange.end) {
        xrange = XVimRangeSwap(xrange);
    }

    // EOF can not be included in operation range.
    if (xrange.begin >= length) {
        return NSMakeRange(length, 0);
    }

    // EOF should not be included.
    // If type is exclusive we do not subtract 1 because we do it later below
    if (xrange.end >= length && type != CHARACTERWISE_EXCLUSIVE) {
        // Note that we already know that "to" is not 0 so not chekcing if its 0.
        xrange.end--;
    }

    // At this point "from" and "to" is not EOF
    if (type == CHARACTERWISE_EXCLUSIVE) {
        // to will not be included.
        xrange.end--;
    } else if (type == CHARACTERWISE_INCLUSIVE) {
        // Nothing special
    } else if (type == LINEWISE) {
        xrange.end = [buffer endOfLine:xrange.end];
        if (xrange.end >= length) {
            xrange.end--;
        }
        xrange.begin = [buffer startOfLine:xrange.begin];
    }

    return XVimMakeNSRange(xrange);
}

- (void)_registerInsertionPointForUndo
{
    XVimUndoOperation *op = [[XVimUndoOperation alloc] initWithIndex:_insertionPoint];
    [op registerForBuffer:self.buffer];
    [op release];
}

- (void)__startYankWithType:(MOTION_TYPE)type
{
    if (_selectionMode == XVIM_VISUAL_NONE) {
        if (type == CHARACTERWISE_EXCLUSIVE || type == CHARACTERWISE_INCLUSIVE) {
            _lastYankedType = TEXT_TYPE_CHARACTERS;
        } else if (type == LINEWISE) {
            _lastYankedType = TEXT_TYPE_LINES;
        }
    } else if (_selectionMode == XVIM_VISUAL_CHARACTER) {
        _lastYankedType = TEXT_TYPE_CHARACTERS;
    } else if (_selectionMode == XVIM_VISUAL_LINE) {
        _lastYankedType = TEXT_TYPE_LINES;
    } else if (_selectionMode == XVIM_VISUAL_BLOCK) {
        _lastYankedType = TEXT_TYPE_BLOCK;
    }
    TRACE_LOG(@"YANKED START WITH TYPE:%d", _lastYankedType);
}

- (void)_yankRange:(NSRange)range withType:(MOTION_TYPE)type
{
    XVimBuffer *buffer = self.buffer;
    NSString *string = buffer.string;
    NSString *s;
    BOOL needsNL;

    [self __startYankWithType:type];

    needsNL = _lastYankedType == TEXT_TYPE_LINES;
    if (range.length) {
        s = [string substringWithRange:range];
        if (needsNL && !isNewline([s characterAtIndex:s.length - 1])) {
            s = [s stringByAppendingString:buffer.lineEnding];
        }
    } else if (needsNL) {
        s = buffer.lineEnding;
    } else {
        s = @"";
    }

    [_lastYankedText release];
    _lastYankedText = [s retain];
    TRACE_LOG(@"YANKED STRING : %@", s);
}

- (void)_yankSelection:(XVimSelection)sel
{
    XVimBuffer *buffer   = self.buffer;
    NSString   *string   = buffer.string;
    NSUInteger  tabWidth = buffer.tabWidth;

    NSMutableString *ybuf = [[NSMutableString alloc] init];

    _lastYankedType = TEXT_TYPE_BLOCK;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger lpos = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [buffer indexOfLineNumber:line column:sel.right];

        /* if lpos points in the middle of a tab, split it and advance lpos */
        if (lpos < string.length && [string characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = sel.left - (sel.left % tabWidth);

            if (lcol < sel.left) {
                NSUInteger count = tabWidth - (sel.left - lcol);

                if (lpos == rpos) {
                    /* if rpos points to the same tab, truncate it to the right also */
                    count = sel.right - sel.left + 1;
                }
                CFStringPad((CFMutableStringRef)ybuf, CFSTR("     "),
                            (CFIndex)(ybuf.length + count), 0);
                lpos++;
            }
        }

        if (lpos <= rpos) {
            if (sel.right == XVimSelectionEOL) {
                [ybuf appendString:[string substringWithRange:NSMakeRange(lpos, rpos - lpos)]];
            } else {
                NSRange r = NSMakeRange(lpos, rpos - lpos + 1);
                NSUInteger rcol;
                BOOL mustPad = NO;

                if (rpos >= string.length) {
                    rcol = [buffer columnOfIndex:rpos];
                    mustPad = YES;
                    r.length--;
                } else {
                    unichar c = [string characterAtIndex:rpos];
                    if (isNewline(c)) {
                        rcol = [buffer columnOfIndex:rpos];
                        mustPad = YES;
                        r.length--;
                    } else if (c == '\t') {
                        rcol = [buffer columnOfIndex:rpos];
                        if (sel.right - rcol + 1 < tabWidth) {
                            mustPad = YES;
                            r.length--;
                        }
                    }
                }

                if (r.length) {
                    [ybuf appendString:[string substringWithRange:r]];
                }

                if (mustPad) {
                    [ybuf appendString:[NSString stringMadeOfSpaces:sel.right - rcol + 1]];
                }
            }
        }
        [ybuf appendString:buffer.lineEnding];
    }

    [_lastYankedText release];
    _lastYankedText = ybuf;
    TRACE_LOG(@"YANKED STRING : %@", ybuf);
}

- (void)_killSelection:(XVimSelection)sel
{
    XVimBuffer *buffer   = self.buffer;
    NSString   *string   = buffer.string;
    NSUInteger  tabWidth = buffer.tabWidth;

    for (NSUInteger line = sel.bottom; line >= sel.top; line--) {
        NSUInteger lpos = [buffer indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [buffer indexOfLineNumber:line column:sel.right];
        NSUInteger nspaces = 0;

        if (lpos >= string.length) {
            continue;
        }

        if ([string characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = [buffer columnOfIndex:lpos];

            if (lcol < sel.left) {
                nspaces = sel.left - lcol;
                if (lpos == rpos) {
                    nspaces = tabWidth - (sel.right - sel.left + 1);
                }
            }
        }

        if ([buffer isIndexAtEndOfLine:rpos]) {
            rpos--;
        } else if (lpos < rpos) {
            if ([string characterAtIndex:rpos] == '\t') {
                nspaces += tabWidth - (sel.right - [buffer columnOfIndex:rpos] + 1);
            }
        }

        NSRange range = NSMakeRange(lpos, rpos - lpos + 1);

        [buffer replaceCharactersInRange:range withSpaces:nspaces];
    }
}

- (void)doDelete:(XVimMotion *)motion andYank:(BOOL)yank
{
    XVimBuffer *buffer = self.buffer;

    NSAssert(!(_selectionMode == XVIM_VISUAL_NONE && motion == nil),
             @"motion must be specified if current selection mode is not visual");
    if (_insertionPoint == 0 && buffer.length == 0) {
        return ;
    }
    NSUInteger pos = _insertionPoint;

    motion.info->deleteLastLine = NO;
    if (_selectionMode == XVIM_VISUAL_NONE) {
        XVimRange motionRange = [self _getMotionRange:pos motion:motion];
        NSRange r;

        if (motionRange.end == NSNotFound) {
            return;
        }

        // We have to treat some special cases
        // When a cursor get end of line with "l" motion, make the motion type to inclusive.
        // This make you to delete the last character. (if its exclusive last character never deleted with "dl")
        if (motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine) {
            if (motion.type == CHARACTERWISE_EXCLUSIVE) {
                motion.type = CHARACTERWISE_INCLUSIVE;
            } else if (motion.type == CHARACTERWISE_INCLUSIVE) {
                motion.type = CHARACTERWISE_EXCLUSIVE;
            }
        }
        if (motion.motion == MOTION_WORD_FORWARD) {
            if ((motion.info->isFirstWordInLine && motion.info->lastEndOfLine != NSNotFound)) {
                // Special cases for word move over a line break.
                motionRange.end = motion.info->lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if (motion.info->reachedEndOfLine) {
                if (motion.type == CHARACTERWISE_EXCLUSIVE) {
                    motion.type = CHARACTERWISE_INCLUSIVE;
                } else if (motion.type == CHARACTERWISE_INCLUSIVE) {
                    motion.type = CHARACTERWISE_EXCLUSIVE;
                }
            }
        }
        r = [self _getOperationRange:motionRange type:motion.type];

        if (motion.type == LINEWISE && [buffer isIndexOnLastLine:motionRange.end]) {
            // eat the previous end of line as well
            if (r.location > 0) {
                NSUInteger endOfPreviousLine = [buffer endOfLine:r.location - 1];

                r.length += r.location - endOfPreviousLine;
                r.location = endOfPreviousLine;
                motion.info->deleteLastLine = YES;
            }
        }
        if (yank) {
            [self _yankRange:r withType:motion.type];
        }

        pos = r.location;
        [self _moveCursor:pos preserveColumn:NO];
        [buffer beginEditingAtIndex:pos];
        [buffer replaceCharactersInRange:r withString:@""];
        if (motion.type == LINEWISE) {
            pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
        }
    } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        BOOL toFirstNonBlank = (self.selectionMode == XVIM_VISUAL_LINE);
        NSRange range = [self _selectedRange];

        // Currently not supportin deleting EOF with selection mode.
        // This is because of the fact that NSTextView does not allow select EOF

        if (yank) {
            [self _yankRange:range withType:DEFAULT_MOTION_TYPE];
        }

        pos = range.location;
        [self _moveCursor:pos preserveColumn:NO];
        [buffer beginEditingAtIndex:pos];
        [buffer replaceCharactersInRange:range withString:@""];
        if (toFirstNonBlank) {
            pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
        }
    } else {
        XVimSelection sel = [self _selectedBlock];
        if (yank) {
            [self _yankSelection:sel];
        }
        pos = [buffer indexOfLineNumber:sel.top column:sel.left];
        [buffer beginEditingAtIndex:pos];
        [self _killSelection:sel];
    }
    [buffer endEditingAtIndex:pos];

    [_delegate textView:_textView didDelete:_lastYankedText  withType:_lastYankedType];

    [self _moveCursor:pos preserveColumn:NO];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doChange:(XVimMotion *)motion
{
    XVimBuffer *buffer = self.buffer;

    BOOL insertNewline = NO;
    if (motion.type == LINEWISE || _selectionMode == XVIM_VISUAL_LINE) {
        // 'cc' deletes the lines but need to keep the last newline.
        // So insertNewline as 'O' does before entering insert mode
        insertNewline = YES;
    }

    // "cw" is like "ce" if the cursor is on a word ( in this case blank line is not treated as a word )
    if (motion.motion == MOTION_WORD_FORWARD && [_textView.textStorage isNonblank:_insertionPoint]) {
        motion.motion = MOTION_END_OF_WORD_FORWARD;
        motion.type = CHARACTERWISE_INCLUSIVE;
        motion.option |= MOPT_CHANGE_WORD;
    }

    [buffer beginEditingAtIndex:_insertionPoint];
    _cursorMode = CURSOR_MODE_INSERT;
    [self doDelete:motion andYank:YES];

    if (motion.info->deleteLastLine || insertNewline) {
        [self _insertNewlineAboveLine:[buffer lineNumberAtIndex:_insertionPoint]];
    }

    [buffer endEditingAtIndex:_insertionPoint];

    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doYank:(XVimMotion*)motion
{
    XVimBuffer *buffer = self.buffer;

    NSAssert( !(_selectionMode == XVIM_VISUAL_NONE && motion == nil),
             @"motion must be specified if current selection mode is not visual");
    NSUInteger newPos = NSNotFound;

    if (_selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self _getMotionRange:_insertionPoint motion:motion];
        NSRange r;

        if (NSNotFound == to.end) {
            return;
        }

        // We have to treat some special cases (same as delete)
        if (motion.motion == MOTION_FORWARD && motion.info->reachedEndOfLine) {
            motion.type = CHARACTERWISE_INCLUSIVE;
        }
        if (motion.motion == MOTION_WORD_FORWARD) {
            if ((motion.info->isFirstWordInLine && motion.info->lastEndOfLine != NSNotFound)) {
                // Special cases for word move over a line break.
                to.end = motion.info->lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if (motion.info->reachedEndOfLine) {
                if (motion.type == CHARACTERWISE_EXCLUSIVE) {
                    motion.type = CHARACTERWISE_INCLUSIVE;
                } else if (motion.type == CHARACTERWISE_INCLUSIVE) {
                    motion.type = CHARACTERWISE_EXCLUSIVE;
                }
            }
        }
        r = [self _getOperationRange:to type:motion.type];
        if (motion.type == LINEWISE && to.end >= buffer.length && [buffer isIndexAtStartOfLine:to.end]) {
            if (r.location > 0) {
                NSUInteger endOfPreviousLine = [buffer endOfLine:r.location - 1];

                r.length += r.location - endOfPreviousLine;
                r.location = endOfPreviousLine;
            }
        }
        [self _yankRange:r withType:motion.type];
    } else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        NSRange range = [self _selectedRange];

        newPos = range.location;
        [self _yankRange:range withType:DEFAULT_MOTION_TYPE];
    } else {
        XVimSelection sel = [self _selectedBlock];

        newPos = [buffer indexOfLineNumber:sel.top column:sel.left];
        [self _yankSelection:sel];
    }

    [_delegate textView:_textView didYank:_lastYankedText  withType:_lastYankedType];
    if (newPos != NSNotFound) {
        [self _moveCursor:newPos preserveColumn:NO];
    }
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doPut:(NSString *)_text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count
{
    XVimBuffer *buffer = self.buffer;
    NSMutableString *text = [_text mutableCopy];

    TRACE_LOG(@"text:%@  type:%d   afterCursor:%d   count:%d", text, type, after, count);

    [buffer beginEditingAtIndex:_insertionPoint];

    if (self.selectionMode != XVIM_VISUAL_NONE) {
        [self doDelete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, 1) andYank:YES];
        after = NO;
    }

    NSUInteger insertionPointAfterPut = _insertionPoint;
    NSUInteger targetPos = _insertionPoint;

    if (type == TEXT_TYPE_CHARACTERS) {
        // Forward insertion point +1 if after flag if on
        if (0 != text.length) {
            if (![buffer isIndexAtEndOfLine:_insertionPoint] && after) {
                targetPos++;
            }
            insertionPointAfterPut = targetPos;
            for (NSUInteger i = 0; i < count ; i++) {
                [buffer replaceCharactersInRange:NSMakeRange(targetPos, 0) withString:text];
            }
            insertionPointAfterPut += text.length * count - 1;
        }
    } else if (type == TEXT_TYPE_LINES) {
        if (after) {
            [self _insertNewlineBelowCurrentLine];
            targetPos = _insertionPoint;
        } else {
            targetPos= [buffer startOfLine:_insertionPoint];
        }
        insertionPointAfterPut = targetPos;
        if (after) {
            // delete newline at the end. (TEXT_TYPE_LINES always have newline at the end of the text)
            [text replaceCharactersInRange:NSMakeRange(text.length - 1, 1) withString:@""];
        }
        for (NSUInteger i = 0; i < count ; i++) {
            [buffer replaceCharactersInRange:NSMakeRange(targetPos, 0) withString:text];
            targetPos += text.length;
        }
    } else if (type == TEXT_TYPE_BLOCK) {
        // Forward insertion point +1 if after flag if on
        if (![buffer isIndexAtEndOfLine:_insertionPoint] && after) {
            _insertionPoint++;
        }
        insertionPointAfterPut = _insertionPoint;

        NSUInteger insertPos = _insertionPoint;
        NSUInteger column    = [buffer columnOfIndex:insertPos];
        NSUInteger startLine = [buffer lineNumberAtIndex:insertPos];
        NSArray   *lines     = [text componentsSeparatedByString:buffer.lineEnding];

        for (NSUInteger i = 0 ; i < lines.count ; i++) {
            NSString *line = [lines objectAtIndex:i];
            NSUInteger targetLine = startLine + i;
            NSUInteger head = [buffer indexOfLineNumber:targetLine];

            if (NSNotFound == head) {
                NSAssert( targetLine != 0, @"This should not be happen");
                [buffer replaceCharactersInRange:NSMakeRange(buffer.length, 0) withString:buffer.lineEnding];
                head = buffer.length;
            }
            NSAssert(NSNotFound != head, @"Head of the target line must be found at this point");

            // Find next insertion point
            NSUInteger max = [buffer numberOfColumnsInLineAtIndex:head];

            // FIXME: deal with tabs here

            // If the line does not have enough column pad it with spaces
            if (column > max) {
                NSUInteger end = [buffer endOfLine:head];

                [buffer replaceCharactersInRange:NSMakeRange(end, 0) withSpaces:column - max];
            }

            NSUInteger pos = [buffer indexOfLineNumber:targetLine column:column];

            for (NSUInteger i = 0; i < count ; i++) {
                [buffer replaceCharactersInRange:NSMakeRange(pos, 0) withString:line];
                pos += line.length;
            }
        }
    }

    [text release];
    [buffer endEditingAtIndex:insertionPointAfterPut];

    [self _moveCursor:insertionPointAfterPut preserveColumn:NO];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doSwapCharacters:(XVimMotion *)motion mode:(int)mode
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger undoPos = _insertionPoint;
    NSUInteger endPos;

    if (buffer.length == 0) {
        return;
    }

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        NSRange    range;

        if (motion.motion == MOTION_NONE) {
            XVimMotion *m = XVIM_MAKE_MOTION(MOTION_FORWARD,CHARACTERWISE_EXCLUSIVE,MOPT_NOWRAP,motion.count);
            XVimRange   r = [self _getMotionRange:undoPos motion:m];

            if (r.end == NSNotFound) {
                return;
            }
            if (m.info->reachedEndOfLine) {
                range = [self _getOperationRange:r type:CHARACTERWISE_INCLUSIVE];
            } else {
                range = [self _getOperationRange:r type:CHARACTERWISE_EXCLUSIVE];
            }
            endPos = r.end;
        } else {
            XVimRange to = [self _getMotionRange:undoPos motion:motion];
            if (to.end == NSNotFound) {
                return;
            }

            range  = [self _getOperationRange:to type:motion.type];
            endPos = range.location;
        }

        [buffer beginEditingAtIndex:undoPos];
        [buffer swapCharactersInRange:range mode:mode];
        [buffer endEditingAtIndex:endPos];
    } else {
        NSArray *ranges = [self _selectedRanges];

        endPos = undoPos = [[ranges objectAtIndex:0] rangeValue].location;
        [buffer beginEditingAtIndex:undoPos];
        for (NSValue *v in ranges) {
            [buffer swapCharactersInRange:v.rangeValue mode:mode];
        }
        [buffer endEditingAtIndex:endPos];
    }

    [self _moveCursor:endPos preserveColumn:NO];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (BOOL)doReplaceCharacters:(unichar)c count:(NSUInteger)count
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger end = [buffer endOfLine:_insertionPoint];

    // Note : endOfLine may return one less than _insertionPoint if _insertionPoint is on newline
    if (NSNotFound == end) {
        return NO;
    }

    if (_insertionPoint + count > end) {
        return NO;
    }

    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:count];
    unichar buf[8] = { c, c, c, c, c, c, c, c };
    NSUInteger pos = _insertionPoint;

    [buffer beginEditingAtIndex:pos];
    for (NSUInteger i = 0; i < count; i += 8) {
        [s appendCharacters:buf length:MIN(8, count - i)];
    }
    [buffer replaceCharactersInRange:NSMakeRange(pos, count) withString:s];
    [buffer endEditingAtIndex:pos];

    [s release];

    [self _moveCursor:pos + count preserveColumn:NO];
    [self _syncState];
    return YES;
}

- (void)_joinAtLineNumber:(NSUInteger)line
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger headOfLine = [buffer indexOfLineNumber:line];
    NSTextStorage *ts = _textView.textStorage;
    BOOL needSpace = NO;

    if (headOfLine == NSNotFound) {
        return;
    }

    NSUInteger tail = [buffer endOfLine:headOfLine];
    if (tail >= buffer.length) {
        // This is the last line and nothing to join
        return;
    }

    // Check if we need to insert space between lines.
    NSUInteger lastOfLine = [buffer lastOfLine:headOfLine];
    if (lastOfLine != NSNotFound) {
        // This is not blank line so we check if the last character is space or not .
        if (![ts isWhitespace:lastOfLine]) {
            needSpace = YES;
        }
    }

    // Search in next line for the position to join(skip white spaces in next line)
    NSUInteger posToJoin = [buffer indexOfLineMotion:1 index:headOfLine column:0];

    posToJoin = [buffer nextNonblankInLineAtIndex:posToJoin allowEOL:YES];
    if (posToJoin < buffer.length && [buffer.string characterAtIndex:posToJoin] == ')') {
        needSpace = NO;
    }

    // delete "tail" to "posToJoin" excluding the position of "posToJoin" and insert space if need.
    if (needSpace) {
        [buffer replaceCharactersInRange:NSMakeRange(tail, posToJoin - tail) withString:@" "];
    } else {
        [buffer replaceCharactersInRange:NSMakeRange(tail, posToJoin - tail) withString:@""];
    }

    // Move cursor
    [self _moveCursor:tail preserveColumn:NO];
}

- (void)doJoin:(NSUInteger)count addSpace:(BOOL)addSpace
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger line;

    [buffer beginEditingAtIndex:_insertionPoint];

    if (_selectionMode == XVIM_VISUAL_NONE) {
        line = self.insertionLine;
    } else {
        XVimRange lines = [self _selectedLines];

        line = lines.begin;
        count = MAX(1, lines.end - lines.begin);
    }

    if (addSpace) {
        for (NSUInteger i = 0; i < count; i++) {
            [self _joinAtLineNumber:line];
        }
    } else {
        NSUInteger pos = [buffer indexOfLineNumber:line];

        for (NSUInteger i = 0; i < count; i++) {
            NSUInteger tail = [buffer endOfLine:pos];

            if (tail < buffer.length) {
                [buffer replaceCharactersInRange:NSMakeRange(tail, 1) withString:@""];
                [self _moveCursor:tail preserveColumn:NO];
            }
        }
    }

    [buffer endEditingAtIndex:_insertionPoint];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doFilter:(XVimMotion *)motion
{
    XVimBuffer *buffer = self.buffer;

    if (_insertionPoint == 0 && buffer.length == 0) {
        return ;
    }

    NSRange filterRange;
    NSUInteger line, pos;

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self _getMotionRange:_insertionPoint motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        filterRange = [self _getOperationRange:to type:LINEWISE];
        line = [buffer lineNumberAtIndex:filterRange.location];
    } else {
        XVimRange lines = [self _selectedLines];
        NSUInteger from = [buffer indexOfLineNumber:lines.begin];
        NSUInteger to   = [buffer indexOfLineNumber:lines.end];

        filterRange = [self _getOperationRange:XVimMakeRange(from, to) type:LINEWISE];
        line = lines.begin;
    }

    [buffer indentCharacterRange:filterRange];

    pos = [buffer indexOfLineNumber:line];
    pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];

    [self _moveCursor:pos preserveColumn:NO];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)doShift:(XVimMotion *)motion right:(BOOL)right
{
    XVimBuffer *buffer = self.buffer;

    if (_insertionPoint == 0 && buffer.length == 0) {
        return ;
    }

    NSUInteger shiftWidth = buffer.indentWidth;
    NSUInteger column = 0, pos;
    XVimRange  lines;
    BOOL blockMode = NO;

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self _getMotionRange:_insertionPoint motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        lines = XVimMakeRange([buffer lineNumberAtIndex:to.begin], [buffer lineNumberAtIndex:to.end]);
    } else if (_selectionMode != XVIM_VISUAL_BLOCK) {
        lines = [self _selectedLines];
        shiftWidth *= motion.count;
    } else {
        XVimSelection sel = [self _selectedBlock];

        column = sel.left;
        lines  = XVimMakeRange(sel.top, sel.bottom);
        shiftWidth *= motion.count;
        blockMode = YES;
    }

    if (blockMode) {
        pos = [buffer indexOfLineNumber:lines.begin column:column];
    } else {
        pos = [buffer indexOfLineNumber:lines.begin];
        pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
    }

    [buffer beginEditingAtIndex:pos];
    pos = [buffer shiftLines:lines column:column
                       count:shiftWidth right:right block:blockMode];
    [buffer endEditingAtIndex:pos];

    [self _moveCursor:pos preserveColumn:NO];
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (void)_insertNewlineBelowCurrentLine
{
    XVimBuffer *buffer = self.buffer;

    NSUInteger pos = [buffer startOfLine:_insertionPoint];

    _insertionPoint = pos;
    [buffer beginEditingAtIndex:_insertionPoint];
    pos = [buffer endOfLine:pos];
    [buffer replaceCharactersInRange:NSMakeRange(pos, 0) withString:buffer.lineEnding];
    [buffer endEditingAtIndex:_insertionPoint];

    [self _moveCursor:pos + 1 preserveColumn:NO];
    [self _syncState];
}

- (void)_insertNewlineAboveLine:(NSUInteger)line
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger pos = [self.buffer indexOfLineNumber:line];

    if (NSNotFound == pos) {
        return;
    }
    if (line == 1) {
        [buffer beginEditingAtIndex:0];
        [buffer replaceCharactersInRange:NSMakeRange(0, 0) withString:buffer.lineEnding];
        [buffer endEditingAtIndex:0];
    } else {
        _insertionPoint = pos;
        [self _insertNewlineBelowCurrentLine];
    }
}

- (void)insertNewlineAboveAndInsertWithIndent
{
    NSUInteger head = [self.buffer startOfLine:_insertionPoint];

    _cursorMode = CURSOR_MODE_INSERT;
    if (head) {
        [_textView setSelectedRange:NSMakeRange(head - 1,0)];
        [_textView insertNewline:self];
    } else {
        [_textView setSelectedRange:NSMakeRange(0, 0)];
        [_textView insertNewline:self];
        [_textView setSelectedRange:NSMakeRange(0, 0)];
    }
}

- (void)insertNewlineBelowAndInsertWithIndent
{
    NSUInteger tail = [self.buffer endOfLine:_insertionPoint];

    _cursorMode = CURSOR_MODE_INSERT;
    [_textView setSelectedRange:NSMakeRange(tail, 0)];
    [_textView insertNewline:_textView];
}

- (void)doInsert:(XVimInsertionPoint)mode blockColumn:(NSUInteger *)column blockLines:(XVimRange *)lines
{
    XVimBuffer *buffer = self.buffer;

    if (column) *column = NSNotFound;
    if (lines)  *lines  = XVimMakeRange(NSNotFound, NSNotFound);

    if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        XVimSelection sel = [self _selectedBlock];
        NSUInteger tl = [buffer indexOfLineNumber:sel.top column:sel.left];

        if (lines) *lines = XVimMakeRange(sel.top, sel.bottom);
        switch (mode) {
        case XVIM_INSERT_BLOCK_KILL:
            [self _yankSelection:sel];
            [buffer beginEditingAtIndex:tl];
            [self _killSelection:sel];
            [buffer endEditingAtIndex:tl];
            /* falltrhough */
        case XVIM_INSERT_DEFAULT:
            _insertionPoint = tl;
            if (column) *column = sel.left;
            break;
        case XVIM_INSERT_APPEND:
            if (sel.right != XVimSelectionEOL) {
                sel.right++;
            }
            _insertionPoint = [buffer indexOfLineNumber:sel.top column:sel.right];
            if (column) *column = sel.right;
            break;
        default:
            NSAssert(false, @"unreachable");
            break;
        }
    } else if (mode != XVIM_INSERT_DEFAULT) {
        NSUInteger pos = _insertionPoint;
        switch (mode) {
        case XVIM_INSERT_APPEND_EOL:
            _insertionPoint = [buffer endOfLine:pos];
            break;
        case XVIM_INSERT_APPEND:
            NSAssert(_cursorMode == CURSOR_MODE_COMMAND, @"_cursorMode shoud be CURSOR_MODE_COMMAND");
            if (![buffer isIndexAtEndOfLine:pos]) {
                _insertionPoint = pos + 1;
            }
            break;
        case XVIM_INSERT_BEFORE_FIRST_NONBLANK:
            _insertionPoint = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
            break;
        default:
            NSAssert(false, @"unreachable");
        }
    }

    _cursorMode = CURSOR_MODE_INSERT;
    self.selectionMode = XVIM_VISUAL_NONE;
    [self _syncState];
}

- (BOOL)doIncrementNumber:(int64_t)offset
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger pos;

    pos = [buffer incrementNumberAtIndex:_insertionPoint by:offset];
    if (pos == NSNotFound) {
        return NO;
    }
    [self _moveCursor:pos preserveColumn:NO];
    [self _syncState];
    return YES;
}

- (void)doInsertFixupWithText:(NSString *)text mode:(XVimInsertionPoint)mode
                        count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines
{
    XVimBuffer *buffer = self.buffer;
    NSMutableString *buf = nil;
    NSUInteger tabWidth = buffer.tabWidth;

    if (count == 0 || lines.begin > lines.end || text.length == 0) {
        return;
    }
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return;
    }
    if (count > 1) {
        buf = [[NSMutableString alloc] initWithCapacity:text.length * count];
        for (NSUInteger i = 0; i < count; i++) {
            [buf appendString:text];
        }
        text = buf;
    }

    [buffer beginEditingAtIndex:NSNotFound];
    for (NSUInteger line = lines.begin; line <= lines.end; line++) {
        NSUInteger pos = [buffer indexOfLineNumber:line column:column];

        if (column != XVimSelectionEOL && [buffer isIndexAtEndOfLine:pos]) {
            if ([buffer columnOfIndex:pos] < column) {
                if (mode != XVIM_INSERT_APPEND) {
                    continue;
                }
                [buffer replaceCharactersInRange:NSMakeRange(pos, 0)
                                      withSpaces:column - [buffer columnOfIndex:pos]];
            }
        }
        if (tabWidth && [buffer.string characterAtIndex:pos] == '\t') {
            NSUInteger col = [buffer columnOfIndex:pos];

            if (col < column) {
                [buffer replaceCharactersInRange:NSMakeRange(pos, 1)
                                      withSpaces:tabWidth - (col % tabWidth)];
                pos += column - col;
            }
        }
        [buffer replaceCharactersInRange:NSMakeRange(pos, 0) withString:text];
    }
    [buffer endEditingAtIndex:NSNotFound];

    [buf release];
}

- (void)doSortLines:(XVimRange)range withOptions:(XVimSortOptions)options
{
    XVimBuffer *buffer = self.buffer;
    NSUInteger pos;

    NSAssert(range.begin > 0 && range.end > 0, @"lines must be greater than 0.");

    if (range.begin > range.end) {
        range = XVimRangeSwap(range);
    }

    NSMutableArray *lines = [[NSMutableArray alloc] initWithCapacity:range.end - range.begin + 1];
    NSRange characterRange = [buffer indexRangeForLines:XVimMakeNSRange(range)];

    pos = [buffer indexOfLineNumber:range.begin];
    for (NSUInteger line = range.begin; line <= range.end; line++) {
        NSUInteger nlLen;
        NSRange lineRange;

        lineRange = [buffer indexRangeForLineAtIndex:pos newLineLength:&nlLen];
        if (line == range.end && nlLen == 0 && lineRange.length == 0) {
            break;
        }
        [lines addObject:[buffer.string substringWithRange:lineRange]];
        pos = NSMaxRange(lineRange) + nlLen;
    }

    [lines sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        NSStringCompareOptions compareOptions = 0;
        if (options & XVimSortOptionNumericSort) {
            compareOptions |= NSNumericSearch;
        }
        if (options & XVimSortOptionIgnoreCase) {
            compareOptions |= NSCaseInsensitiveSearch;
        }

        if (options & XVimSortOptionReversed) {
            return [str2 compare:str1 options:compareOptions];
        } else {
            return [str1 compare:str2 options:compareOptions];
        }
    }];

    if (options & XVimSortOptionRemoveDuplicateLines) {
        NSMutableIndexSet *removeIndices = [NSMutableIndexSet indexSet];
        // At this point the lines are already sorted
        [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            if (idx < [lines count] - 1) {
                NSString *nextStr = [lines objectAtIndex:idx + 1];
                if ([str isEqualToString:nextStr]) {
                    [removeIndices addIndex:idx + 1];
                }
            }
        }];
        [lines removeObjectsAtIndexes:removeIndices];
    }

    NSString  *nl  = buffer.lineEnding;
    NSString  *str = [[lines componentsJoinedByString:nl] stringByAppendingString:nl];

    pos = characterRange.location;
    [buffer beginEditingAtIndex:pos];
    [buffer replaceCharactersInRange:characterRange withString:str];
    [buffer endEditingAtIndex:pos];

    [self _moveCursor:pos preserveColumn:NO];
    [self _syncState];

    [lines release];
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
    return [self.buffer lineNumberAtIndex:index];
}

- (NSUInteger)lineNumberInScrollView:(CGFloat)ratio offset:(NSInteger)offset
{
    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSRect visibleRect = scrollView.contentView.bounds;
    NSPoint point = visibleRect.origin;
    CGFloat glyphHeight = [self _glyphHeightAtIndex:_insertionPoint];

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
	NSRect glyphRect = [self _glyphRectAtIndex:_insertionPoint length:1];

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
    [self _lineUp:_insertionPoint count:count];
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
    [self _lineDown:_insertionPoint count:count];
}

- (void)_scroll:(CGFloat)ratio count:(NSUInteger)count
{
    NSScrollView *scrollView = _textView.enclosingScrollView;
    NSClipView   *clipView   = scrollView.contentView;
    XVimBuffer   *buffer     = self.buffer;

    NSRect  visibleRect = clipView.bounds;
    CGFloat scrollSize  = NSHeight(visibleRect) * ratio * count;
    // This may be beyond the beginning or end of document (intentionally)
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize);

    // Cursor position relative to left-top origin shold be kept after scroll
    // (Exception is when it scrolls beyond the beginning or end of document)

    NSRect  currentInsertionRect = [self _glyphRectAtIndex:_insertionPoint length:1];
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
    [self _moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [self _syncState];
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
    XVimBuffer *buffer = self.buffer;
    NSUInteger pos = _insertionPoint;

    if (lineNumber) {
        if ((pos = [buffer indexOfLineNumber:lineNumber]) == NSNotFound) {
            pos = buffer.length;
        }
    }
    if (fnb) {
        pos = [buffer firstNonblankInLineAtIndex:pos allowEOL:YES];
    }
    [self _moveCursor:pos preserveColumn:NO];
    [self _syncState];

    NSRect glyphRect = [self _glyphRectAtIndex:_insertionPoint length:0];

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

#pragma mark *** Crap to sort ***

- (void)xvim_setWrapsLines:(BOOL)wraps
{
#ifdef __USE_DVTKIT__
    if ([_textView isKindOfClass:[DVTSourceTextView class]]) {
        [(DVTSourceTextView *)_textView setWrapsLines:wraps];
    }
#endif
}

- (void)xvim_hideCompletions
{
#ifdef __USE_DVTKIT__
    if ([_textView isKindOfClass:[DVTSourceTextView class]]) {
        [((DVTSourceTextView *)_textView).completionController hideCompletions];
    }
#endif
}

#pragma mark Search

- (void)xvim_highlightNextSearchCandidate:(NSString *)regex count:(NSUInteger)count
                                   option:(XVimMotionOptions)opt forward:(BOOL)forward
{
    NSTextStorage *ts = _textView.textStorage;
    NSRange range = NSMakeRange(NSNotFound,0);

    if (forward) {
        range = [ts searchRegexForward:regex from:_insertionPoint count:count option:opt];
    }else{
        range = [ts searchRegexBackward:regex from:_insertionPoint count:count option:opt];
    }
    if (range.location != NSNotFound) {
        [self scrollTo:range.location];
        [_textView showFindIndicatorForRange:range];
    }
}

- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(XVimMotionOptions)opt
{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:YES];
}

- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(XVimMotionOptions)opt
{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:NO];
}

- (void)xvim_updateFoundRanges:(NSString*)pattern withOption:(XVimMotionOptions)opt
{
    NSAssert( nil != pattern, @"pattern munst not be nil");

    if (!_needsUpdateFoundRanges) {
        return;
    }

    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
	if  (opt & MOPT_SEARCH_CASEINSENSITIVE) {
		r_opts |= NSRegularExpressionCaseInsensitive;
	}

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:r_opts error:&error];

    if (nil != error) {
        [_foundRanges removeAllObjects];
        return;
    }

    // Find all the maches
    NSString *string = self.buffer.string;
    if (string == nil) {
        return;
    }

    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    [_foundRanges setArray:matches];

    // Clear current highlight.
    [self xvim_clearHighlightText];
    // Add yellow highlight
    for (NSTextCheckingResult *result in self.foundRanges) {
        [_textView.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                                 value:[NSColor yellowColor] forCharacterRange:result.range];
    }

    _needsUpdateFoundRanges = NO;
}

- (void)xvim_clearHighlightText
{
    if (!_needsUpdateFoundRanges) {
        return;
    }

    [_textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                                    forCharacterRange:NSMakeRange(0, self.buffer.length)];
    // [self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor clearColor] forCharacterRange:NSMakeRange(0, string.length)];
    _needsUpdateFoundRanges = NO;
}

- (NSRange)xvim_currentWord:(XVimMotionOptions)opt
{
    return [_textView.textStorage currentWord:_insertionPoint count:1 option:opt|MOPT_TEXTOBJECT_INNER];
}

@end
