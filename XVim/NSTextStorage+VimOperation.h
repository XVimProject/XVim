//
//  NSTextStorage+VimOperation.h
//  XVim
//
//  Created by Suzuki Shuichiro on 7/30/13.
//
//


#import "XVimMotion.h"
#import "XVimDefs.h"
#import <Cocoa/Cocoa.h>

typedef enum {
    XVimSortOptionReversed              = 1,
    XVimSortOptionRemoveDuplicateLines  = 1 << 1,
    XVimSortOptionNumericSort           = 1 << 2,
    XVimSortOptionIgnoreCase            = 1 << 3
} XVimSortOptions;

/**
 VimOperation category on NSTextStorage
 Adds Vim-like functionality to NSTextStorage.
 **/

#pragma mark Macros
#ifdef DEBUG
// The methods here often take index as current interest position and index can be at EOF
// The following macros asserts the range of index.
// WITH_EOF permits the index at EOF position.
// WITHOUT_EOF doesn't permit the index at EOF position.
#define ASSERT_VALID_RANGE_WITH_EOF(x) NSAssert( x <= [[self string] length] || [[self string] length] == 0, @"index can not exceed the length of string.   TextLength:%lu   SpecifiedIndex:%lu", [[self string] length], x)
#define ASSERT_VALID_RANGE_WITHOUT_EOF(x) NSAssert( x < [[self string] length] || [[self string] length] == 0, @"index can not exceed the length of string - 1 TextLength:%lu   SpecifiedIndex:%lu", [[self string] length], x)

// Some methods assume that "index" is at valid cursor position in Normal mode.
// See isValidCursorPosition's description the condition of the valid cursor position.
#define ASSERT_VALID_CURSOR_POS(x) NSAssert( [self isValidCursorPosition:x], @"index can not be invalid cursor position" )
#else
#define ASSERT_VALID_RANGE_WITH_EOF(x)
#define ASSERT_VALID_RANGE_WITHOUT_EOF(x)
#define ASSERT_VALID_CURSOR_POS(x)
#endif

#define charat(x) [[self string] characterAtIndex:(x)]


#pragma mark Term Definitions
/**
 * Note that the terms here are not the same definition as Cocoa or Xcode classes uses.
 *
 * "Character"
 * Character is a one unichar value. (any value including tabs,spaces)
 *
 * "EOF"
 * EOF is the position at the end of document(text).
 * If we have NSTextView with string "abc" the EOF is just AFTER the 'c'.
 * The index of EOF is 3 in this case ( index is 0 based ).
 * What we have to think about is a cursor can be on the EOF(when the previous letter is newline) but characterAtIndex: with index of EOF cause an exception.
 * We have to be careful about it when calculate and find the position of some motions.
 *
 * "Newline"
 * Newline is defined as "unichar determined by isNewline function". Usually "\n" or "\r".
 *
 * "Line"
 * Line is a sequence of characters terminated by newline or EOF. "Line" includes the last newline character.
 *
 * "Blankline"
 * Blankline is a line which has only newline or EOF. In other words, it is newline character or EOF after newline character.
 *
 * "Last of Line(LOL)"
 * Last of line is the last character of a line EXCLUDING newline character.
 * This means that blankline does NOT have an Last of line.
 *
 * "First of Line(FOL)"
 * First of line is the first character of a line excluding newline character.
 * This means that blankline does NOT have a First of line.
 *
 * "First Nonblank of Line"
 * First Nonblank of Line is the first printable character in a line.
 *
 * "End of Line(EOL)"
 * End of Line is newline or EOF character at the end of a line.
 * A line always has an EOL.
 *
 * "Beginning of Line (BOL)"
 * First character of a line including newline and EOF
 *
 **/

/**
 * Line number starts from 1.
 * Column number starts from 0.
 **/

@interface NSTextStorage (VimOperation)

- (NSString*)xvim_string;

#pragma mark Properties
// Returns position of eof
- (NSUInteger)endOfFile;

// Returns number of lines in the text
- (NSUInteger)numberOfLines;


#pragma mark Definitions

// Determine if the position specified with "index" is EOF.
- (BOOL) isEOF:(NSUInteger)index;

//Determine if the text is empty.
- (BOOL) isEmpty;

