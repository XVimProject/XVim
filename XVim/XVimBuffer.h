//
//  XVimBuffer.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import <Foundation/Foundation.h>
#import "XVimDefs.h"

#pragma mark Macros

#ifdef DEBUG
// The methods here often take index as current interest position and index can be at EOF
// The following macros asserts the range of index.
// WITH_EOF permits the index at EOF position.
// WITHOUT_EOF doesn't permit the index at EOF position.
#define ASSERT_VALID_RANGE_WITH_EOF(x) NSAssert( x <= [self length], \
    @"index can not exceed the length of string.   TextLength:%lu   SpecifiedIndex:%lu", (long)[self length], x)
#else
#define ASSERT_VALID_RANGE_WITH_EOF(x)
#define ASSERT_VALID_CURSOR_POS(x)
#endif

@class XVimUndoOperation, XVimBuffer;

@interface NSTextStorage (XVimBuffer)
@property (nonatomic, readonly) XVimBuffer *xvim_buffer;
@end

@interface NSDocument (XVimBuffer)
@property (nonatomic, readonly) XVimBuffer *xvim_buffer;
@end

/** @brief class to represent an XVim Buffer
 *
 * If we were writing a vi clone, this would be the object owning the document
 * and the text storage. But since XVim is meant to be a plugin to add vim
 * bindings to existing apps like XCode, this is done in the reverse way.
 *
 * The XVimBuffer is an associated object of the NSDocument and NSTextStorage
 * that the App we're hooking into is supposed to use.
 *
 * XVimBuffer supposes that there's a 1:1 mapping between the document
 * and the storage and owns no reference to either of those.
 *
 * This means that when the document and textstorage get deallocated,
 * either one may be stale, and make the app crash if we try to use them.
 *
 * FIXME: hook into NSDocument/NSTextStorage to invalidate
 *        the XVimBuffer in the rigth places.
 *        This isn't urgent though because IDE uses an NSDocument subclass
 *        that owns its textStorage, hence their lifetime is tied.
 *
 ******************************************************************************
 *
 * Note that the terms here do not have the usual Cocoah meaning
 *
 * "Character"
 *   Character is a one unichar value. (any value including tabs,spaces)
 *
 * "index"
 *   This is the 0-based location of a given character within -xvim_string.
 *
 * "Position"
 *   This is an XVimPosition (line + column)
 *
 * "EOF"
 *   EOF is the position of the end of the document (-length),
 *   so for a text of "abc", EOF is just after the 'c', at position 3.
 *
 *   What we have to think about is that a cursor can be at EOF,
 *   but -[xvim_string characterAtIndex:] at this position raises.
 *
 *   We have to be careful about it when computing motions effects.
 *
 * "Newline"
 *   Newline is defined as "unichar determined by isNewline function".
 *   Usually "\n" or "\r".
 *
 * "Line"
 *   Line is a sequence of characters terminated by newline or EOF.
 *   "Line" includes the last newline character.
 *   Line numbers start at 1
 *
 * "Blankline"
 *   Blankline is a line which has only newline or EOF.
 *   In other words, it is newline character or EOF after newline character.
 *
 * "Last of Line(LOL)"
 *   Last of line is the last character of a line EXCLUDING newline character.
 *   This means that blankline does NOT have an Last of line.
 *
 * "First of Line(FOL)"
 *   First of line is the first character of a line excluding newline character.
 *   This means that blankline does NOT have a First of line.
 *
 * "First Nonblank of Line"
 *   First Nonblank of Line is the first printable character in a line.
 *
 * "End of Line(EOL)"
 *   End of Line is newline or EOF character at the end of a line.
 *   A line always has an EOL.
 *
 * "Beginning of Line (BOL)"
 *   First character of a line including newline and EOF
 *
 */

@interface XVimBuffer : NSObject {
@public
    XVimVisualInfo visualInfo;
}

@property (nonatomic, readonly) NSDocument    *document;
@property (nonatomic, readonly) NSTextStorage *textStorage;
@property (nonatomic, readonly) NSUndoManager *undoManager;

+ (XVimBuffer *)makeBufferForDocument:(NSDocument *)document
                          textStorage:(NSTextStorage *)textStorage;

#pragma mark Properties

