//
//  XVimTextView.h
//  XVim
//
//  Created by Suzuki Shuichiro on 9/19/12.
//
//

#import "XVimVisualMode.h"
#import "XVimMotion.h"
#import "XVimRegister.h"
#import "XVimText.h"
#import <Foundation/Foundation.h>

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/


@protocol XVimTextViewDelegate <NSObject>
- (void)textYanked:(NSString*)yankedText withType:(TEXT_TYPE)type inView:(id)view;
- (void)textDeleted:(NSString*)deletedText withType:(TEXT_TYPE)type inView:(id)view;
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
@property(readonly) NSUInteger insertionPreservedColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) VISUAL_MODE selectionMode;
@property(readonly) CURSOR_MODE cursorMode;
@property(readonly) NSUInteger preservedColumn;

// Delegates
@property(strong) id<XVimTextViewDelegate> delegate;


// Selection Mode
- (void)changeSelectionMode:(VISUAL_MODE)mode;




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
- (void)insertNewlineBelow;
- (void)insertNewlineAboveLine:(NSUInteger)line;
- (void)insertNewlineAbove;
- (void)insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column;

// Insert or Command
- (void)escapeFromInsert;
- (void)append;
- (void)insert;
- (void)appendAtEndOfLine;
- (void)insertBeforeFirstNonBlank;

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

// Case changes. These functions are all range checked.
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