// Determine if the posiion is last character of the text
- (BOOL) isLastCharacter:(NSUInteger)index;
    
// Determine if the position specified with "index" is LOL.
- (BOOL) isLOL:(NSUInteger)index;

// Determine if the position specified with "index" is FOL.
//- (BOOL) isFOL:(NSUInteger)index;  // Not implemented

// Determine if the position specified with "index" is EOL.
- (BOOL) isEOL:(NSUInteger)index;

// Determine if the position is a beginning of line
- (BOOL) isBOL:(NSUInteger)index;

// Determine if the position specified with "index" is newline.
- (BOOL) isNewline:(NSUInteger)index;

// Determine if the position specified with "index" is white space.
- (BOOL) isWhitespace:(NSUInteger)index;

// Determine if the position is on the last line in the document
- (BOOL) isLastLine:(NSUInteger)index;

// Determine if the position is on the first line in the document
- (BOOL) isFirstLine:(NSUInteger)index; // Not implemented

// Determine if the position is non blank character
// EOF is a blank character
- (BOOL) isNonblank:(NSUInteger)index;

/**
 * Determine if the position specified with "index" is blankline.
 * Blankline is one of followings
 *   - Newline after Newline. Ex. The second '\n' in "abc\n\nabc" is a blankline. First one is not.
 *   - Newline at begining of the document.
 *   - EOF after Newline. Ex. The index 4 of "abc\n" is blankline. Note that index 4 is exceed the string length. But the cursor can be there.
 *   - EOF of 0 sized document.
 **/
- (BOOL) isBlankline:(NSUInteger)index;

/**
 * Determine if the position specified with "index" is an empty line.
 * Empty line is one of following
 *   - Blankline
 *   - Only whitespace followed by Newline or EOF.
 **/
- (BOOL) isEmptyline:(NSUInteger)index;

/**
 * Determine if the position specified with "index" is valid cursor position in normal mode.
 * Valid position is followings
 *   - Non newline characters.
 *   - Blankline( including EOF after newline )
 **/
- (BOOL) isValidCursorPosition:(NSUInteger)index;


#pragma mark Searching Positions
/**
 * Returns next non-blank character position after the position "index" in a current line.
 * If no non-blank character is found or the line is a blank line this returns NSNotFound.
 * NOTE: This searches non blank characters from "index" and NOT "index+1"
 *       If the character at "index" is non blank this returns "index" itself
 **/ 
- (NSUInteger)nextNonblankInLine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the first newline character when searching forwards from "index+1"
 * Searching starts from position "index"+1. The position index is not included to search newline.
 * Returns NSNotFound if no newline character is found.
 **/
- (NSUInteger)nextNewline:(NSUInteger)index;

/**
 * Returns position of the first newline character when searching backwards from "index-1"
 * Searching starts from position "index"-1. The position index is not included to search newline.
 * Returns NSNotFound if no newline characer is found.
 **/
- (NSUInteger)prevNewline:(NSUInteger)index;

/**
 * Returns position of the first of line of the current line specified by index.
 * first of line is one of following which is found first when searching backwords from "index".
 *    - Character just after newline
 *    - Character at the head of document
 * If the size of document is 0 it does not have any first of line.
 * Blankline does NOT have first of line. So EOF is NEVER head of line.
 * Searching starts from position "index". So the "index" could be a first of line and may be returned.
 **/
- (NSUInteger)firstOfLine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the last character of line when the cursor is at "index"
 * End of line is one of following which is found first when searching forwords from "index".
 *    - Character just before newline if its not newlin
 *    - Character just before EOF if its not newline 
 * Blankline does not have last of line.
 * Searching starts from position "index". So the "index" could be an end of line.
 **/
- (NSUInteger)lastOfLine:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of first character of the line specified by index.
 * Note that first character in the line is different from first of line.
 * First character may be newline when its blankline.
 * First character may be EOF if the EOF is blankline
 * In short words, its just after a newline or begining of document.
 * Search starts from "index" and this may return index itself.
 * This never returns NSNotFound
 **/
- (NSUInteger)beginningOfLine:(NSUInteger)index;

/**
 * Returns position of the end of current line. 
 * end of line is one of followings
 *    - Newline character at the end of a line.
 *    - EOF of the last line of the document.
 * Blankline also has tail of line.
 **/
