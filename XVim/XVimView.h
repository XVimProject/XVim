//
//  XVimView.h
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <Cocoa/Cocoa.h>
#import "XVimDefs.h"
#import "XVimMotion.h"

@class XVimView, XVimBuffer, XVimWindow;

@interface NSTextView (XVimView)
@property (readonly, nonatomic) XVimView *xvim_view;

- (XVimView *)xvim_makeXVimViewInWindow:(XVimWindow *)window;
@end

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/

@protocol XVimTextViewDelegateProtocol
- (void)textView:(NSTextView*)view didYank:(NSString*)yankedText withType:(TEXT_TYPE)type;
- (void)textView:(NSTextView*)view didDelete:(NSString*)deletedText withType:(TEXT_TYPE)type;
@end

/** @brief XVimView class, representing one XVim View
 *
 * An XVim View is more or less what a window is in vim, namely a view
 * on a given buffer (TextStorage). You can have several views on the same buffer.
 *
 * This is actually grafted on top of an NSTextView that it hooks to give it
 * vim-like capabilities.
 */
@interface XVimView : NSObject
@property (readonly, nonatomic) XVimWindow *window;
@property (readonly, nonatomic) NSTextView *textView;
@property (readonly, nonatomic) XVimBuffer *buffer;
@property (strong,   nonatomic) id<XVimTextViewDelegateProtocol> delegate;

- (instancetype)initWithView:(NSTextView *)view window:(XVimWindow *)window;

#pragma mark *** Properties  ***

@property (readonly, nonatomic) NSUInteger     insertionPoint;
@property (readonly, nonatomic) XVimPosition   insertionPosition;
@property (readonly, nonatomic) NSUInteger     insertionColumn;
@property (readonly, nonatomic) NSUInteger     insertionLine;

@property (readonly, nonatomic) NSUInteger     selectionBegin;
@property (readonly, nonatomic) XVimPosition   selectionPosition;
@property (readonly, nonatomic) NSUInteger     selectionColumn;
@property (readonly, nonatomic) NSUInteger     selectionLine;

@property (nonatomic)           XVimVisualMode selectionMode;
@property (readonly, nonatomic) BOOL           inVisualMode; /* != VISUAL_NONE  */
@property (readonly, nonatomic) BOOL           inBlockMode;  /* == VISUAL_BLOCK */

@property (nonatomic, readonly) BOOL           needsUpdateFoundRanges;
@property (nonatomic, readonly) NSArray       *foundRanges;

#pragma mark *** Visual Mode and Cursor Position ***

- (void)escapeFromInsertAndMoveBack:(BOOL)moveBack;

- (void)selectSwapCorners:(BOOL)onSameLine;

- (void)saveVisualInfoForBuffer:(XVimBuffer *)buffer;

- (void)selectNextPlaceholder;
- (void)selectPreviousPlaceholder;
- (void)adjustCursorPosition;

- (void)moveCursorToIndex:(NSUInteger)index;
- (void)moveCursorToPosition:(XVimPosition)index;
- (void)moveCursorWithMotion:(XVimMotion *)motion;

#pragma mark *** Operations ***

- (void)doDelete:(XVimMotion *)motion andYank:(BOOL)yank;
- (void)doChange:(XVimMotion *)motion;
- (void)doYank:(XVimMotion*)motion;
- (void)doPut:(NSString *)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count;
- (void)doSwapCharacters:(XVimMotion *)motion mode:(int)mode;
- (BOOL)doReplaceCharacters:(unichar)c count:(NSUInteger)count;
- (void)doJoin:(NSUInteger)count addSpace:(BOOL)addSpace;
- (void)doFilter:(XVimMotion *)motion;
- (void)doShift:(XVimMotion *)motion right:(BOOL)right;
- (void)insertNewlineAboveAndInsertWithIndent;
- (void)insertNewlineBelowAndInsertWithIndent;
- (void)doInsert:(XVimInsertionPoint)mode blockColumn:(NSUInteger *)column blockLines:(XVimRange *)lines;
- (BOOL)doIncrementNumber:(int64_t)offset;
- (void)doInsertFixupWithText:(NSString *)text mode:(XVimInsertionPoint)mode
                        count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines;
- (void)doSortLines:(XVimRange)range withOptions:(XVimSortOptions)options;

#pragma mark *** Drawing ***

- (NSUInteger)lineNumberInScrollView:(CGFloat)ratio offset:(NSInteger)offset;

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color
                     heightRatio:(CGFloat)heightRatio
                      widthRatio:(CGFloat)widthRatio
                           alpha:(CGFloat)alpha;

#pragma mark *** Scrolling ***

- (void)scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollTo:(NSUInteger)location;
- (void)scrollPageForward:(NSUInteger)count;
- (void)scrollPageBackward:(NSUInteger)count;
- (void)scrollHalfPageForward:(NSUInteger)count;
- (void)scrollHalfPageBackward:(NSUInteger)count;
- (void)scrollLineForward:(NSUInteger)count;
- (void)scrollLineBackward:(NSUInteger)count;

#pragma mark *** Crap to sort ***

- (void)xvim_setWrapsLines:(BOOL)wraps;
- (void)xvim_hideCompletions;
- (void)xvim_highlightNextSearchCandidate:(NSString *)regex count:(NSUInteger)count
                                   option:(XVimMotionOptions)opt forward:(BOOL)forward;
- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(XVimMotionOptions)opt;
- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(XVimMotionOptions)opt;
- (void)xvim_updateFoundRanges:(NSString*)pattern withOption:(XVimMotionOptions)opt;
- (void)xvim_clearHighlightText;
- (NSRange)xvim_currentWord:(XVimMotionOptions)opt;

@end
