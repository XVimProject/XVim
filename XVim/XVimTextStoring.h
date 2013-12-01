//
//  XVimTextStoring.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import <Foundation/Foundation.h>

@class XVimBuffer;

/** @brief Protocol that can be implemented by your NSTextStorage.
 *
 * Implementing it will likely boost XVimBuffer performance significantly
 * All selectors are optional, and serve as the direct backend for
 * XVimBuffer selectors of the same name without the xvim_ prefix.
 *
 */
@protocol XVimTextStoring

@optional

#pragma mark *** Content & Lines access ***

@property (nonatomic, readonly) NSString  *xvim_string;

@property (nonatomic, readonly) NSUInteger xvim_numberOfLines;

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
- (NSRange)xvim_indexRangeForLineNumber:(NSUInteger)num newLineLength:(NSUInteger *)newLineLength;

/** @brief returns the index range for the given line range
 *
 * @param[in]  range  the line range.
 *
 * @returns
 *   the range of indexes forming the line, including trailing newLine characters
 *   Never returns NSNotFound
 */
- (NSRange)xvim_indexRangeForLines:(NSRange)range;

/** @brief get the line number of a given index.
 *
 * @returns
 *    the line number of specified index.
 *    This never returns NSNotFound.
 */
- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)index;

#pragma mark *** Indent ***

@property (nonatomic, readonly) NSUInteger xvim_tabWidth;

@property (nonatomic, readonly) NSUInteger xvim_indentWidth;

- (void)xvim_indentCharacterRange:(NSRange)range buffer:(XVimBuffer *)buffer;

@end
