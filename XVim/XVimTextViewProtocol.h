//
//  XVimTextView.h
//  XVim

//
//  Created by Suzuki Shuichiro on 9/19/12.
//
//

#import "XVim.h"
#import "XVimMotion.h"
#import "XVimRegister.h"
#import <Foundation/Foundation.h>

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/

@protocol XVimTextViewDelegateProtocol
- (void)textView:(NSTextView*)view didYank:(NSString*)yankedText withType:(TEXT_TYPE)type;
- (void)textView:(NSTextView*)view didDelete:(NSString*)deletedText withType:(TEXT_TYPE)type;
@end

typedef enum {
    CURSOR_MODE_INSERT,
    CURSOR_MODE_COMMAND
}CURSOR_MODE;

typedef enum {
    OPTION_NONE,
}OPERATION_OPTION;

@protocol XVimTextViewProtocol <NSObject>
@property(readonly) NSUInteger insertionPoint;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) XVIM_VISUAL_MODE selectionMode;
@property(readonly) NSUInteger selectedLines;  // Number of lines selected (0 if not in selection mode)
@property(readonly) NSUInteger selectedColumns; // Number of columns selected (0 if not in selection mode)
@property(readonly) CURSOR_MODE cursorMode;
@property(readonly) NSUInteger preservedColumn;

// Selection Mode
- (void)changeSelectionMode:(XVIM_VISUAL_MODE)mode;




// Top Level Operation Interface
- (void)move:(XVimMotion*)motion;
- (void)delete:(XVimMotion*)motion;
- (void)change:(XVimMotion*)motion;
- (void)yank:(XVimMotion*)motion;
- (void)put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)times;
- (void)swapCase:(XVimMotion*)motion; // Previously this is named "toggleCase" in XVim
- (void)makeLowerCase:(XVimMotion*)motion; // Previously this is named "lowerCase" in XVim
- (void)makeUpperCase:(XVimMotion*)motion; // Previously this is named "lowerCase" in XVim
- (void)filter:(XVimMotion*)motion;
- (void)shiftRight:(XVimMotion*)motion;
- (void)shiftLeft:(XVimMotion*)motion;
- (void)join:(NSUInteger)count;
- (void)insertNewlineBelowLine:(NSUInteger)line;
- (void)insertNewlineAboveLine:(NSUInteger)line;
- (void)insertNewlineAbove;
- (void)insertNewlineBelow;
- (void)insertNewlineAboveAndInsert;
- (void)insertNewlineBelowAndInsert;
- (void)insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column;
- (BOOL)replaceCharacters:(unichar)c count:(NSUInteger)count;

// Insert or Command
- (void)escapeFromInsert;
- (void)append;
- (void)insert;
- (void)appendAtEndOfLine;
- (void)insertBeforeFirstNonblank;

// for keydown in insertion
- (void)passThroughKeyDown:(NSEvent*)event;

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

- (void)overwriteCharacter:(unichar)c;


- (void)moveToPosition:(XVimPosition)pos;

// Scrolls
- (void)scrollPageForward:(NSUInteger)count;
- (void)scrollPageBackward:(NSUInteger)count;
- (void)scrollHalfPageForward:(NSUInteger)count;
- (void)scrollHalfPageBackward:(NSUInteger)count;
- (void)scrollLineForward:(NSUInteger)count;
- (void)scrollLineBackward:(NSUInteger)count;
- (void)scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;;
- (void)scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;;



@end
