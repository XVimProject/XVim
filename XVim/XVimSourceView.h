//
//  XVimSourceView.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

/**
 
 XVimSourceView presents an editing interface to XVim for the underlying
 NSTextView object.
 
 All methods in here must depend directly on NSTextView.
 
 If they depend on Xcode functionality (DVTSourceTextView), they should be in
 XVimSourceView+Xcode.
 
 If they depend only on other public functions, they should be in
 XVimSourceView+Vim.
 
 **/

@interface XVimSourceView : NSObject

- (id)initWithView:(NSView*)view;

// Returns the attached view
- (NSView*)view;

// Returns the internal string
- (NSString*)string;

// Selection
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)range;

// NSTextView functions
- (void)copyText;
- (void)deleteText;
- (void)cutText;
- (void)undo;
- (void)redo;
- (void)moveUp;
- (void)moveDown;
- (void)moveForward;
- (void)moveForwardAndModifySelection;
- (void)moveBackward;
- (void)moveBackwardAndModifySelection;
- (void)moveToBeginningOfLine;
- (void)moveToEndOfLine;
- (void)deleteForward;
- (void)insertText:(NSString*)text;
- (void)insertText:(NSString*)text replacementRange:(NSRange)range;
- (void)insertNewline;

- (NSColor *)insertionPointColor;

// Scrolling
- (NSUInteger)halfPageDown:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)halfPageUp:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)lineDown:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)lineUp:(NSUInteger)index count:(NSUInteger)count;
- (void)pageUp;
- (void)pageDown;
- (void)scrollTo:(NSUInteger)location;

// Shows the yellow find indicator for given range
- (void)showFindIndicatorForRange:(NSRange)range;

// Drawing
- (NSUInteger)glyphIndexForPoint:(NSPoint)point;
- (NSRect)boundingRectForGlyphIndex:(NSUInteger)glyphIndex;
 
@end

