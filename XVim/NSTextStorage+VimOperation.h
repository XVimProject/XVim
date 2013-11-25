//
//  NSTextStorage+VimOperation.h
//  XVim
//
//  Created by Suzuki Shuichiro on 7/30/13.
//
//


#import "XVimMotion.h"
#import "XVimDefs.h"
#import "XVimTextStoring.h"

/**
 VimOperation category on NSTextStorage
 Adds Vim-like functionality to NSTextStorage.
 **/

@interface NSTextStorage (VimOperation)

#pragma mark Definitions

// Determine if the position specified with "index" is white space.
- (BOOL) isWhitespace:(NSUInteger)index;

// Determine if the position is non blank character
// EOF is a blank character
- (BOOL) isNonblank:(NSUInteger)index;

#pragma mark Vim operation related methods

- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info;

/**
 * Returns the position when a cursor goes to upper line.
 * @param index the position of the cursor
 * @param column the desired position of the column in previous line
 * @param count number of repeat
 * @param opt currntly nothing is supported
 * @return The position to move to. If the current index is on the first line it returns 0
 *
 * "column" may be greater then number of characters in the current line.
 * Assume that you have following text.
 *     abcd
 *     ef
 *     12345678
 * When a cursor at character "4" goes up cursor will go at "f".
 * When a cursor goes up agein it should got at d. (This is default Vim motion)
 * To keep the column position you have to specifi the "column" argument.
 *
 **/
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;

/**
 * See prevLine's description for meaning of arguments
 **/
- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;

/**
 * Returns position of the head of count words forward and an info structure that handles the end of word boundaries.
 * @param index
 * @param count
 * @param option MOTION_OPTION_NONE or BIGWORD
 * @param info This is used with special cases explaind above such as 'cw' or 'w' crossing over the newline.
 **/
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info;


- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)endOfWordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt; //e,E
- (NSUInteger)endOfWordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt; //ge,gE
- (NSUInteger)sentencesForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)sentencesBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)moveFromIndex:(NSUInteger)index paragraphs:(NSInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)nextCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt;
- (NSUInteger)prevCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt;

// Search starts from 'index+1' to the end of the string
- (NSRange)searchRegexForward:(NSString*)regex from:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
// Search starts from 'index-1' to the beginning of the string
- (NSRange)searchRegexBackward:(NSString*)regex from:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;


/**
 * This does all the work need to do with vim '%' motion.
 * Find match pair character in the line and find the corresponding pair.
 * Returns NSNotFound if not found.
 **/
- (NSUInteger)positionOfMatchedPair:(NSUInteger)pos;

#pragma mark Text Object
// TODO: Following code should be rewritten
- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
// The following code is from xVim by WarWithinMe.
// These will be integreted into NSTextView category.

// =======================
// Unlike vim, this function won't ignore indent before the current character
// even if what is '{'
NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what, char other);
NSRange xv_current_quote(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what);

@end
