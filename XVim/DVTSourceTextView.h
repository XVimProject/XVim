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

+ (id)foldingLogAspect;
+ (id)drawingLogAspect;
+ (void)initialize;
- (void)_reloadAnnotationProviders;
- (void)_unloadAnnotationProviders;
- (void)_updateLayoutEstimation;
- (void)centerOnRange:(struct _NSRange)arg1;
- (void)drawFoundLocationsInRange:(struct _NSRange)arg1;
- (id)_findResultUnderlineColor;
- (id)_findResultCurrentUnderlineColor;
- (id)_findResultGradient;
- (id)_findResultCurrentGradient;
- (void)setCurrentFoundLocation:(id)arg1;
- (void)setFoundLocations:(id)arg1;
- (void)unfoldAllComments:(id)arg1;
- (void)foldAllComments:(id)arg1;
- (void)unfoldAllMethods:(id)arg1;
- (void)foldAllMethods:(id)arg1;
- (void)unfoldRecursive:(id)arg1;
- (void)unfold:(id)arg1;
- (void)unfoldAll:(id)arg1;
- (void)foldSelection:(id)arg1;
- (void)foldRecursive:(id)arg1;
- (void)fold:(id)arg1;
- (BOOL)writeSelectionToPasteboard:(id)arg1 type:(id)arg2;
- (BOOL)writeRTFSelectionToPasteboard:(id)arg1;
- (id)writablePasteboardTypes;
- (void)balance:(id)arg1;
- (void)shiftLeft:(id)arg1;
- (void)shiftRight:(id)arg1;
- (void)_indentSelectionByNumberOfLevels:(long long)arg1;
- (struct _NSRange)_indentInsertedTextIfNecessaryAtRange:(struct _NSRange)arg1;
- (void)showMatchingBraceAtLocation:(id)arg1;
- (void)indentSelectionIfIndentable:(id)arg1;
- (void)indentSelection:(id)arg1;
- (void)commentAndUncommentCurrentLines:(id)arg1;
- (void)moveCurrentLineDown:(id)arg1;
- (void)moveCurrentLineUp:(id)arg1;
- (void)_didChangeSelection:(id)arg1;
- (void)_autoHighlightMatchingBracketAtLocation:(unsigned long long)arg1;
- (void)PBX_toggleShowsInvisibleCharacters:(id)arg1;
- (void)PBX_toggleShowsControlCharacters:(id)arg1;
- (void)useSelectionForReplace:(id)arg1;
- (BOOL)validateMenuItem:(id)arg1;
- (BOOL)validateUserInterfaceItem:(id)arg1;
- (void)layoutManager:(id)arg1 didCompleteLayoutForTextContainer:(id)arg2 atEnd:(BOOL)arg3;
- (id)layoutManager:(id)arg1 shouldUseTemporaryAttributes:(id)arg2 forDrawingToScreen:(BOOL)arg3 atCharacterIndex:(unsigned long long)arg4 effectiveRange:(struct _NSRange *)arg5;
- (void)_centeredScrollRectToVisible:(struct CGRect)arg1 forceCenter:(BOOL)arg2;
- (void)scrollViewFrameChanged;
- (void)viewWillDraw;
- (void)viewWillMoveToWindow:(id)arg1;
- (void)breakUndoCoalescing;
- (void)didChangeText;
- (void)scrollRangeToVisible:(struct _NSRange)arg1 animate:(BOOL)arg2;
- (void)insertText:(id)arg1 replacementRange:(struct _NSRange)arg2;
- (void)flagsChanged:(id)arg1;
- (void)selectPreviousToken:(id)arg1;
- (void)selectNextToken:(id)arg1;
- (void)toggleTokenizedEditing:(id)arg1;
- (id)tokenizedEditingTokenPathsForCharacterRange:(struct _NSRange)arg1;
- (id)tokenPathsForCharacterRange:(struct _NSRange)arg1 displayOnly:(BOOL)arg2;
- (void)textStorage:(id)arg1 didEditRange:(struct _NSRange)arg2 changeInLength:(long long)arg3;
- (void)textStorage:(id)arg1 willEditRange:(struct _NSRange)arg2 changeInLength:(long long)arg3;
- (void)textStorageDidChangeLineNumbers:(id)arg1;
- (void)updateTokenizedEditingRanges;
- (void)_scheduleAutoHighlightTokenTimerIfNeeded;
- (void)_autoHighlightTokenWithTimer:(id)arg1;
- (void)tokenizableItemsForItemAtRealRange:(struct _NSRange)arg1 completionBlock:(id)arg2;
- (void)_scheduleAutoHighlightTokenMenuTimerIfNeeded;
- (void)_showAutoHighlightTokenMenuWithTimer:(id)arg1;
- (id)_autoHighlightTokenWindowWithTokenRect:(struct CGRect)arg1;
- (void)_scheduleAutoHighlightTokenMenuAnimationTimerIfNeeded;
- (struct CGRect)_hitTestRectForAutoHighlightTokenWindow:(id)arg1;
- (struct CGRect)_autoHighlightTokenRectAtPoint:(struct CGPoint)arg1;
- (struct _NSRange)_autoHighlightTokenMenuRangeAtPoint:(struct CGPoint)arg1;
- (void)_animateAutoHighlightTokenMenuWithTimer:(id)arg1;
- (void)_popUpTokenMenu:(id)arg1;
- (id)_autoHighlightTokenMenu;
- (void)_clearAutoHighlightTokenMenu;
- (void)_clearDisplayForAutoHighlightTokens;
- (void)_displayAutoHighlightTokens;
- (void)removeStaticVisualizationView;
- (void)addStaticVisualizationView:(id)arg1;
- (void)removeVisualization:(id)arg1 fadeOut:(BOOL)arg2 completionBlock:(id)arg3;
- (void)addVisualization:(id)arg1 fadeIn:(BOOL)arg2 completionBlock:(id)arg3;
- (void)didInsertCompletionTextAtRange:(struct _NSRange)arg1;
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)arg1;
- (BOOL)shouldSuppressTextCompletion;
- (id)contextForCompletionStrategiesAtWordStartLocation:(unsigned long long)arg1;
- (void)autoInsertCloseBrace;
- (void)deleteExpressionBackward:(id)arg1;
- (void)deleteExpressionForward:(id)arg1;
- (void)moveExpressionBackwardAndModifySelection:(id)arg1;
- (void)moveExpressionBackward:(id)arg1;
- (void)moveExpressionForwardAndModifySelection:(id)arg1;
- (void)moveExpressionForward:(id)arg1;
- (void)deleteSubWordBackward:(id)arg1;
- (void)deleteSubWordForward:(id)arg1;
- (void)moveSubWordBackwardAndModifySelection:(id)arg1;
- (void)moveSubWordForwardAndModifySelection:(id)arg1;
- (void)moveSubWordBackward:(id)arg1;
- (void)moveSubWordForward:(id)arg1;
- (void)deleteForward:(id)arg1;
- (void)deleteBackward:(id)arg1;
- (void)pasteAndMatchStyle:(id)arg1;
- (void)paste:(id)arg1;
- (void)_paste:(id)arg1 indent:(BOOL)arg2;
- (void)insertNewline:(id)arg1;
- (BOOL)handleInsertTab;
- (BOOL)handleSelectPreviousPlaceholder;
- (BOOL)handleSelectNextPlaceholder;
- (void)insertText:(id)arg1;
- (void)setFoldsFromString:(id)arg1;
- (id)foldString;
- (struct CGRect)frameForRange:(struct _NSRange)arg1 ignoreWhitespace:(BOOL)arg2;
- (struct _NSRange)visibleParagraphRange;
- (long long)_currentLineNumber;
- (struct _NSRange)rangeOfCenterLine;
- (void)doingBatchEdit:(BOOL)arg1;
- (void)rightMouseDown:(id)arg1;
- (void)rightMouseUp:(id)arg1;
- (void)mouseDragged:(id)arg1;
- (void)mouseUp:(id)arg1;
- (void)mouseDown:(id)arg1;
- (void)scrollWheel:(id)arg1;
- (void)_clipViewAncestorDidScroll:(id)arg1;
- (void)_finishedAnimatingScroll;
- (void)_toolTipTimer;
- (void)mouseMoved:(id)arg1;
- (void)_mouseInside:(id)arg1;
- (void)removeFromSuperview;
- (void)viewDidMoveToWindow;
- (void)_updateScrollerMarkersWithAnnotations:(id)arg1 clearCurrent:(BOOL)arg2;
- (void)_refreshScrollerMarkers;
- (double)_markForLineNumber:(unsigned long long)arg1;
- (void)setUsesMarkedScrollbar:(BOOL)arg1;
- (id)attributedStringForCompletionPlaceholderCell:(id)arg1 atCharacterIndex:(unsigned long long)arg2 withDefaultAttributes:(id)arg3;
- (void)clickedOnCell:(id)arg1 inRect:(struct CGRect)arg2 atIndexInToken:(unsigned long long)arg3;
- (void)_didClickOnTemporaryLinkWithEvent:(id)arg1;
- (void)_updateTemporaryLinkUnderMouseForEvent:(id)arg1;
- (unsigned long long)_nonBlankCharIndexUnderMouse;
- (void)_clearClickedLinkProgressIndicators;
- (void)_adjustClickedLinkProgressIndicators;
- (void)_adjustClickedLinkProgressIndicator:(id)arg1 withRect:(struct CGRect)arg2;
- (void)_showClickedLinkProgressIndicators;
- (void)_invalidateClickedLinks;
- (id)_clickedLinkProgressIndicatorWithRect:(struct CGRect)arg1;
- (void)_clearTemporaryLinkRanges;
- (void)_setTemporaryLinkRanges:(id)arg1 isAlternate:(BOOL)arg2;
- (void)animation:(id)arg1 didReachProgressMark:(float)arg2;
- (void)animationDidEnd:(id)arg1;
- (void)animationDidStop:(id)arg1;
- (BOOL)animationShouldStart:(id)arg1;
- (void)stopBlockHighlighting;
- (void)startBlockHighlighting;
- (void)focusLocationMayHaveChanged:(id)arg1;
- (void)toggleCodeFocus:(id)arg1;
- (void)_drawViewBackgroundInRect:(struct CGRect)arg1;
- (void)_drawTokensInRect:(struct CGRect)arg1;
- (void)_drawCaretForTextAnnotationsInRect:(struct CGRect)arg1;
- (void)drawTextAnnotationsInRect:(struct CGRect)arg1;
- (long long)_drawRoundedBackgroundForItem:(id)arg1 dynamicItem:(id)arg2;
- (id)_roundedRect:(struct CGRect)arg1 withRadius:(double)arg2;
- (unsigned long long)_drawBlockBackground:(struct CGRect)arg1 atLocation:(unsigned long long)arg2 forItem:(id)arg3 dynamicItem:(id)arg4;
- (double)_grayLevelForDepth:(long long)arg1;
- (id)alternateColor;
- (void)setFoldingHoverRange:(struct _NSRange)arg1;
- (struct _NSRange)foldingHoverRange;
- (void)_loadColorsFromCurrentTheme;
- (void)_themeColorsChanged:(id)arg1;
- (id)currentTheme;
- (void)setFrameSize:(struct CGSize)arg1;
- (void)drawRect:(struct CGRect)arg1;
- (void)_drawRect:(struct CGRect)arg1 clip:(BOOL)arg2;
- (void)_drawOverlayRect:(struct CGRect)arg1;
- (unsigned long long)foldedCharacterIndexForPoint:(struct CGPoint)arg1;
- (void)setSelectedRanges:(id)arg1 affinity:(unsigned long long)arg2 stillSelecting:(BOOL)arg3;
- (void)setSelectedRange:(struct _NSRange)arg1;
- (void)contextMenu_toggleMessageBubbleShown:(id)arg1;
- (void)toggleMessageBubbleShown:(id)arg1;
- (void)_enumerateMessageBubbleAnnotationsInSelection:(id)arg1;
- (void)setAccessoryAnnotationWidth:(unsigned long long)arg1;
- (void)_updateAccessoryAnnotationViews;
- (void)_adjustSizeOfAccessoryAnnotation:(id)arg1;
- (void)showAnnotation:(id)arg1 animateIndicator:(BOOL)arg2;
- (void)_animateBubbleView:(id)arg1;
- (void)didRemoveAnnotations:(id)arg1;
- (void)didAddAnnotations:(id)arg1;
- (id)visibleAnnotationsForLineNumberRange:(struct _NSRange)arg1;
- (id)annotationForRepresentedObject:(id)arg1;
- (void)setShowsFoldingSidebar:(BOOL)arg1;
- (BOOL)showsFoldingSidebar;
- (void)getParagraphRect:(struct CGRect *)arg1 firstLineRect:(struct CGRect *)arg2 forLineRange:(struct _NSRange)arg3 ensureLayout:(BOOL)arg4;
- (struct _NSRange)lineNumberRangeForBoundingRect:(struct CGRect)arg1;
- (unsigned long long)lineNumberForPoint:(struct CGPoint)arg1;
- (id)printJobTitle;
- (id)language;
- (BOOL)allowsCodeFolding;
- (void)setAllowsCodeFolding:(BOOL)arg1;
- (void)setTextStorage:(id)arg1;
- (void)setTextStorage:(id)arg1 keepOldLayout:(BOOL)arg2;
- (id)textStorage;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1 textContainer:(id)arg2;
- (id)init;
- (void)_commonInitDVTSourceTextView;
- (BOOL)_removeMenusNotInWhiteList:(id)arg1 fromMenu:(id)arg2;
- (id)menuForEvent:(id)arg1;
- (double)fmc_maxY;
- (double)fmc_startOfLine:(long long)arg1;
- (long long)fmc_lineNumberForPosition:(double)arg1;
- (BOOL)shouldIndentPastedText:(id)arg1;
- (void)indentUserChangeBy:(long long)arg1;
- (void)viewDidEndLiveResize;
- (void)viewWillStartLiveResize;
- (void)setMarkedText:(id)arg1 selectedRange:(struct _NSRange)arg2;
- (BOOL)shouldChangeTextInRanges:(id)arg1 replacementStrings:(id)arg2;
- (BOOL)scrollRectToVisible:(struct CGRect)arg1;
- (void)scrollPoint:(struct CGPoint)arg1;
- (void)updateInsertionPointStateAndRestartTimer:(BOOL)arg1;
- (void)scrollRangeToVisible:(struct _NSRange)arg1;
- (void)resignKeyWindow;
- (BOOL)resignFirstResponder;
- (void)_invalidateDisplayForViewStatusChange;
- (void)_invalidateAllRevealovers;

- (void)setWrapsLines:(BOOL)arg1;
- (BOOL)wrapsLines;
- (void)selectNextPlaceholder:(id)sender;

- (DVTCompletionController*)completionController;
- (DVTUndoManager*)undoManager;

////////////////////////////////////////////////////////

- (void)setSelectedRange:(NSRange)charRange;
- (void)setSelectedRange_:(NSRange)charRange;

- (void)setSelectedRange:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag;
- (void)setSelectedRange_:(NSRange)charRange affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelectingFlag;

- (id)initWithCoder_:(NSCoder *)aDecoder;

- (void)viewDidMoveToSuperview;
- (void)viewDidMoveToSuperview_;

- (void)keyDown:(NSEvent *)theEvent;
- (void)keyDown_:(NSEvent *)theEvent;

- (void)mouseDown_:(NSEvent *)theEvent;
- (void)mouseUp_:(NSEvent *)theEvent;
- (void)mouseDragged_:(NSEvent *)theEvent;

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

- (BOOL)becomeFirstResponder;
- (BOOL)becomeFirstResponder_;

- (void)observeValueForKeyPath_:(NSString *)keyPath 
					   ofObject:(id)object 
						 change:(NSDictionary *)change 
						context:(void *)context;

@end