@property (nonatomic, readonly) NSString  *string;
@property (nonatomic, readonly) NSString  *lineEnding;
@property (nonatomic, readonly) NSUInteger numberOfLines;
@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly) NSUInteger tabWidth;
@property (nonatomic, readonly) NSUInteger indentWidth;

#pragma mark Specific positions of the index within the line

/** @brief returns YES when \a index is on the last line
 */
- (BOOL)isIndexOnLastLine:(NSUInteger)index;

/** @brief returns YES when \a index is at the beginning of its line
 * It returns NO if \a index points to the \n of a \r\n
 */
- (BOOL)isIndexAtStartOfLine:(NSUInteger)index;

/** @brief returns YES when \a index is at the end of its line
 * It also returns YES if \a index points to the \n in a \r\n.
 */
- (BOOL)isIndexAtEndOfLine:(NSUInteger)index;

/** @brief returns YES when \a index is a valid cursor position for normal mode
 */
- (BOOL)isNormalCursorPositionValidAtIndex:(NSUInteger)index;

#pragma mark Converting between Indexes and Line Numbers

/** @brief returns the index range for the given line number
 *
 * @param[in]  num
 *   The line number
 * @param[out] newLineLength
 *   The number of characters after the returned range forming the end of line
 * @returns
 *   - {NSNotFound, 0} if the index is beyond the end of the document.
 *   - the range of indexes forming the line, excluding trailing newLine characters
 */
- (NSRange)indexRangeForLineNumber:(NSUInteger)num newLineLength:(NSUInteger *)newLineLength;

/** @brief returns the index range for the given line range
 *
 * @param[in]  range  the line range.
 *
 * @returns
 *   the range of indexes forming the line, including trailing newLine characters
 *   Never returns NSNotFound
 */
- (NSRange)indexRangeForLines:(NSRange)range;

/** @brief returns the line range around the given index
 *
 * @param[in]  index
 *   The index within -xvim_string
 * @param[out] newLineLength
 *   The number of characters after the returned range forming the end of line
 * @returns
 *   the range of indexes forming the line, exclugint trailing newLine characters
 *   Note that if the index is within a CRLF for example, the range may end before index
 */
- (NSRange)indexRangeForLineAtIndex:(NSUInteger)index newLineLength:(NSUInteger *)newLineLength;

/** @brief starting position of line @a num within -xvim_string.
 * @returns the starting index for that line number or NSNotFound.
 * @see -xvim_indexRangeForLineNumber:newLineLength:
 */
- (NSUInteger)indexOfLineNumber:(NSUInteger)num;

/** @brief get the line number of a given position.
 *
 * @returns
 *    the line number of specified index.
 *    This never returns NSNotFound.
 */
- (NSUInteger)lineNumberAtIndex:(NSUInteger)index;

#pragma mark Converting between Indexes and Line Numbers + Columns

/** @brief returns the column number of \a index within the line.
 *
 * Column numbers starts at 0.
 *
 * This never returns NSNotFound.
 */
- (NSUInteger)columnOfIndex:(NSUInteger)index;

/** @brief returns the XVim Posiion of \a index
 *
 * Column numbers starts at 0.
 *
 * This never returns NSNotFound.
 */
- (XVimPosition)positionOfIndex:(NSUInteger)index;

/** @brief returns number of columns for the line containing \a index.
 *
 * If the specified line does not exist in the current document it returns NSNotFound
 */
- (NSUInteger)numberOfColumnsInLineAtIndex:(NSUInteger)index;

/** @brief returns the index for the given line number and column.
 *
 * @returns
 *   NSNotFound if \a num exceeds the number of lines in the document
 *   If \a column is larger than the number of columns in that line,
 *   it returns the index of the endOfLine for that line
 */
- (NSUInteger)indexOfLineNumber:(NSUInteger)num column:(NSUInteger)column;

/** @brief returns the index for the given line containing \a index and column.
 *
 * @returns
 *   Never returns NSNotfound
 *   If \a column is larger than the number of columns in that line,
 *   it returns the index of the endOfLine for that line
 */
- (NSUInteger)indexOfLineAtIndex:(NSUInteger)index column:(NSUInteger)column;

#pragma mark Motion support functions

