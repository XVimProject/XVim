//
//  Created by pebble on 2017/06/13.
//

#import <Foundation/Foundation.h>
#import "SourceEditor.h"
#import "XVimTextViewProtocol.h"
#import "NSTextStorage+VimOperation.h"
#import <Cocoa/Cocoa.h>
#import "DVTKit.h"
#import "IDEKit.h"
#import "Utils.h"
#import "NSString+VimHelper.h"
#import "NSObject+ExtraData.h"
#import "NSTextView+VimOperation.h"
#import "NSTextStorage+VimOperation.h"
#import "Logger.h"
#import "XVimMacros.h"
#import "XVimOptions.h"
#import <objc/message.h>

@class XVimWindow;

@interface _TtC12SourceEditor16SourceEditorView (XVim)
+ (void)xvim_initialize;
+ (void)xvim_finalize;

@end

@interface _TtC12SourceEditor16SourceEditorView (VimOperation)
// TODO: Method names in category should have prefix like xvim_
#pragma mark Properties
// Make sure that these property names are not conflicting to the properties in NSTextView
@property(readonly) NSUInteger insertionPoint;
@property(readonly) XVimPosition insertionPosition;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger preservedColumn;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) XVimPosition selectionBeginPosition;
@property(readonly) NSUInteger numberOfSelectedLines;
@property(readonly) XVIM_VISUAL_MODE selectionMode;
@property(readonly) BOOL selectionToEOL;
@property(readonly) CURSOR_MODE cursorMode;
//@property(readonly) NSURL* documentURL;
@property(strong) id<XVimTextViewDelegateProtocol> xvimDelegate;
@property BOOL needsUpdateFoundRanges;
@property(readonly) NSArray* foundRanges;
@property(readonly) long long currentLineNumber;

- (NSString*)xvim_string;
#pragma mark Changing state
- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
- (void)xvim_escapeFromInsert;
- (void)xvim_setWrapsLines:(BOOL)wraps;

#pragma mark Operations (Has effect to internal state)
- (void)xvim_adjustCursorPosition;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_moveToPosition:(XVimPosition)pos;
- (void)xvim_move:(XVimMotion*)motion;
- (void)xvim_selectSwapEndsOnSameLine:(BOOL)onSameLine;
- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank;
- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank;
- (BOOL)xvim_change:(XVimMotion*)motion;
- (void)xvim_yank:(XVimMotion*)motion;
- (void)xvim_yank:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint;
- (void)xvim_copymove:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint withInsertionPoint:(NSUInteger)insertionPoint after:(BOOL)after onlyCopy:(BOOL)onlyCopy;
- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count;
- (void)xvim_swapCase:(XVimMotion*)motion;
- (void)xvim_makeLowerCase:(XVimMotion*)motion;
- (void)xvim_makeUpperCase:(XVimMotion*)motion;
- (BOOL)xvim_replaceCharacters:(unichar)c count:(NSUInteger)count;
- (void)xvim_join:(NSUInteger)count addSpace:(BOOL)addSpace;
- (void)xvim_filter:(XVimMotion*)motion;
- (void)xvim_shiftRight:(XVimMotion*)motion;
- (void)xvim_shiftRight:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count;
- (void)xvim_shiftLeft:(XVimMotion*)motion;
- (void)xvim_shiftLeft:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count;
- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column;
- (void)xvim_insertNewlineBelowLine:(NSUInteger)line;
- (void)xvim_insertNewlineBelowCurrentLine;
- (void)xvim_insertNewlineBelowCurrentLineWithIndent;
- (void)xvim_insertNewlineAboveLine:(NSUInteger)line;
- (void)xvim_insertNewlineAboveCurrentLine;
- (void)xvim_insertNewlineAboveCurrentLineWithIndent;
- (void)xvim_insertNewlineAboveAndInsertWithIndent;
- (void)xvim_insertNewlineBelowAndInsertWithIndent;
- (void)xvim_insert:(XVimInsertionPoint)mode blockColumn:(NSUInteger *)column blockLines:(XVimRange *)lines;
- (void)xvim_overwriteCharacter:(unichar)c;
- (BOOL)xvim_incrementNumber:(int64_t)offset;
- (void)xvim_blockInsertFixupWithText:(NSString *)text mode:(XVimInsertionPoint)mode
                                count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines;

/**
 * Sort specified lines.
 *    line1 - line beginning
 *    line2 - line end
 * The lines must be greater than 0 (Line number starts from 1)
 * line2 can be less than line1
 * If the range of lines exceeds the maximu line number of the text
 * it sorts lines up to end of the text.
 * If the range is out of range of current text it does nothing.
 **/
- (void)xvim_sortLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2 withOptions:(XVimSortOptions)options;
- (void)xvim_selectNextPlaceholder;
- (void)xvim_hideCompletions;

#pragma mark Scroll
- (NSUInteger)xvim_lineUp:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)xvim_lineDown:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_scroll:(CGFloat)ratio count:(NSUInteger)count;
- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)xvim_scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)xvim_scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)xvim_scrollTo:(NSUInteger)location;
- (void)xvim_pageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_pageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_halfPageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_halfPageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_scrollPageForward:(NSUInteger)count;
- (void)xvim_scrollPageBackward:(NSUInteger)count;
- (void)xvim_scrollHalfPageForward:(NSUInteger)count;
- (void)xvim_scrollHalfPageBackward:(NSUInteger)count;
- (void)xvim_scrollLineForward:(NSUInteger)count;
- (void)xvim_scrollLineBackward:(NSUInteger)count;

#pragma mark Search
/**
 * Shows the candidate of the next search result.
 **/
- (void)xvim_highlightNextSearchCandidate:(NSString *)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward;
- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)xvim_updateFoundRanges:(NSString*)pattern withOption:(MOTION_OPTION)opt;
- (void)xvim_clearHighlightText;
- (NSRange)xvim_currentWord:(MOTION_OPTION)opt;
- (NSRange)xvim_currentNumber;

#pragma mark Searching positions
// TODO: Thses method should be internal. Create abstracted interface to achieve the operation uses these methods.
/**
 * Takes point in view and returns its index.
 * This method automatically convert the "folded index" to "real index"
 * When some characters are folded( like placeholders) the pure index for a specifix point is
 * less than real index in the string.
 **/
- (NSUInteger)xvim_glyphIndexForPoint:(NSPoint)point;
- (NSRect)xvim_boundingRectForGlyphIndex:(NSUInteger)glyphIndex;

/**
 * Return number of lines in current visible view.
 * This means the capacity of the view to show lines and not actually showing now.
 * For example the view is 100px height and 1 line is 10px then this returns 10
 * even there are only 2 lines in current view.
 *
 * TODO: This assumes that all the lines in a view has same text height.
 *       I thinks this is not bad assumption but there may be a situation the assumption does not work.
 **/
- (NSUInteger)xvim_numberOfLinesInVisibleRect;

- (NSUInteger)xvim_lineNumberFromTop:(NSUInteger)count;
- (NSUInteger)xvim_lineNumberFromBottom:(NSUInteger)count;

- (void)xvim_syncStateFromView; // update our instance variables with self's properties
- (IDEEditorArea*)xvim_editorArea;
- (XVimWindow*)xwim_window;

- (void)setXvimDelegate:(id)xvimDelegate;
- (id)xvimDelegate;

@end