- (NSUInteger)endOfLine:(NSUInteger)index; // Never returns NSNotFound

/**
 * Returns position of the first non-whitespace character in the line specified by index.
 * If there is no first of line it returns NSNotFound
 **/
- (NSUInteger)firstOfLineWithoutSpaces:(NSUInteger)index; // May return NSNotFound

/**
 * Returns position of the first non-blank character at the line specified by index
 * If its blank line it retuns position of newline character
 * If its a line with only white spaces it returns end of line.
 * This NEVER returns NSNotFound.
 * Note that this is differnet from firstOfLineWithoutSpaces
 **/
- (NSUInteger)firstNonblankInLine:(NSUInteger)index; // Never returns NSNotFound

 /**
 * Returns position at line number "num" and column number 0
 * Line number starts from 1.
 * NSNotFound is retured if the specifiled line number exceeds the maxmam line number in the document.
 **/
- (NSUInteger)positionAtLineNumber:(NSUInteger)num;

/**
 * Returns position at line number "num" and column number "column"
 * Line number starts from 1.
 * If the line number specified exceeds the maximum lines in the document it returns NSNotFound.
 * If the specified column exeeds the column number in the line it returns position of tail of the line(newline or eof)
 **/
- (NSUInteger)positionAtLineNumber:(NSUInteger)num column:(NSUInteger)column;

/**
 * Returns maximum column number at the line
 * Column number starts from 0.
 * If the specified line does not exist in the current document it returns NSNotFound
 **/
- (NSUInteger)maxColumnAtLineNumber:(NSUInteger)num;

/**
 * Returns index of the position where the specified column is matched when searching from "pos" in the line.
 * If the specified column is not found ( which means it finds end of line before finding matching column) 
 * it returns NSNotFound if "notfound" is YES  or  it returns the position of the end of line if "notfound" is NO.
 **/
- (NSUInteger)nextPositionFrom:(NSUInteger)pos matchingColumn:(NSUInteger)column returnNotFound:(BOOL)notfound;

/**
 * Returns line number of specified index.
 * Line number starts from 1
 * This never returns NSNotFound.
 **/
- (NSUInteger)lineNumber:(NSUInteger)index;

/**
 * Returns column number.
 * Column number starts from 0.
 * This never returns NSNotFound.
 **/
- (NSUInteger)columnNumber:(NSUInteger)index;

/**
 * Return characgter range for line range.
 * NOTE: Linenumber starts from 0 not 1 for this method.
 * TODO: Xcode uses linenuber starts from 0 and XVim uses 1
 *       We should adapt Xcode's way.
 **/
- (NSRange)characterRangeForLineRange:(NSRange)arg1;


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
- (NSUInteger)paragraphsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)paragraphsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
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
// Return the location of the start of indentation on current line. '^'
NSInteger xv_caret(NSString *string, NSInteger index);
// Return the beginning of line location. '0'
NSInteger xv_0(NSString *string, NSInteger index);

// Unlike vim, this function won't ignore indent before the current character
// even if what is '{'
NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what, char other);
NSRange xv_current_quote(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what);

// Find char in current line.
// Return the current index if nothing found.
// If inclusive is YES :
//   'fx' returns the index after 'x'
//   'Fx' returns the index before 'x'
NSInteger xv_findChar(NSString *string, NSInteger index, int repeatCount, char command, unichar what, BOOL inclusive);



#pragma mark Conversions
/**
 * Convert index to XVimPosition.
 * "index" can be 0 to EOF.
 * Otherwise it returns XVimPosition with {NSNotFound, NSNotFound}
 **/
- (XVimPosition)XVimPositionFromIndex:(NSUInteger)index;

/**
 * Convert XVimPosition to index.
 * If line or column specified by "pos" does not exist
 * it returns NSNotFound.
 **/
- (NSUInteger)IndexFromXVimPosition:(XVimPosition)pos;

/**
 * Returns nearest valid cursor position for normal mode.
 * This is usually convert cursor position on newline to previous character since
 * a cursor can not be on a newline charaster if its not blankline
 **/
- (NSUInteger)convertToValidCursorPositionForNormalMode:(NSUInteger)index;

@end
