//
//  NSTextView+VimMotion.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "XVimMotionType.h"

////////////////////////
// Term Definitions   //
////////////////////////

/**
 * "Character"
 * Characgter is a one unichar value. (any value including tabs,spaces)
 *
 * "EOF"
 * EOF is the position at the end of document(text).
 * If we have NSTextView with string "abc" the EOF is just AFTER the 'c'.
 * The index of EOF is 3 in this case ( index is 0 based ).
 * What we have to think about is a cursor can be on the EOF(when the previous letter is newline) but characterAtIndex: with index of EOF cause an exception.
 * We have to be careful about it when calculate and find the position of some motions.
 *
 * "Newline"
 * Newline is defined as "unichar determined by isNewLine function". Usually "\n" or "\r".
 *
 * "Line"
 * Line is a sequence of characters terminated by newline or EOF. "Line" includes the last newline character.
 *
 * "Blankline"
 * Blankline is a line which has only newline or EOF. In other words, it is newline character or EOF after newline character.
 *
 * "End of Line(EOL)"
 * End of line is the last character of a line EXCLUDING newline character.
 * This means that blankline does NOT have an end of line.
 *
 * "Head of Line"
 * Head of line is the first character of a line excluding newline character.
 * This means that blankline does NOT have a head of line.
 *
 * "Tail of Line"
 * Tail of Line is newline or EOF character at the end of a line.
 *
 *
 *
 **/

typedef enum{
    MOTION_OPTION_NONE,
    LEFT_RIGHT_WRAP,
    LEFT_RIGHT_NOWRAP,
    BIGWORD // for 'WORD' motion
} MOTION_OPTION;

typedef struct _XVimWordInfo{
    BOOL isFirstWordInALine;
    NSUInteger lastEndOfLine;
    NSUInteger lastEndOfWord;
}XVimWordInfo;

BOOL isDigit(unichar ch);
BOOL isAlpha(unichar ch);
BOOL isDelimeter(unichar ch);
BOOL isWhiteSpace(unichar ch);
BOOL isNonAscii(unichar ch);
BOOL isNewLine(unichar ch);
BOOL isFuzzyWord(unichar ch);
BOOL isNonBlank(unichar ch);
BOOL isKeyword(unichar ch);

@interface NSTextView (VimMotion)

// Support Methods

// Determine if the position specified with "index" is EOF.
- (BOOL) isEOF:(NSUInteger)index;

// Determine if the posiion is last character of the document
- (BOOL) isLastCharacter:(NSUInteger)index;
    
// Determine if the position specified with "index" is EOL.
- (BOOL) isEOL:(NSUInteger)index;

// Determine if the position specified with "index" is newline.
- (BOOL) isNewLine:(NSUInteger)index;

// Determine if the position specified with "index" is white space.
- (BOOL) isWhiteSpace:(NSUInteger)index;

/**
 * Determine if the position specified with "index" is blankline.
 * Blankline is one of them
 *   - Newline after Newline. Ex. Second '\n' in "abc\n\nabc" is a blankline. First one is not.  
 *   - Newline at begining of the document.
 *   - EOF after Newline. Ex. The index 4 of "abc\n" is blankline. Note that index 4 is exceed the string length. But the cursor can be there.
 *   - EOF of 0 sized document.
 **/
- (BOOL) isBlankLine:(NSUInteger)index;

/**
 * Determine if the position specified with "index" is an empty line.
 * Empty line is one of them
 *   - Blankline
 *   - Only whitespace followed by Newline.
 **/
- (BOOL) isEmptyLine:(NSUInteger)index;


/**
 * Determine if the position specified with "index" is valid cursor position in normal mode.
 * Valid position is followings
 *   - Non newline characters.
 *   - Blankline( including EOF after newline )
 **/
- (BOOL) isValidCursorPosition:(NSUInteger)index;

/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
 **/
- (void)adjustCursorPosition;

/**
 * Returns next non-blank character position after the position "index" in a current line.
 * If no non-blank character is found or the line is a blank line this returns NSNotFound.
 * NOTE: This searches non blank characters from "index" and NOT "index+1"
 *       If the character at "index" is non blank this returns "index" itself
 **/ 
- (NSUInteger)nextNonBlankInALine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the first newline character when searching forwards from "index+1"
 * Searching starts from position "index"+1. The position index is not included to search newline.
 * Returns NSNotFound if no newline character is found.
 **/
- (NSUInteger)nextNewLine:(NSUInteger)index; 

/**
 * Returns position of the first newline character when searching backwards from "index-1"
 * Searching starts from position "index"-1. The position index is not included to search newline.
 * Returns NSNotFound if no newline characer is found.
 **/
- (NSUInteger)prevNewLine:(NSUInteger)index;

/**
 * Returns position of the head of line of the current line specified by index.
 * Head of line is one of them which is found first when searching backwords from "index".
 *    - Character just after newline
 *    - Character at the head of document
 * If the size of document is 0 it does not have any head of line.
 * Blankline does NOT have headOfLine. So EOF is NEVER head of line.
 * Searching starts from position "index". So the "index" could be a head of line and may be returned.
 **/
- (NSUInteger)headOfLine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the first non-whitespace character past the head of line of the
 * current line specified by index.
 * If there is no head of line it returns NSNotFound
 **/
- (NSUInteger)headOfLineWithoutSpaces:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the first non-blank character at the line specified by index
 * If its blank line it retuns position of newline character
 * If its a line with only white spaces it returns end of line.
 * This NEVER returns NSNotFound.
 * Note that this is differnet from headOfLineWithoutSpaces
 **/
- (NSUInteger)firstNonBlankInALine:(NSUInteger)index; // Never returns NSNotFound

/**
 * Returns position of the tail of current line. 
 * Tail of line is one of followings
 *    - Newline character at the end of a line.
 *    - EOF of the last line of the document.
 * Blankline also has tail of line.
 **/
- (NSUInteger)tailOfLine:(NSUInteger)index; // Never returns NSNotFound

/**
 * Returns position of the end of line when the cursor is at "index"
 * End of line is one of following which is found first when searching forwords from "index".
 *    - Character just before newline if its not newlin
 *    - Character just before EOF if its not newline 
 * Blankline does not have end of line.
 * Searching starts from position "index". So the "index" could be an end of line.
 **/
- (NSUInteger)endOfLine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of eof
 **/
- (NSUInteger)endOfFile;

/**
 * Returns column number of the position "index"
 * Column number starts from 0
 **/
- (NSUInteger)columnNumber:(NSUInteger)index;

/**
 * Returns position at line number "num" and column number "column"
 * If the "column" exceeds the end of line it returns position of  the end of line.
 * Line number starts from 1.
 **/
- (NSUInteger)positionAtLineNumber:(NSUInteger)num column:(NSUInteger)column;

// Clamps range to end of line
- (void)clampRangeToEndOfLine:(NSRange*)range;

// Clamps range to buffer
- (void)clampRangeToBuffer:(NSRange*)range;

// Selection
- (void)moveCursorWithBoundsCheck:(NSUInteger)to;
- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to;
- (NSUInteger)lineNumber:(NSUInteger)index;
- (NSUInteger)numberOfLines;
- (NSRange)getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)selectOperationTargetFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
 
// Motions
- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info;
- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;

// Scrolls
- (NSUInteger)pageForward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)pageBackward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)halfPageForward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)halfPageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)scrollToCursor;
    
// Case changes. These functions are all range checked.
- (void)toggleCaseForRange:(NSRange)range;
- (void)uppercaseRange:(NSRange)range;
- (void)lowercaseRange:(NSRange)range;

@end