/** @brief returns the index for a 'h/l' movement
 *
 * @param scount    the motion count (negative means backwards)
 * @param index     the start index
 * @param wrap      wether the movement blocks at line start/end or wraps
 * @returns
 *   This never returns NSNotFound, but it can return the end of line,
 *   and it's up to the caller to detect that if it's a problem.
 */
- (NSUInteger)indexOfCharMotion:(NSInteger)scount index:(NSUInteger)index options:(XVimMotionOptions)options;

/** @brief returns the index for a 'j/k' movement
 *
 * @param scount  the number of lines to go forward (negative means backward).
 * @param index   the line number containing that index is the starting line for that movement
 * @param column  the column to try to reach
 * @returns
 *   this never returns NSNotFound, if the movement reaches the start
 *   or end of the file, the resulting line number is clamped.
 */
- (NSUInteger)indexOfLineMotion:(NSInteger)scount index:(NSUInteger)index column:(NSUInteger)column;

#pragma mark Searching particular positions on the current line

/** @brief position of the first character of the line containing \a index.
 *
 * @param index  the index to search backwards from
 */
- (NSUInteger)startOfLine:(NSUInteger)index; // never returns NSNotFound

/** @brief returns the firstOfLine for the line containing \a index.
 *
 * If the line is blank, this returns NSNotFound
 * else this is the same as -beginningOfLine:
 */
- (NSUInteger)firstOfLine:(NSUInteger)index; // May return NSNotFound

/** @brief position of the end of the line containing \a index.
 *
 * @param index  the index to search from
 *
 * @returns
 *    the position of the end of the line.
 *    end of the line is either:
 *    - a newline character at the end of the line
 *    - end of the document
 *
 *    Note that for files with \r\n if index points to \n
 *    this returns a position before index.
 */
- (NSUInteger)endOfLine:(NSUInteger)index; // never returns NSNotFound

/** @brief returns the lastOfLine for the line containing \a index.
 *
 * If the line is blank, this returns NSNotFound
 * else this is the same as -endOfLine:index - 1
 */
- (NSUInteger)lastOfLine:(NSUInteger)index; // May return NSNotFound

/** @brief returns the next non blank position on the same line.
 *
 * @param index     the index to search from
 * @param allowEOL  whether reaching EOL is allowed or not
 *
 * @returns
 *   the position of the first non blank character, starting at index.
 *
 *   if \a allowEOL is NO and that no non blank character is found,
 *   this returns NSNotFound.
 */
- (NSUInteger)nextNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL;

/** @brief returns the first non blank character on the line, possibly EOL.
 *
 * @param index   searches on the line containing that index.
 *
 * @returns
 *   the position of the first non blank character
 *   on the line containing \a index.
 *
 *   if \a allowEOL is NO and that no non blank character is found,
 *   this returns NSNotFound.
 */
- (NSUInteger)firstNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL;

/** @brief returns the next digit position on the same line.
 *
 * @param index     the index to search from
 *
 * @returns
 *   the position of the first decimal digit character starting at \a index
 *
 *   this returns NSNotFound if none is found.
 */
- (NSUInteger)nextDigitInLine:(NSUInteger)index;

#pragma mark Support for modifications

@property (nonatomic, readonly) BOOL isEditing;

- (void)undoRedo:(XVimUndoOperation *)op;

- (void)beginEditingAtIndex:(NSUInteger)index;
- (void)endEditingAtIndex:(NSUInteger)index;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)replaceCharactersInRange:(NSRange)range withSpaces:(NSUInteger)count;

#define XVIM_BUFFER_SWAP_UPPER  0
#define XVIM_BUFFER_SWAP_LOWER  1
#define XVIM_BUFFER_SWAP_CASE   2
#define XVIM_BUFFER_SWAP_ROT13  3
- (void)swapCharactersInRange:(NSRange)range mode:(int)mode;

// Never fails
- (NSUInteger)shiftLines:(XVimRange)lines column:(NSUInteger)column
                   count:(NSUInteger)count right:(BOOL)right block:(BOOL)block;

// May return NSNotFound
- (NSUInteger)incrementNumberAtIndex:(NSUInteger)index by:(int64_t)offset;

- (void)indentCharacterRange:(NSRange)range;

@end
