//
//  XVimSourceView.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//
#import "XVimTextViewProtocol.h"

/**
 
 XVimSourceView presents an editing interface to XVim for the underlying
 NSTextView object.
 
 All methods in here must depend directly on NSTextView.
 
 If they depend on Xcode functionality (DVTSourceTextView), they should be in
 XVimSourceView+Xcode.
 
 If they depend only on other public functions, they should be in
 XVimSourceView+Vim.
 
 **/

typedef enum {
    CURSOR_MODE_INSERT,
    CURSOR_MODE_COMMAND
}CURSOR_MODE;

@interface XVimSourceView : NSObject <XVimTextViewProtocol>
@property(readonly) NSString* string;
@property(readonly) NSUInteger insertionPoint;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionPreservedColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) NSUInteger selectionAreaStart;
@property(readonly) NSUInteger selectionAreaEnd;
@property(readonly) NSUInteger preservedColumn;
@property(readonly) VISUAL_MODE selectionMode;
@property CURSOR_MODE cursorMode;

- (id)initWithView:(NSTextView*)view;

// Returns the attached view (DO NOT USE IT IN NEWLY CREATED CODE)
- (NSTextView*)view;

// Selection ( DO NOT USE IN NEWLY CREATED CODE (except in XVimWindow class))
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)range;

// Utility Methods - These method uses XVimTextViewProtocol to perform its role.
- (void)moveForward;
- (void)moveBackward;
- (void)moveToBeginningOfLine;
- (void)moveToEndOfLine;


// NSTextView functions (Do not use following methods)
- (void)copyText;
- (void)deleteText;
- (void)cutText;
- (void)undo;
- (void)redo;
- (void)moveUp;
- (void)moveDown;
- (void)moveForwardAndModifySelection;
- (void)moveBackwardAndModifySelection;
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

