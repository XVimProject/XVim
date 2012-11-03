//
//  XVimTextView.h
//  XVim
//
//  Created by Suzuki Shuichiro on 9/19/12.
//
//

#import "XVimVisualMode.h"
#import "XVimMotion.h"
#import <Foundation/Foundation.h>

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/


typedef enum _OPERATION_OPTION{
    OPTION_NONE,
}OPERATION_OPTION;

@protocol XVimTextViewProtocol <NSObject>
@property(readonly) NSUInteger insertionPoint;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionPreservedColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) NSUInteger selectionAreaStart;
@property(readonly) NSUInteger selectionAreaEnd;
@property(readonly) VISUAL_MODE selectionMode;
@property(readonly) NSUInteger preservedColumn;
@property(readonly) NSString* string;

- (void)startSelection:(VISUAL_MODE)mode;
- (void)endSelection;
- (void)changeSelectionMode:(VISUAL_MODE)mode;

// Direct Motion
- (void)moveCursor:(NSUInteger)pos; // Avoid using this method. This is here only for compatibility reason

// Top Level Operation Interface
- (void)move:(XVimMotion*)motion;
- (void)delete:(XVimMotion*)motion;
- (void)yunk:(XVimMotion*)motion;
- (void)swapCase:(XVimMotion*)motion; // Previously this is named "toggleCase" in XVim
- (void)makeLowerCase:(XVimMotion*)motion; // Previously this is named "lowerCase" in XVim
- (void)makeUpperCase:(XVimMotion*)motion; // Previously this is named "lowerCase" in XVim
- (void)filter:(XVimMotion*)motion;
- (void)shiftRight:(XVimMotion*)motion;
- (void)shiftLeft:(XVimMotion*)motion;
- (void)insertNewlineBelow;
- (void)insertNewlineAbove;

// Premitive Operations ( Avoid using following. Consider use or make Top Level Operation Interface instead )
- (void)moveBack:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveFoward:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveDown:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveUp:(NSUInteger)count option:(MOTION_OPTION)opt;
//- (void)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info;
- (void)moveWordsBackward:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveSentencesForward:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveSentencesBackward:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveParagraphsForward:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)moveParagraphsBackward:(NSUInteger)count option:(MOTION_OPTION)opt;

// Case changes. These functions are all range checked.
- (void)toggleCase;
- (void)upperCase;
- (void)lowerCase;
- (void)toggleCaseForRange:(NSRange)range;
- (void)upperCaseForRange:(NSRange)range;
- (void)lowerCaseForRange:(NSRange)range;

// Scrolls
- (void)scrollPageForward:(NSUInteger)count;
- (void)scrollPageBackward:(NSUInteger)count;
- (void)scrollHalfPageForward:(NSUInteger)count;
- (void)scrollHalfPageBackward:(NSUInteger)count;
- (void)scrollLineForward:(NSUInteger)count;
- (void)scrollLineBackward:(NSUInteger)count;




@end
