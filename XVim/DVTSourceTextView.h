//
//  DVTSourceTextView.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DVTFoldingTextStorage;
@class DVTCompletionController;
@class DVTUndoManager;

@interface DVTSourceTextView : NSTextView

- (void)shiftRight:(id)sender;
- (void)shiftLeft:(id)sender;

- (void)setWrapsLines:(BOOL)wraps;
- (int)_currentLineNumber;

- (void)selectNextPlaceholder:(id)sender;

- (DVTFoldingTextStorage*)textStorage;
- (DVTCompletionController*)completionController;
- (DVTUndoManager*)undoManager;

////////////////////////////////////////////////////////

- (void)setSelectedRange:(NSRange)charRange;
- (void)setSelectedRange_:(NSRange)charRange;

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag;
- (void)setSelectedRange_:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithCoder_:(NSCoder *)aDecoder;

- (void)viewDidMoveToSuperview;
- (void)viewDidMoveToSuperview_;

- (void)keyDown:(NSEvent *)theEvent;
- (void)keyDown_:(NSEvent *)theEvent;

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDown_:(NSEvent *)theEvent;

- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseUp_:(NSEvent *)theEvent;

- (void)drawRect:(NSRect)dirtyRect;
- (void)drawRect_:(NSRect)dirtyRect;

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (BOOL)performKeyEquivalent_:(NSEvent *)theEvent;

- (BOOL)shouldDrawInsertionPoint;
- (BOOL)shouldDrawInsertionPoint_;

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)aColor turnedOn:(BOOL)flag;
- (void)drawInsertionPointInRect_:(NSRect)rect color:(NSColor*)aColor turnedOn:(BOOL)flag;

- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor*)aColor;
- (void)_drawInsertionPointInRect_:(NSRect)rect color:(NSColor*)aColor;

- (void)doCommandBySelector:(SEL)aSelector;
- (void)doCommandBySelector_:(SEL)aSelector;


@end
