//
//  NSTextStorage+VimOperation.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/30/13.
//
//

#import "XVimStringBuffer.h"
#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "Logger.h"
#import "NSTextView+VimOperation.h"

@implementation NSTextStorage (VimOperation)

#pragma mark XVimTextStoring Properties

- (NSString *)xvim_string
{
    return self.string;
}

- (NSUInteger)xvim_numberOfLines
{
    return [self xvim_lineNumberAtIndex:self.length];
}

#pragma mark Settings

// TODO: These values should be taken from IDEFileTextSetting.
- (NSUInteger)xvim_indentWidth
{
    return 4;
}

- (NSUInteger)xvim_tabWidth
{
    return 4;
}

#pragma mark Converting between Indexes and Line Numbers

// TODO: we may need to keep track line number and position by hooking insertText: method.
// FIXME: this code is actually never called in XVim for XCode, it probably has bugs, it's not tested
- (NSRange)xvim_indexRangeForLineNumber:(NSUInteger)num newLineLength:(NSUInteger *)newLineLength
{
    NSAssert(num > 0, @"line number starts at 1");

    NSString  *string = self.xvim_string;
    NSUInteger length = self.length;
    NSUInteger lineNum = 0, end = 0, contentsEnd;

    do {
        [string getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(end, 0)];
        lineNum++;
        if (lineNum == num) {
            if (newLineLength) *newLineLength = end - contentsEnd;
            return NSMakeRange(end, contentsEnd - end);
        }
    } while (end < length);

    if (newLineLength) *newLineLength = 0;

    // we have a last empty line after \n
    if (contentsEnd < end) {
        lineNum++;
        if (lineNum == num) {
            return NSMakeRange(end, 0);
        }
    }

    return NSMakeRange(NSNotFound, 0);
}

// TODO: we may need to keep track line number and position by hooking insertText: method.
// FIXME: this code is actually never called in XVim for XCode, it probably has bugs, it's not tested
- (NSRange)xvim_indexRangeForLines:(NSRange)range
{
    NSString  *string = self.xvim_string;
    NSUInteger length = self.length, start = 0;
    NSUInteger lineNum = 0, end = 0, contentsEnd = 0;

    NSAssert(range.location > 0, @"line number starts at 1");

    do {
        [string getLineStart:NULL end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(end, 0)];
        lineNum++;
        if (lineNum == range.location) {
            start = end;
        }
        if (lineNum == NSMaxRange(range)) {
            return NSMakeRange(start, end - start);
        }
    } while (end < length);

    // we have a last empty line after \n
    if (contentsEnd < end) {
        lineNum++;
        if (lineNum == range.location) {
            start = end;
        }
        if (lineNum == NSMaxRange(range)) {
            return NSMakeRange(start, end - start);
        }
    }

    return NSMakeRange(0, length);
}

- (NSRange)xvim_indexRangeForLineAtIndex:(NSUInteger)index newLineLength:(NSUInteger *)newLineLength
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.xvim_string;
    NSUInteger len = self.length;
    NSUInteger end, contentEnd;

    if (index > len) {
        index = len;
    }

    [string getLineStart:&index end:&end contentsEnd:&contentEnd forRange:NSMakeRange(index, 0)];
    if (newLineLength) *newLineLength = contentEnd - end;
    return NSMakeRange(index, contentEnd - index);
}

- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)num
{
    if (num == 1) {
        return 0;
    }
    return [self xvim_indexRangeForLineNumber:num newLineLength:NULL].location;
}

- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);

    NSString *string = self.xvim_string;
    NSUInteger len = self.length;
    NSUInteger num = 1, pos = 0;

    if (index > len) {
        index = len;
    }

    do {
        num++;
        if (index == pos) {
            return num;
        }
        [string getLineStart:NULL end:&pos contentsEnd:NULL forRange:NSMakeRange(pos, 0)];
    } while (pos < index);

    return num;
}

#pragma mark Converting between Indexes and Line Numbers + Columns

static NSUInteger xvim_sb_count_columns(xvim_string_buffer_t *sb, NSUInteger tabWidth)
{
    NSUInteger col = 0;

    if (!xvim_sb_at_end(sb)) {
        do {
            if (xvim_sb_peek(sb) == '\t') {
                col += tabWidth;
                if (tabWidth) col -= col % tabWidth;
            } else {
                col++;
            }
        } while (xvim_sb_next(sb));
    }

    return col;
}

- (NSUInteger)xvim_columnOfIndex:(NSUInteger)index
{
    NSRange range = [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_string_buffer_t sb;

    if (index < NSMaxRange(range)) {
        range.length = index - range.location;
    }
    if (range.length == 0) {
        return 0;
    }

    xvim_sb_init(&sb, self.xvim_string, range.location, range);
    return xvim_sb_count_columns(&sb, self.xvim_tabWidth);
}

- (NSUInteger)xvim_numberOfColumnsInLineAtIndex:(NSUInteger)index
{
    NSRange range = [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_string_buffer_t sb;

    xvim_sb_init(&sb, self.xvim_string, range.location, range);
    return xvim_sb_count_columns(&sb, self.xvim_tabWidth);
}

- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)num column:(NSUInteger)column
{
	NSUInteger index = [self xvim_indexOfLineNumber:num];

    if (column == 0 || index == NSNotFound) {
        return index;
    }

    NSRange    range = [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL];
    NSUInteger tabWidth = self.xvim_tabWidth;
    NSUInteger col = 0;
    xvim_string_buffer_t sb;

    xvim_sb_init(&sb, self.xvim_string, range.location, range);
    do {
        if (xvim_sb_peek(&sb) == '\t') {
            col += tabWidth;
            if (tabWidth) col -= col % tabWidth;
        } else {
            col++;
        }
        if (col > column) {
            return xvim_sb_index(&sb);
        }
    } while (xvim_sb_next(&sb) && col < column);

    return xvim_sb_index(&sb);
}


#pragma mark Searching particular positions on the current line

- (NSUInteger)xvim_startOfLine:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.xvim_string;
    NSUInteger len = self.length;

    if (index > len) {
        index = len;
    }
    [string getLineStart:&index end:NULL contentsEnd:NULL forRange:NSMakeRange(index, 0)];
    return index;
}

- (NSUInteger)xvim_firstOfLine:(NSUInteger)index
{
    NSUInteger pos = [self xvim_startOfLine:index];
    NSUInteger len = self.length;
    if( len == 0 ){
        return NSNotFound;
    }

    if (pos == index && isNewline([self.xvim_string characterAtIndex:(pos - 1)])) {
        return NSNotFound;
    }
    return pos;
}

- (NSUInteger)xvim_endOfLine:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSString *string = self.xvim_string;
    NSUInteger len = self.length;

    if (index > len) {
        index = len;
    }
    [string getLineStart:NULL end:NULL contentsEnd:&index forRange:NSMakeRange(index, 0)];
    return index;
}

- (NSUInteger)xvim_lastOfLine:(NSUInteger)index
{
    NSUInteger pos = [self xvim_endOfLine:index];

    if (pos <= index && (pos == 0 || isNewline([self.xvim_string characterAtIndex:pos - 1]))) {
        return NSNotFound;
    }
    return pos - 1;
}

- (NSUInteger)xvim_nextNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL
{
    NSString *s = self.xvim_string;
    NSUInteger length = s.length;
    xvim_string_buffer_t sb;
    unichar c;

    ASSERT_VALID_RANGE_WITH_EOF(index);

    xvim_sb_init(&sb, s, index, NSMakeRange(index, length - index));
    xvim_sb_skip_forward(&sb, [NSCharacterSet whitespaceCharacterSet]);
    c = xvim_sb_peek(&sb);

    if (c == XVimInvalidChar || isNewline(c)) {
        return allowEOL ? xvim_sb_index(&sb) : NSNotFound;
    }
    return xvim_sb_index(&sb);
}

- (NSUInteger)xvim_firstNonblankInLineAtIndex:(NSUInteger)index allowEOL:(BOOL)allowEOL
{
    index = [self xvim_startOfLine:index];
    return [self xvim_nextNonblankInLineAtIndex:index allowEOL:allowEOL];
}

- (NSUInteger)xvim_nextDigitInLine:(NSUInteger)index
{
    xvim_string_buffer_t sb;
    NSRange range;

    range = [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL];
    xvim_sb_init(&sb, self.xvim_string, index, range);
    if (xvim_sb_find_forward(&sb, [NSCharacterSet decimalDigitCharacterSet])) {
        return xvim_sb_index(&sb);
    }

    return NSNotFound;
}

#pragma mark Definitions

- (BOOL) isEOF:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [[self xvim_string] length] == index;
}

- (BOOL) isLOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isEOF:index] == NO && [self isNewline:index] == NO && [self isNewline:index+1];
}

- (BOOL) isEOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isNewline:index] || [self isEOF:index];
}

- (BOOL) isBOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 0 == index ){
        return YES;
    }
    
    if( [self isNewline:index-1] ){
        return YES;
    }
    
    return NO;
}

- (BOOL) isLastCharacter:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [[self xvim_string] length] == 0 ){
        return NO;
    }
    return [[self xvim_string] length]-1 == index;
}

- (BOOL) isNewline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self xvim_string] length] ){
        return NO; // EOF is not a newline
    }
    return isNewline([[self xvim_string] characterAtIndex:index]);
}

- (BOOL) isWhitespace:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self xvim_string] length] ){
        return NO; // EOF is not whitespace
    }
    return isWhitespace([[self xvim_string] characterAtIndex:index]);
}

- (BOOL) isWhitespaceOrNewline:(NSUInteger)index{
    return isWhiteSpaceOrNewline([[self xvim_string] characterAtIndex:index]);
}

- (BOOL) isKeyword:(NSUInteger)index{
    return isKeyword([[self xvim_string] characterAtIndex:index]);
}

- (BOOL) isLastLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self xvim_lineNumberAtIndex:index] == [self xvim_numberOfLines];
}

- (BOOL) isNonblank:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEOF:index]){
        return YES;
    }
    return isNonblank([[self xvim_string] characterAtIndex:index]);
}

- (BOOL)isBlankline:(NSUInteger)index
{
    return [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL].length == 0;
}

- (BOOL) isValidCursorPosition:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isBlankline:index] ){
        return YES;
    }
    // "index" in not a blankline.
    // Then the EOF is not a valid cursor position.
    if( [self isEOF:index] ){
        return NO;
    }
    
    // index is never the position of EOF. We can call isNewline with index.
    if( ![self isNewline:index]){
        return YES;
    }
    
    return NO;
}


#pragma mark Searching Positions

/**
 * This does all the work need to do with vim '%' motion.
 * Find match pair character in the line and find the corresponding pair.
 * Returns NSNotFound if not found.
 **/
- (NSUInteger)positionOfMatchedPair:(NSUInteger)pos
{
    NSString *s = self.xvim_string;

    // find matching bracketing character and go to it
    // as long as the nesting level matches up

    xvim_string_buffer_t sb;
    xvim_sb_init(&sb, s, pos, NSMakeRange(pos, [self xvim_endOfLine:pos] - pos));

#define pairs "{}[]()"
    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@pairs];

    unichar start_with_c, look_for_c;
    BOOL search_forward;
    NSInteger nest_level = 0;

    if (xvim_sb_find_forward(&sb, charset)) {
        start_with_c = xvim_sb_peek(&sb);
        xvim_sb_init(&sb, s, xvim_sb_index(&sb), NSMakeRange(0, s.length));

        NSUInteger pos = (NSUInteger)(strchr(pairs, start_with_c) - pairs);

        look_for_c     = (unichar)pairs[pos ^ 1];
        search_forward = !(pos & 1);
    } else {
        // src is not an open or close char
        // vim does not produce an error msg for this so we won't either i guess
        return NSNotFound;
    }
#undef pairs

    do {
        unichar c = xvim_sb_peek(&sb);

        if (c == look_for_c) {
            if (--nest_level == 0) {
                // found match at proper level
                return xvim_sb_index(&sb);
            }
        } else {
            nest_level += (c == start_with_c);
        }
    } while (search_forward ? xvim_sb_next(&sb) : xvim_sb_prev(&sb));

    return NSNotFound;
}

#pragma mark Vim operation related methods
#define charat(x) [[self string] characterAtIndex:(x)]

- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    if( 0 == index){
        return 0;
    }
    NSUInteger pos;
    NSUInteger index_count = 0;
    for( pos = index; pos > 0; ){
        if( index_count >= count ){
            break;
        }

        if( (opt & LEFT_RIGHT_NOWRAP) && [self isNewline:pos-1] ){
            break;
        }
        
        if( [self isNewline:pos-1] ){
            // skip the newline letter at the end of line
            --pos;
            ++index_count;
        } else {
            NSRange rph = [self rangePlaceHolder:pos option:opt];
            if( rph.location != NSNotFound ){
                pos = rph.location;
            }

            --pos;
            ++index_count;

            rph = [self rangePlaceHolder:pos option:opt];
            if( rph.location != NSNotFound ){
                pos = rph.location;
            }
        } 
    }
    return pos;
}

- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info{
    info->reachedEndOfLine = NO;
    
    if( index == [[self xvim_string] length] )
        return [[self xvim_string] length];
    
    NSUInteger pos = index;
    // If the currenct cursor position is on a newline (blank line) and not wrappable never move the cursor
    if( (opt&LEFT_RIGHT_NOWRAP) && [self isBlankline:pos]){
        return pos;
    }
    
    NSUInteger index_count = 0;
    for( ;pos < [[self xvim_string] length]; ){
        if( [self isEOF:pos+1] ||
            ((opt&LEFT_RIGHT_NOWRAP) && [self isNewline:pos+1]) )
        {
            info->reachedEndOfLine = YES;
            break;
        }

        ++index_count;
        NSRange rph = [self rangePlaceHolder:pos option:opt];
        if( rph.location != NSNotFound ){
            pos = NSMaxRange(rph);
        } else {
            ++pos;
        }
        
        if( [self isEOF:pos] ||
            ((opt&LEFT_RIGHT_NOWRAP) && [self isNewline:pos]) ){
            --pos;
            info->reachedEndOfLine = YES;
            break;
        }
        if( index_count >= count ){
            break;
        }
    }
    return pos;
}

#pragma mark placeholder methods
- (NSRange)rangePlaceHolder:(NSUInteger)index option:(MOTION_OPTION)opt
{
    if( opt&MOPT_PLACEHOLDER ){
        return [self rangePlaceholder:index];
    } else {
        return NSMakeRange(NSNotFound, 0);
    }
}

- (NSRange)rangePlaceholder:(NSUInteger)index
{
    NSString* str = [self xvim_string];
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSUInteger begin = [self firstOfLine:index];
    for( NSUInteger pos = begin; pos + 1 < [[self xvim_string] length]; ++pos ){
        if( [self isEOF:pos] ) break;
        if( [self isNewline:pos+1] ) break;
        unichar uc1 = [str characterAtIndex:pos];
        unichar uc2 = [str characterAtIndex:pos+1];
        if( uc1 == '<' && uc2 == '#' ){
            if( index < pos ){
                range = NSMakeRange(NSNotFound, 0);
                break;
            } else {
                range.location = pos;
                range.length = 0;
            }
        } else if( uc1 == '#' && uc2 == '>' ){
            if( range.location == NSNotFound ){
                // parse error
                break;
            }
            range.length = pos + 1 - range.location + 1;
            if( NSLocationInRange(index, range) ){
                break;
            }
            range = NSMakeRange(NSNotFound, 0);
        }
    }
    return range;
}

- (NSUInteger)firstOfLine:(NSUInteger)index{
    
    NSRange range = [self xvim_indexRangeForLineAtIndex:index newLineLength:NULL];
    return range.location;
}

#pragma mark -

- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);

    NSUInteger lno = [self xvim_lineNumberAtIndex:index];

    lno = lno > count ? lno - count : 1;
    return [self xvim_indexOfLineNumber:lno column:column];
}

- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    
    NSUInteger lno = [self xvim_lineNumberAtIndex:index] + count;
    NSUInteger lines = self.xvim_numberOfLines;

    if (lno > lines) {
        lno = lines;
    }
    return [self xvim_indexOfLineNumber:lno column:column];
}

/** 
 From Vim help: word and WORD
 *word*
 A word consists of a sequence of letters, digits and underscores, or a 
 sequence of other non-blank characters, separated with white space (spaces, 
 tabs, <EOL>).  This can be changed with the 'iskeyword' option.  An empty line 
 is also considered to be a word. 
 
 *WORD* 
 A WORD consists of a sequence of non-blank characters, separated with white 
 space.  An empty line is also considered to be a WORD. 
 
 Special case: "cw" and "cW" are treated like "ce" and "cE" if the cursor is 
 on a non-blank.  This is because "cw" is interpreted as change-word, and a 
 word does not include the following white space.  
 Another special case: When using the "w" motion in combination with an 
 operator and the last word moved over is at the end of a line, the end of 
 that word becomes the end of the operated text, not the first word in the 
 next line. 
**/

/**
 [A] newline -> newline
 [D] word    -> newline
 [G] blank   -> newline
 [B] newline -> word
 [E] word    -> WORD
 [H] blank   -> word
 */
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(nil != info, @"Specify info");
    
    NSUInteger pos = index;
    info->lastEndOfLine = NSNotFound;
    
    if( [self isEOF:index] ){
        return index;
    }
    
    BOOL wordInLineFound = NO;
    NSUInteger curTwoNewLine = NSNotFound;
    NSUInteger lastTwoNewLine = NSNotFound;
    NSUInteger twonewline_count = 0;
    NSUInteger word_count = 0;
    for( pos = index+1 ; pos <= [[self xvim_string] length]; ++pos ){
        NSRange rph = [self rangePlaceHolder:pos option:opt];
        if( [self isEOF:pos] ){
            if( [self isNonblank:pos-1] ){
                info->lastEndOfLine = pos-1;
                info->lastEndOfWord = pos-1;
            }
            info->reachedEndOfLine = YES;
            pos--;
            break;
        }
        if( [self isNewline:pos] ){
            // current new line 
            if( [self isNewline:pos-1] ){
                //two newlines in a row (means blank line)
                //blank line is a word so count it.
                ++twonewline_count;
                lastTwoNewLine = curTwoNewLine;
                curTwoNewLine = pos-1;
                if( lastTwoNewLine != NSNotFound ){
                    info->lastEndOfLine = lastTwoNewLine;
                }
                // [A]
                info->isFirstWordInLine = YES;
                wordInLineFound = YES;
            } else {
                // last word or blank
                // preserve the point
                if( count == 1 ){
                    if( info->lastEndOfLine == NSNotFound ){
                        info->lastEndOfLine = pos-1;
                    }
                } else {
                    info->lastEndOfLine = pos-1;
                }
                // [D,G]
                wordInLineFound = NO;
                if( ![self isNonblank:pos-1] ){
                    info->isFirstWordInLine = YES;
                }
            }
        }
        else if( rph.location != NSNotFound ){
            // from anything to placeholder
            if( rph.location == pos ){
                // - begin of placeholder (ex. from anything to '<#')
                ++word_count;
            } else {
                if( pos < NSMaxRange(rph) ){
                    pos = NSMaxRange(rph)-1;
                }
            }
            // enough to treat as [E]
            info->isFirstWordInLine = NO;
            wordInLineFound = YES;
        }
        else if( [self isNonblank:pos] &&
            ( [self rangePlaceholder:pos-1].location != NSNotFound && rph.location == NSNotFound ))
        {
            // - from placeholder to non-placeholder (ex. from '#>' to '[')
            // enough to treat as [E]
            ++word_count;
            info->isFirstWordInLine = NO;
            wordInLineFound = YES;
        }
        else if( [self isNonblank:pos] ){
            // a word
            if( [self isNewline:pos-1] ){
                // - from newline to word
                // [B]
                ++word_count;
                info->isFirstWordInLine = YES;
                wordInLineFound = YES;
            }else if([self isWhitespaceOrNewline:pos-1]){
                // - from blank to word
                // [H]
                ++word_count;
                if( !wordInLineFound ){
                    info->isFirstWordInLine = YES;
                    wordInLineFound = YES;
                }else{
                    info->isFirstWordInLine = NO;
                }
            } else if( !(opt & BIGWORD) && [self isKeyword:pos-1] != [self isKeyword:pos] ){
                // - another keyword (ex. from '>' to 'a' or from 'a' to '<')
                // [E]
                ++word_count;
                info->isFirstWordInLine = NO;
                wordInLineFound = YES;
            }
        }
        
        if( [self isNewline:pos] && (opt & LEFT_RIGHT_NOWRAP) ){
            pos--;
            break;
        }
        
        if( count <= twonewline_count + word_count ){
            break;
        }
    }
    return pos;
}

- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 1 >= index )
        return 0;
    
    NSUInteger word_count = 0;
    NSUInteger pos = index-1;
    for( ; ; --pos ){
        if( pos == 0 ){
            break;
        }
        NSRange rph = [self rangePlaceHolder:pos option:opt];
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !BIGWORD)
        //    - newline and newline(blankline) 
        if( ([self isNewline:pos-1] && [self isBlankline:pos]) ||
           (([self isWhitespaceOrNewline:pos-1] && [self isNonblank:pos]) ) ||
            (!(opt & BIGWORD) && [self isKeyword:pos-1] != [self isKeyword:pos] && ![self isWhitespaceOrNewline:pos])
        )
        {
            word_count++;
        } else if( [self isNonblank:pos-1] && [self rangePlaceholder:pos-1].location != NSNotFound ){
            word_count++;
            pos = [self rangePlaceholder:pos-1].location;
        } else if( rph.location != NSNotFound ){
            word_count++;
        }
        
        if( pos == 0 ){
            break;
        }
        if([self isNewline:pos-1] && (opt & LEFT_RIGHT_NOWRAP) ){
            break;
        }
        if( rph.location != NSNotFound && rph.location < pos ){
            pos = rph.location;
        }
        if( word_count == count ){
            break;
        }
    }
    return pos;
}

/**
 * Returns position of the end of count words forward.
 *
 * TODO: This can returns NSNotFound if its the "index" is the on the last character of the document.
 *       This is because Vim causes an error(beeps) when type "e" at the end of document.
 *       But currently this returns "index" as a next position to move because all evaluators does not expect NSNotFound
 **/
- (NSUInteger)endOfWordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert( 0 != count , @"count must be greater than 0");
    if( [self isEOF:index] || [self isLastCharacter:index]){
        return index;
    }
    NSUInteger pos = index;
    NSUInteger word_count = 0;
    NSString *string = [self xvim_string];
    for( ; ; ++pos ){
        if( [self isLastCharacter:pos] ){
            break;
        }
        NSRange rph = [self rangePlaceHolder:pos option:opt];
        if( rph.location != NSNotFound ){
            // placeholder
            if( (opt&MOTION_OPTION_CHANGE_WORD) || pos != index ){
                word_count++;
            }
            pos = NSMaxRange(rph) - 1;
            if( [self isLastCharacter:pos] ){
                break;
            }
        } else if( [self isNewline:pos] && [self isNewline:pos+1] ){
            // two NewLine
            if( opt&MOTION_OPTION_CHANGE_WORD ){
                word_count++;
            }
        } else if( (opt&MOTION_OPTION_CHANGE_WORD) && isWhitespace([string characterAtIndex:index]) ){
            // begins with space in case of 'cw'
            if( [self isWhitespace:pos] && ![self isWhitespace:pos+1] ){
                word_count++;
            }
        } else if( ![self isWhitespaceOrNewline:pos] ){
            if( (![self isWhitespaceOrNewline:pos+1] &&
                 !(opt & BIGWORD) &&
                 [self isKeyword:pos] != [self isKeyword:pos+1] ) ||
                [self isWhitespaceOrNewline:pos+1] ||
               [self rangePlaceHolder:pos+1 option:opt].location != NSNotFound
               ){
                if( (opt&MOTION_OPTION_CHANGE_WORD) || pos != index ){
                    word_count++;
                }
            }
        }
        if( word_count == count ){
            break;
        }
    }
    return pos;
}

/**
 * Returns position of the end of count words backward.
 **/
- (NSUInteger)endOfWordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert( 0 != count , @"count must be greater than 0");
    if( [self isEOF:index] || [self isLastCharacter:index]){
        return index;
    }
    NSUInteger pos = index;
    NSUInteger word_count = 0;
    NSString *string = [self xvim_string];
    for( ; ; --pos ){
        if( pos == 0 ){
            break;
        }
        NSRange rph = [self rangePlaceHolder:pos option:opt];
        if( rph.location != NSNotFound ){
            // placeholder
            if( (opt&MOTION_OPTION_CHANGE_WORD) || pos != index ){
                word_count++;
            }
            pos = NSMaxRange(rph) - 1;
            if( [self isLastCharacter:pos] ){
                break;
            }
        } else if( [self isNewline:pos] && [self isNewline:pos+1] ){
            // two NewLine
            if( opt&MOTION_OPTION_CHANGE_WORD ){
                word_count++;
            }
        } else if( (opt&MOTION_OPTION_CHANGE_WORD) && isWhitespace([string characterAtIndex:index]) ){
            // begins with space in case of 'cw'
            if( [self isWhitespace:pos] && ![self isWhitespace:pos+1] ){
                word_count++;
            }
        } else if( ![self isWhitespaceOrNewline:pos] ){
            if( (![self isWhitespaceOrNewline:pos+1] &&
                 !(opt & BIGWORD) &&
                 [self isKeyword:pos] != [self isKeyword:pos+1] ) ||
                [self isWhitespaceOrNewline:pos+1] ||
               [self rangePlaceHolder:pos+1 option:opt].location != NSNotFound
               ){
                if( (opt&MOTION_OPTION_CHANGE_WORD) || pos != index ){
                    word_count++;
                }
            }
        }
        if( word_count == count ){
            break;
        }
    }
    return pos;
}


/*
 Definition of Sentence from gVim help
 
 - A sentence is defined as ending at a '.', '!' or '?' followed by either the
 end of a line, or by a space or tab.  Any number of closing ')', ']', '"'
 and ''' characters may appear after the '.', '!' or '?' before the spaces,
 tabs or end of line.  A paragraph and section boundary is also a sentence
 boundary.
 If the 'J' flag is present in 'cpoptions', at least two spaces have to
 follow the punctuation mark; <Tab>s are not recognized as white space.
 The definition of a sentence cannot be changed.
 */

// TODO: Treat paragraph and section boundary as sections baundary as well
- (NSUInteger)sentencesForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    NSUInteger pos = index+1;
    NSUInteger sentence_head = NSNotFound;
    NSString* s = [self xvim_string];
    NSUInteger sentence_found = 0;
    if( pos >= s.length-1 ){
        return NSNotFound;
    }
    // Search "." or "!" or "?" forward and check if it is followed by spaces(and closing characters)
    for( ; pos < s.length && NSNotFound == sentence_head ; pos++ ){
        unichar c = [s characterAtIndex:pos];
        if( c == '.' || c == '!' || c == '?' ){
            // Check if this is end of a sentence.
            NSUInteger k = pos+1;
            unichar c2 = '\0';
            // Skip )]"'
            for( ; k < s.length ; k++ ){
                c2 = [s characterAtIndex:k];
                if( c2 != ')' && c2 != ']' && c2 != '"' && c2  != '\'' ){
                    break;
                }
            }
            // after )]"' must be space to be end of a sentence.
            if( k < s.length && !isNonblank(c2) ){ // !isNonblank == isBlank
                // This is a end of sentence.
                // Now search for next non blank character to find head of sentence
                for( k++ ; k < s.length ; k++ ){
                    c2 = [s characterAtIndex:k];
                    if(isNonblank(c2)){
                        // Found a head of sentence.
                        sentence_found++;
                        if( count == sentence_found ){
                            sentence_head = k;
                        }
                        break;
                    }
                }
            }
        }
    }
    
    if( sentence_head == NSNotFound && pos == s.length ){
        if( (sentence_found+1) == count ){
            sentence_head = s.length;
            while( ![self isValidCursorPosition:sentence_head] ){
                sentence_head--;
            }
        }
    }
    return sentence_head;
}

- (NSUInteger)sentencesBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    if( 0 == index ){
        return NSNotFound;
    }
    
    NSUInteger pos = index-1; 
    NSUInteger lastSearchBase = index;
    NSUInteger sentence_head = NSNotFound;
    NSString* s = [self xvim_string];
    NSUInteger sentence_found = 0;
    // Search "." or "!" or "?" backwards and check if it is followed by spaces(and closing characters)
    for( ; NSNotFound == sentence_head ; pos-- ){
        if( pos == 0 ){
            // Head of file is always head of sentece
            sentence_found++;
            if( count == sentence_found ){
                sentence_head = pos;
            }
            break;
        }
        unichar c = [s characterAtIndex:pos];
        if( c == '.' || c == '!' || c == '?' ){
            // Check if this is end of a sentence.
            NSUInteger k = pos+1;
            unichar c2 = '\0';
            // Skip )]"'
            for( ; k < lastSearchBase ; k++ ){
                c2 = [s characterAtIndex:k];
                if( c2 != ')' && c2 != ']' && c2 != '"' && c2 != '\'' ){
                    break;
                }
            }
            // after )]"' must be space to be end of a sentence.
            if( k < lastSearchBase && !isNonblank(c2) ){ // !isNonblank == isBlank
                // This is a end of sentence.
                // Now search for next non blank character
                for( k++ ; k < lastSearchBase ; k++ ){
                    c2 = [s characterAtIndex:k];
                    if(isNonblank(c2)){
                        // Found a head of sentence.
                        sentence_found++;
                        if( count == sentence_found ){
                            sentence_head = k;
                        }
                        break;
                    }
                }
            }
            lastSearchBase = pos;
        }
    }
    
    return sentence_head;
}

/*
 Definition of paragraph from gVim help
 
 A paragraph begins after each empty line, and also at each of a set of
 paragraph macros, specified by the pairs of characters in the 'paragraphs'
 option.  The default is "IPLPPPQPP TPHPLIPpLpItpplpipbp", which corresponds to
 the macros ".IP", ".LP", etc.  (These are nroff macros, so the dot must be in
 the first column).  A section boundary is also a paragraph boundary.
 Note that a blank line (only containing white space) is NOT a paragraph
 boundary. 
 
 Note: if MOPT_PARA_BOUND_BLANKLINE is passed in then blank lines with whitespace are paragraph boundaries. This is to get propper function for the delete a paragraph command(dap).
 
 Also note that this does not include a '{' or '}' in the first column.  When
 the '{' flag is in 'cpoptions' then '{' in the first column is used as a
 paragraph boundary |posix|.
 */

- (NSUInteger)paragraphsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    NSUInteger pos = index;
    NSString* s = [self xvim_string];
    if( 0 == pos ){
        pos = 1;
    }
    NSUInteger prevpos = pos - 1;
    
    NSUInteger paragraph_head = NSNotFound;
    NSUInteger paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos < s.length && NSNotFound == paragraph_head ; pos++,prevpos++ ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if(isNewline(prevc) && !isNewline(c)){
            if([self xvim_nextNonblankInLineAtIndex:pos allowEOL:NO] == NSNotFound && opt == MOPT_PARA_BOUND_BLANKLINE){
                paragraph_found++;
                if(count == paragraph_found){
                    paragraph_head = pos;
                    break;
                }
            }
        }
        if( (isNewline(c) && isNewline(prevc)) ){
            if( newlines_skipped ){
                paragraph_found++;
                if( count  == paragraph_found ){
                    paragraph_head = pos;
                    break;
                }else{
                    newlines_skipped = NO;
                }
            }else{
                // skip continuous newlines 
                continue;
            }
        }else{
            newlines_skipped = YES;
        }
    }
    
    if( NSNotFound == paragraph_head   ){
        // end of document
        paragraph_head = s.length;
        while( ![self isValidCursorPosition:paragraph_head] ){
            paragraph_head--;
        }
    }
    
    return paragraph_head;
}

- (NSUInteger)paragraphsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    NSUInteger pos = index;
    NSString* s = [self xvim_string];
    if( pos == 0 ){
        return NSNotFound;
    }
    if( pos == s.length )
    {
        pos = pos - 1;
    }
    NSUInteger prevpos = pos - 1;
    NSUInteger paragraph_head = NSNotFound;
    NSUInteger paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos > 0 && NSNotFound == paragraph_head ; pos--,prevpos-- ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if(isNewline(c) && isNewline(prevc)){
            if( newlines_skipped ){
                paragraph_found++;
                if( count == paragraph_found ){
                    paragraph_head = pos;
                    break;
                }else{
                    newlines_skipped = NO;
                }
            }else{
                // skip continuous newlines 
                continue;
            }
        }else{
            newlines_skipped = YES;
        }
    }
    
    if( NSNotFound == paragraph_head   ){
        // begining of document
        paragraph_head = 0;
    }
    
    return paragraph_head;
}


- (NSUInteger)sectionsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)sectionsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)nextCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEOF:index] ){
        return NSNotFound;
    }
    
    NSUInteger p = index+1; // Search from next character
    if( (opt & MOTION_OPTION_SKIP_ADJACENT_CHAR) && 1 == count && ![self isEOF:p] && [[self xvim_string] characterAtIndex:p] == character) {
        // Need to skip the character when it is found adjacent position.
        p++;
    }
    
    NSUInteger end = [self xvim_endOfLine:p];
    if( NSNotFound == end ){
        return NSNotFound;
    }
    
    for( ; p < end; p++ ){
        if( [[self xvim_string] characterAtIndex:p] == character ){
            count--;
            if( 0 == count ){
                return p;
            }
        }
    }
    
    return NSNotFound;
}

- (NSUInteger)prevCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 0 == index ){
        return NSNotFound;
    }
    
    NSUInteger p = index-1;// Search from next character
    if( (opt & MOTION_OPTION_SKIP_ADJACENT_CHAR) && 1 == count && 0 != p && [[self xvim_string] characterAtIndex:p] == character) {
        // Need to skip the character when it is found adjacent position.
        p--;
    }
    NSUInteger head = [self xvim_firstOfLine:p];
    if( NSNotFound == head ){
        return NSNotFound;
    }
    
    for( ; p != 0 && p >= head ; p-- ){
        if( [[self xvim_string] characterAtIndex:p] == character ){
            count--;
            if( 0 == count){
                return p;
            }
        }
    }
    
    return NSNotFound;
}



- (NSRange)searchRegexForward:(NSString*)pattern from:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(pattern != nil, @"pattern must not be nil");
    
    NSRange ret = NSMakeRange(NSNotFound,0);
    
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if( opt & SEARCH_CASEINSENSITIVE ){
        options |= NSRegularExpressionCaseInsensitive;
    }
    NSError* err = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&err];
    if( err != nil ){
        return ret;
    }
    // Search whole text
    NSArray* matches =  [regex matchesInString:self.string options:0 range:NSMakeRange(0, self.length)];
    
    // First we look for the position in range of [index+1, EOF]
    for( NSTextCheckingResult* result in matches ){
        if( result.range.location > index ){
            count--;
            if( 0 == count){
                ret = [result range];
            }
        }
    }
    
    // Then look for the position in range of [BOF,index] if SEARCH_WRAP
    if( 0 != count && opt & SEARCH_WRAP ){
        for( NSTextCheckingResult* result in matches ){
            if( result.range.location <= index ){
                count--;
                if( 0 == count){
                    ret = [result range];
                }
            }else{
                break;
            }
        }
    }
    
    return ret;
}

- (NSRange)searchRegexBackward:(NSString*)pattern from:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(pattern != nil, @"pattern must not be nil");
    
    NSRange ret = NSMakeRange(NSNotFound,0);
    
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if( opt & SEARCH_CASEINSENSITIVE ){
        options |= NSRegularExpressionCaseInsensitive;
    }
    NSError* err = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&err];
    if( err != nil ){
        return ret;
    }
    // Search whole text
    NSArray* matches =  [regex matchesInString:self.string options:0 range:NSMakeRange(0, self.length)];
    
    // First we look for the position in range of [BOF, index-1] in backwards
    for( NSTextCheckingResult* result in [matches reverseObjectEnumerator] ){
        if( result.range.location < index ){
            count--;
            if( 0 == count){
                ret = [result range];
            }
        }
    }
    
    // Then look for the position in range of [index,EOF] if SEARCH_WRAP
    if( 0 != count && opt & SEARCH_WRAP ){
        for( NSTextCheckingResult* result in [matches reverseObjectEnumerator] ){
            if( result.range.location >= index ){
                count--;
                if( 0 == count){
                    ret = [result range];
                }
            }else{
                break;
            }
        }
    }
    
    return ret;
    
}


// TODO: Fix the warnings
// There are too many warning in following codes.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wuninitialized"
#pragma GCC diagnostic ignored "-Wconversion"
static NSCharacterSet* get_search_set( unichar c, NSCharacterSet* set, NSCharacterSet*);
static NSInteger seek_backwards(NSString*,NSInteger,NSCharacterSet*);
static NSInteger seek_forwards(NSString*,NSInteger,NSCharacterSet*);


/*
 * NSStringHelper is used to provide fast character iteration.
 */
#define ITERATE_STRING_BUFFER_SIZE 64
typedef struct s_NSStringHelper
{
    unichar    buffer[ITERATE_STRING_BUFFER_SIZE];
    __unsafe_unretained NSString*  string;
    NSUInteger strLen;
    NSInteger  index;
    
} NSStringHelper;
void initNSStringHelper(NSStringHelper*, NSString* string, NSUInteger strLen);
void initNSStringHelperBackward(NSStringHelper*, NSString* string, NSUInteger strLen);
unichar characterAtIndex(NSStringHelper*, NSInteger index);

+ (NSCharacterSet *) wordCharSet:(BOOL)isBigWord {
  NSCharacterSet *wordSet = nil;
  if ( isBigWord ) {
    NSCharacterSet *charSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    wordSet = charSet;
  }
  else {
    NSMutableCharacterSet *charSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [charSet addCharactersInString:@"_"];
    wordSet = charSet;
  }
  return wordSet;
}

- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSCharacterSet *wsSet = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet *wordSet = [[self class] wordCharSet:(opt & BIGWORD)];
    NSString* string = [self xvim_string];

    // We search by starting from index = insertionPoint + 1. If the character at the insertion
    // point is a valid word character, we need to reset index back by 1. Otherwise we end up with
    // bugs like this: https://github.com/XVimProject/XVim/issues/554
    if (index > 0 && [wordSet characterIsMember:[string characterAtIndex:index - 1]]) {
        --index;
    }

    NSUInteger length = self.length;
    if (length == 0 || index > length-1) { return NSMakeRange(NSNotFound, 0); }
    NSUInteger maxIndex = self.length - 1;
    
    NSInteger rangeStart = index;
    NSInteger rangeEnd = index;
    
    // repeatCount loop starts here
    while (count--) {
        // Skip past newline
        while (index < maxIndex && isNewline([string characterAtIndex:index])) {
            ++index;
        }
        
        if (index > maxIndex) {
            break;
        }

        unichar initialChar = [string characterAtIndex:index];
        BOOL initialCharIsWs = [wsSet characterIsMember:initialChar];
        NSCharacterSet *searchSet = get_search_set(initialChar, wsSet, wordSet);
        
        NSInteger begin = index;
        NSInteger end = MIN(index + 1, maxIndex);
        
        // Seek backwards
        begin = seek_backwards(string, begin, searchSet);
        
        // Seek forwards
        end = seek_forwards(string, end, searchSet);
        
        // For inclusive mode, try to eat some more
        if ( !(opt & TEXTOBJECT_INNER)) {
            NSInteger newEnd = end;
            if (end >= 0 && (NSUInteger)end < maxIndex) {
                if (initialCharIsWs) {
                    unichar c = [string characterAtIndex:end];
                    searchSet = get_search_set(c, wsSet, wordSet);
                    newEnd = seek_forwards(string, end, searchSet);
                }
                else {
                    newEnd = seek_forwards(string, end, wsSet);
                }
            }

            // If we couldn't eat anything from the end, try to eat start
            NSInteger newBegin = begin;
            if (newEnd == end) {
                if (!initialCharIsWs) {
                    newBegin = seek_backwards(string, begin, wsSet);
                    
                    // Never remove a line's leading whitespace
                    if (newBegin == 0 || isNewline([string characterAtIndex:newBegin - 1])) {
                        newBegin = begin;
                    }
                }
            }
            
            begin = newBegin;
            end = newEnd;
        }
        
        index = end;
        
        rangeStart = MIN(rangeStart, begin);
        rangeEnd = MAX(rangeEnd, end);
    }
    
    return NSMakeRange(rangeStart, rangeEnd - rangeStart);
}

// The following code is from xVim by WarWithinMe.
// These will be integreted into NSTextView category.
// ==========
// NSStringHelper
void initNSStringHelper(NSStringHelper* h, NSString* string, NSUInteger strLen)
{
    h->string = string;
    h->strLen = strLen;
    h->index  = -ITERATE_STRING_BUFFER_SIZE;
}

void initNSStringHelperBackward(NSStringHelper* h, NSString* string, NSUInteger strLen)
{
    h->string = string;
    h->strLen = strLen;
    h->index  = strLen;
}

NSInteger fetchSubStringFrom(NSStringHelper* h, NSInteger index);
NSInteger fetchSubStringFrom(NSStringHelper* h, NSInteger index)
{
    assert(index>=0);
    NSInteger copyBegin = index;
    NSInteger size      = ((NSUInteger)index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index);
NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index)
{
    assert(index>=0);
    NSInteger copyBegin = (index + 1) >= ITERATE_STRING_BUFFER_SIZE ? index + 1 - ITERATE_STRING_BUFFER_SIZE : 0;
    NSInteger size      = ((NSUInteger)index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

unichar characterAtIndex(NSStringHelper* h, NSInteger index)
{
    if (h->index > index)
    {
        h->index = fetchSubStringEnds(h, index);
    } else if (index >= (h->index + ITERATE_STRING_BUFFER_SIZE))
    {
        h->index = fetchSubStringFrom(h, index);
    }
    return h->buffer[index - h->index];
}

NSInteger xv_caret(NSString *string, NSInteger index)
{
    NSInteger resultIndex  = index;
    NSInteger seekingIndex = index;
    
    while (seekingIndex > 0) {
        unichar ch = [string characterAtIndex:seekingIndex-1];
        if (isNewline(ch)) {
            break;
        } else if (ch != '\t' && ch != ' ') {
            resultIndex = seekingIndex - 1;
        }
        --seekingIndex;
    }
    
    if (resultIndex == index) {
        NSInteger maxIndex = [string length] - 1;
        while (resultIndex < maxIndex) {
            unichar ch = [string characterAtIndex:resultIndex];
            if (isNewline(ch) || isWhitespace(ch) == NO) {
                break;
            }
            ++resultIndex;
        }
    }
    
    return resultIndex;
}

NSInteger xv_0(NSString *string, NSInteger index)
{    
    while (index > 0)
    {
        if (isNewline([string characterAtIndex:index-1])) { break; }
        --index;
    }
    return index;
}


// A port from vim's findmatchlimit, simplied version.
// This one only works for (), [], {}, <>
// Return -1 if we cannot find it.
// cpo_match is YES means ignore quotes.
#define MAYBE     2
#define FORWARD   1
#define BACKWARD -1
int findmatchlimit(NSString* string, NSInteger pos, unichar initc, BOOL cpo_match);
int findmatchlimit(NSString* string, NSInteger pos, unichar initc, BOOL cpo_match)
{ 
    // ----------
    unichar    findc           = 0; // The char to find.
    BOOL       backwards       = NO;
    
    int        count           = 0;      // Cumulative number of braces.
    int        do_quotes       = -1;     // Check for quotes in current line.
    int        at_start        = -1;     // do_quotes value at start position.
    int        start_in_quotes = MAYBE;  // Start position is in quotes
    BOOL       inquote         = NO;     // YES when inside quotes
    int        match_escaped   = 0;      // Search for escaped match.
    
    // NSInteger pos             = cursor; // Current search position
    // BOOL      cpo_match       = YES;    // cpo_match = (vim_strchr(p_cpo, CPO_MATCH) != NULL);
    BOOL       cpo_bsl         = NO;     // cpo_bsl = (vim_strchr(p_cpo, CPO_MATCHBSL) != NULL);
    
    // ----------
    char*      b_p_mps         = "(:),{:},[:],<:>";
    for (char* ptr = b_p_mps; *b_p_mps; ptr += 2) 
    {
        if (*ptr == initc) {
            findc = initc;
            initc = ptr[2];
            backwards = YES;
            break;
        }
        
        ptr += 2;
        if (*ptr == initc) {
            findc = initc;
            initc = *(ptr - 2);
            backwards = NO;
            break;
        }
        
        if (ptr[1] != ',') { break; } // Invalid initc!
    }
    
    if (findc == 0) { return -1; }
    
    // ----------
    
    
    // ----------
    NSStringHelper  help;
    NSStringHelper* h        = &help;
    NSInteger       maxIndex = [string length] - 1; 
    backwards ? initNSStringHelperBackward(h, string, maxIndex+1) : initNSStringHelper(h, string, maxIndex+1);
    
    // ----------
    while (YES)
    {
        if (backwards)
        {
            if (pos == 0) { break; } // At start of file
            --pos;
            
            if (isNewline(characterAtIndex(h, pos)))
            {
                // At prev line.
                do_quotes = -1;
            }
        } else {  // Forward search
            if (pos == maxIndex) { break; } // At end of file
            
            if (isNewline(characterAtIndex(h, pos))) {
                do_quotes = -1;
            }
            
            ++pos;
        }
        
        // ----------
        // if (pos.col == 0 && (flags & FM_BLOCKSTOP) && (linep[0] == '{' || linep[0] == '}'))
        // if (comment_dir)
        // ----------
        
        if (cpo_match) {
            do_quotes = 0;
        } else if (do_quotes == -1)
        {
            /*
             * Count the number of quotes in the line, skipping \" and '"'.
             * Watch out for "\\".
             */
            at_start = do_quotes;
            
            NSInteger ptr = pos;
            while (ptr > 0 && !isNewline([string characterAtIndex:ptr-1])) { --ptr; }
            NSInteger sta = ptr;
            
            while (ptr < maxIndex && 
                   !isNewline(characterAtIndex(h, ptr)))
            {
                if (ptr == pos + backwards) { at_start = (do_quotes & 1); }
                
                if (characterAtIndex(h, ptr) == '"' &&
                    (ptr == sta || 
                     characterAtIndex(h, ptr - 1) != '\'' || 
                     characterAtIndex(h, ptr + 1) != '\'')) 
                {
                    ++do_quotes;
                }
                
                if (characterAtIndex(h, ptr) == '\\' && 
                    ptr + 1 < maxIndex && 
                    !isNewline(characterAtIndex(h, ptr+1))) 
                { ++ptr; }
                ++ptr;
            }
            do_quotes &= 1; // result is 1 with even number of quotes
            
            //
            // If we find an uneven count, check current line and previous
            // one for a '\' at the end.
            //
            if (do_quotes == 0)
            {
                inquote = NO;
                if (start_in_quotes == MAYBE)
                {
                    // Do we need to use at_start here?
                    inquote = YES;
                    start_in_quotes = YES;
                } else if (backwards)
                {
                    inquote = YES;
                }
                
                if (sta > 1 && characterAtIndex(h, sta - 2) == '\\')
                {
                    // Checking last char fo previous line.
                    do_quotes = 1;
                    if (start_in_quotes == MAYBE) {
                        inquote = at_start != 0;
                        if (inquote) {
                            start_in_quotes = YES;
                        }
                    } else if (!backwards)
                    {
                        inquote = YES;
                    }
                }
            }
        }
        if (start_in_quotes == MAYBE) {
            start_in_quotes = NO;
        }
        
        unichar c = characterAtIndex(h, pos);
        switch (c) {
                
            case '"':
                /* a quote that is preceded with an odd number of backslashes is
                 * ignored */
                if (do_quotes)
                {
                    NSInteger col = pos;
                    int qcnt = 0;
                    unichar c2;
                    while (col > 0) {
                        --col;
                        c2 = characterAtIndex(h, col);
                        if (isNewline(c2) || c2 != '\\') {
                            break;
                        }
                        ++qcnt;
                    }
                    if ((qcnt & 1) == 0) {
                        inquote = !inquote;
                        start_in_quotes = NO;
                    }
                }
                break;
                
            case '\'':
                if (!cpo_match && initc != '\'' && findc != '\'')
                {
                    if (backwards)
                    {
                        NSInteger p1 = pos;
                        int col = 0;
                        while (p1 > 0 && col < 3) {
                            --p1;
                            if (isNewline(characterAtIndex(h, p1))) {
                                break;
                            }
                            ++col;
                        }
                        
                        if (col > 1)
                        {
                            if (characterAtIndex(h, pos - 2) == '\'')
                            {
                                pos -= 2;
                                break;
                            } else if (col > 2 &&
                                       characterAtIndex(h, pos - 2) == '\\' &&
                                       characterAtIndex(h, pos - 3) == '\'')
                            {
                                pos -= 3;
                                break;
                            }
                        }
                    } else {
                        // Forward search
                        if (pos < maxIndex && !isNewline(characterAtIndex(h, pos + 1)))
                        {
                            if (characterAtIndex(h, pos + 1) == '\\' &&
                                (pos < maxIndex - 2) &&
                                !isNewline(characterAtIndex(h, pos + 2)) &&
                                characterAtIndex(h, pos + 3) == '\'') 
                            {
                                pos += 3;
                                break;
                            } else if (pos < maxIndex - 1 && 
                                       characterAtIndex(h, pos + 2) == '\'')
                            {
                                pos += 2;
                                break;
                            }
                        }
                    }
                }
                /* FALLTHROUGH */
                
            default:
                /* Check for match outside of quotes, and inside of
                 * quotes when the start is also inside of quotes. */
                if ((!inquote || start_in_quotes == YES) && 
                    (c == initc || c == findc))
                {
                    int bslcnt = 0;
                    
                    if (!cpo_bsl)
                    {
                        NSInteger col = pos;
                        unichar c2;
                        while (col > 0) {
                            --col;
                            c2 = characterAtIndex(h, col);
                            if (isNewline(c2) || c2 != '\\') {
                                break;
                            }
                            ++bslcnt;
                        }
                    }
                    /* Only accept a match when 'M' is in 'cpo' or when escaping
                     * is what we expect. */
                    if (cpo_bsl || (bslcnt & 1) == match_escaped)
                    {
                        if (c == initc)
                            count++;
                        else
                        {
                            if (count == 0)
                                return (int)pos;
                            --count;
                        }
                    }
                }
        }
        
    } // End of while
    
    return -1;
}

//- (NSRange) currentBlock:(NSUInteger)index count:(NSUInteger)count 
NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger count, BOOL inclusive, char what, char other)
{
    NSInteger idx    = index;
    
    if ([string characterAtIndex:idx] == what)
    {
        /* cursor on '(' or '{', move cursor just after it */
        ++idx;
        if ((NSUInteger)idx >= [string length]) {
            return NSMakeRange(NSNotFound, 0);
        }
	}
  
	if ([string characterAtIndex:idx] == other)
	{
        /* cursor on ')' or '}', move cursor just before it */
		--idx;
		if (idx < 0) {
			return NSMakeRange(NSNotFound, 0);
		}
	}
	
    NSInteger start_pos = idx;
    NSInteger end_pos   = idx;
    
    while (count-- > 0)
    {
        /*
         * Search backwards for unclosed '(', '{', etc..
         * Put this position in start_pos.
         * Ignore quotes here.
         */
        if ((start_pos = findmatchlimit(string, start_pos, what, YES)) == -1)
        {
            return NSMakeRange(NSNotFound, 0);
        }
        
        /*
         * Search for matching ')', '}', etc.
         * Put this position in end_pos.
         * Ignore quotes here.
         */
        if ((end_pos = findmatchlimit(string, end_pos, other, YES)) == -1) {
            return NSMakeRange(NSNotFound, 0);
        }
    }
    
    if (!inclusive)
    {
        ++start_pos;
        if (what == '{')
        {
            NSInteger oldIdx = index;
            index = end_pos;
            NSInteger idx = xv_caret(string, index);
            
            if (idx == end_pos)
            {
                // The '}' is only preceded by indent, skip that indent.
                //end_pos = [self firstOfLine:index]-1;
                end_pos = xv_0(string ,index)-1;
            }
            index = oldIdx;
        }
    } else {
        ++end_pos;
    }
    
    return NSMakeRange(start_pos, end_pos - start_pos);
}

static NSInteger seek_backwards(NSString *string, NSInteger begin, NSCharacterSet *charSet)
{
    while (begin > 0)
    {
		unichar ch = [string characterAtIndex:begin - 1];
        if (![charSet characterIsMember:ch]) { break; }
        --begin;
    }
	
	return begin;
}

static NSInteger seek_forwards(NSString *string, NSInteger end, NSCharacterSet *charSet)
{
	while (end >=0 && (NSUInteger)end < [string length])
	{
		unichar ch = [string characterAtIndex:end];
		if (![charSet characterIsMember:ch]) { break; }
		++end;
	}
	return end;
}

static NSCharacterSet *get_search_set(unichar initialChar, NSCharacterSet *wsSet, NSCharacterSet *wordSet)
{
	NSCharacterSet *searchSet = nil;
	
	if ([wsSet characterIsMember:initialChar])
	{
		searchSet = wsSet;
	}
	else if ([wordSet characterIsMember:initialChar])
	{
		searchSet = wordSet;
	}
	else
	{
		NSMutableCharacterSet *charSet = [[wordSet invertedSet] mutableCopy];
		[charSet removeCharactersInString:@" \t"];
		searchSet = charSet;
	}
	
	return searchSet;
}

NSInteger find_next_quote(NSString* string, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape);
NSInteger find_next_quote(NSString* string, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape)
{
	BOOL ignoreNextChar = NO;
	
    while (start < max)
    {
        unichar ch = [string characterAtIndex:start];
		if (isNewline(ch)) { break; }
		
		if (!ignoreNextChar || ignoreEscape)
		{
			if (ch == quote)     { return start; }
			ignoreNextChar = (ch == '\\');
		}
		else
		{
			ignoreNextChar = NO;
		}
		
		++start;
    }
    
    return -1;
}

NSInteger find_prev_quote(NSString* string, NSInteger start, unichar quote, BOOL ignoreEscape);
NSInteger find_prev_quote(NSString* string, NSInteger start, unichar quote, BOOL ignoreEscape)
{
	NSInteger pendingi = -1;
	NSInteger pendingQuote = -1;
	
    while (start >= 0)
    {
		unichar ch = [string characterAtIndex:start];	
        if (isNewline(ch)) { break; }
		
		if (ch == '\\' && !ignoreEscape)
		{
			NSInteger temp = pendingi;
			pendingi = pendingQuote;
			pendingQuote = temp;
		}
		else
		{
			pendingQuote = -1;
		}
		
		if (pendingi >= 0)
		{
			break;
		}
		
		if (ch == quote) 
		{ 
			pendingi = start;
		}
		
		--start;
    }
    
    return pendingi;
}

NSRange xv_current_quote(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, char what)
{
	NSInteger begin = find_prev_quote(string, index, what, NO);
	if (begin == -1)
	{
		begin = find_next_quote(string, index, [string length], what, NO);
	}
	
	if (begin < 0)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	NSInteger end = find_next_quote(string, begin + 1, [string length], what, NO);
	if (end < 0)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	if (inclusive)
	{
		end = end + 1;
		
		NSInteger newBegin = begin;
		NSInteger newEnd = end;
		
		if (index >= (NSUInteger)begin)
		{
			newEnd = seek_forwards(string, end, [NSCharacterSet whitespaceCharacterSet]);
		}
		
		if (index < (NSUInteger)begin || newEnd == end)
		{
			newBegin = seek_backwards(string, begin, [NSCharacterSet whitespaceCharacterSet]);
		}
		
		begin = newBegin;
		end = newEnd;
	}
	else
	{
		begin = begin + 1;
	}
	
	return NSMakeRange(begin, end - begin);
}

NSInteger xv_findChar(NSString *string, NSInteger index, int repeatCount, char command, unichar what, BOOL inclusive)
{
    int increment = command <= 'Z' ? -1 : 1; // Capital means backward.
    
    NSInteger maxIdx = [string length] - 1;
    NSInteger idx    = index;
    NSInteger result = idx;
    
    NSStringHelper  help;
    NSStringHelper* h   = &help;
    
    if (increment == -1) 
        initNSStringHelperBackward(h, string, maxIdx + 1);
    else
        initNSStringHelper(h, string, maxIdx + 1);
    
    idx += increment;
    while (idx >= 0 && idx <= maxIdx) 
    {
        unichar ch = characterAtIndex(h, idx);
        if (ch == what) 
        {
            if ((--repeatCount) == 0) {
                result = idx; // Found
                break;
            }
        } else if (isNewline(ch))
        {
            break; // Only search in current line.
        }
        idx += increment;
    }
    
    if (result == idx)
    {
        if (command == 't') {
            --result;
        } else if (command == 'T') {
            ++result;
        }
        
        if (inclusive && increment == 1) // Include the position we found.
        {
            ++result;
        }
    }
    
    return result;
}
#pragma GCC diagnostic pop


#pragma mark Conversions

- (NSUInteger)convertToValidCursorPositionForNormalMode:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    // If the current cursor position is not valid for normal mode move it.
    if( ![self isValidCursorPosition:index] ){
        return index-1;
    }
    return index;
}

- (void)xvim_undoCursorPos:(NSNumber*)num{
    // The follwing way to obtain NSTextView from NSTextStorage is adopted by AppKit too.
    // See NSUndoTextOperation findTextViewForTextStorage method
    NSTextView* view = [(NSLayoutManager*)[self.layoutManagers firstObject] firstTextView];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION,DEFAULT_MOTION_TYPE , MOTION_OPTION_NONE, 1);
    m.position = num.unsignedIntegerValue;
    [view xvim_move:m];
}

#pragma mark textobjec camel case

-(NSRange)currentCamelCaseWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt {
    
    NSRange range;
    
    // try underscore textobject.
    range = [self rangeOfBlcoks:^NSRange(NSInteger idx) {
        return [self rangeOfIncludesSurrundingCharacter:'_' fromIndex:(NSUInteger)idx];
    } beginPos:(NSInteger)index count:count];
    
    if( range.length != 0 ) {
        // underscore textobject.
        if( opt & TEXTOBJECT_INNER) {
            range = NSMakeRange(range.location + 1, range.length - 2);
        }
    } else {
        // try camelcase textobject.
        
        range = [self rangeOfBlcoks:^NSRange(NSInteger idx) {
            return [self rangeOfCamelcaseSurrundingCharacterWithFromIndex:idx];
        } beginPos:(NSInteger)index count:count];
    }
    
    return range;
}

-(NSRange)rangeOfCamelcaseSurrundingCharacterWithFromIndex:(NSInteger)index {
    NSString* string = [self xvim_string];
    
    if( (NSUInteger)index >= self.length )  {
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSCharacterSet* upperCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet* lowerCharSet = [NSCharacterSet lowercaseLetterCharacterSet];
    NSCharacterSet* numberCharSet = [NSCharacterSet decimalDigitCharacterSet];
    
    
    NSInteger beginPos = index;
    NSInteger endPos = index;
    
    unichar currentCh = [string characterAtIndex:(NSUInteger)index];
    
    if( [upperCharSet characterIsMember:currentCh] ) {
        unichar nextCh = [self safetyCharacterAtIndex:(NSUInteger)index + 1 fromString:string];
        
        // example: MyPDFViewer. current 'V' => Viewer
        if( [lowerCharSet characterIsMember:nextCh] ) {
            beginPos = index;
            endPos = seek_forwards(string, index + 1, lowerCharSet);
            
        // example: MyPDFViewer. current 'D' or 'F' => PDF
        } else if( [upperCharSet characterIsMember:nextCh] ) {
            beginPos = seek_backwards(string, index + 1, upperCharSet);
            endPos = seek_forwards(string, index + 1, upperCharSet);
            
            nextCh = [self safetyCharacterAtIndex:(NSUInteger)endPos fromString:string];
            
            if( [lowerCharSet characterIsMember:nextCh] ) {
                --endPos;
            }
        // example: MyPDF_. current 'F' => PDF
        } else {
            endPos = index + 1;
            beginPos = seek_backwards(string, endPos, upperCharSet);
        }
        
    } else if([lowerCharSet characterIsMember:currentCh]) {
        unichar nextCh = [self safetyCharacterAtIndex:(NSUInteger)index + 1 fromString:string];
        
        // example: MyPDFViewer. current 'i' or 'e' => Viewer
        if( [lowerCharSet characterIsMember:nextCh] ) {
            beginPos = seek_backwards(string, index + 1, lowerCharSet);
            endPos = seek_forwards(string, index + 1, lowerCharSet);
        // example: MyPDFViewer. current 'r' => Viewer
        } else {
            endPos = index + 1;
            beginPos = seek_backwards(string, endPos, lowerCharSet);
        }
        
        unichar prevCh = [self safetyCharacterAtIndex:(NSUInteger)beginPos - 1 fromString:string];
        if( [upperCharSet characterIsMember:prevCh] ) {
            --beginPos;
        }
    } else {
        // numbers, symbols
        
        NSMutableCharacterSet* tempCharSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [tempCharSet formUnionWithCharacterSet:upperCharSet];
        [tempCharSet formUnionWithCharacterSet:lowerCharSet];
        [tempCharSet formUnionWithCharacterSet:numberCharSet];
        NSCharacterSet* allSymbolCharSet = [tempCharSet invertedSet];
        
        NSArray* otherCharSets = @[numberCharSet, allSymbolCharSet];
        __block NSRange result = NSMakeRange(NSNotFound, 0);
        [otherCharSets enumerateObjectsUsingBlock:^(id  obj, NSUInteger idx, BOOL* stop) {
            
            NSCharacterSet* charSet = obj;
            if([charSet characterIsMember:currentCh]) {
                
                NSInteger beginPos = seek_backwards(string, index + 1, charSet);
                NSInteger endPos = seek_forwards(string, index + 1, charSet);
                
                result = NSMakeRange((NSUInteger)beginPos, (NSUInteger)(endPos - beginPos));
                *stop = YES;
            }
        }];
        return result;
    }
    
    if( beginPos == index && endPos == index ) {
        return NSMakeRange(NSNotFound, 0);
    }
    NSRange result = NSMakeRange((NSUInteger)beginPos, (NSUInteger)(endPos - beginPos));
    return result;
}

-(unichar)safetyCharacterAtIndex:(NSUInteger)index fromString:(NSString*)str {
    if( index >= str.length ) {
        return 0;
    } else {
        return [str characterAtIndex:index];
    }
}

-(NSRange)rangeOfBlcoks:(NSRange (^)(NSInteger index))block beginPos:(NSInteger)beginPos count:(NSUInteger)count {
    
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSInteger currentIndex = beginPos;
    
    while( count > 0 ) {
        if( range.location != NSNotFound ) {
            currentIndex = (NSInteger)range.location + (NSInteger)range.length;
        }
        NSRange tempRange = block(currentIndex);
        if( tempRange.location == NSNotFound ) {
            break;
        } else {
            if( range.location == NSNotFound ) {
                range.location = tempRange.location;
            }
            range.length += tempRange.length;
        }
        --count;
    }
    return range;
}


#pragma mark underscore textobject

-(NSRange)rangeOfIncludesSurrundingCharacter:(unichar)character fromIndex:(NSUInteger)index {
    NSCharacterSet* underScoreCharSet = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    
    NSMutableCharacterSet* tempCharSet = [NSMutableCharacterSet new];
    [tempCharSet formUnionWithCharacterSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    [tempCharSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
    [tempCharSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSCharacterSet* delimiters = [tempCharSet invertedSet];
    
    NSUInteger beginIndex = [self findBackwardsCharacterSet:underScoreCharSet beginPos:index delimiters:delimiters];
    if( beginIndex == NSNotFound ) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    NSUInteger endIndex = NSNotFound;
    if( beginIndex == index ) {
        endIndex = [self findForwardCharacterSet:underScoreCharSet beginPos:index + 1 delimiters:delimiters];
        if( endIndex == NSNotFound ) {
            endIndex = beginIndex;
            beginIndex = [self findBackwardsCharacterSet:underScoreCharSet beginPos:index - 1 delimiters:delimiters];
        }
    } else {
        endIndex = [self findForwardCharacterSet:underScoreCharSet beginPos:index delimiters:delimiters];
    }
    
    if( endIndex == NSNotFound ) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    if( endIndex == beginIndex ) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    return NSMakeRange(beginIndex, endIndex - beginIndex + 1);
}

-(NSUInteger)findForwardCharacterSet:(NSCharacterSet*)charSet beginPos:(NSUInteger)beginPos delimiters:(NSCharacterSet*)delimiters {
    NSString* string = [self xvim_string];
    
    NSUInteger index = beginPos;
    NSUInteger result = NSNotFound;
    
    while( index < string.length ) {
        unichar currentCh = [string characterAtIndex:index];
        if( [charSet characterIsMember:currentCh] ) {
            result = index;
            break;
        } else if( [delimiters characterIsMember:currentCh] ) {
            break;
        }
        ++index;
    }
    return result;
}

-(NSUInteger)findBackwardsCharacterSet:(NSCharacterSet*)charSet beginPos:(NSUInteger)beginPos delimiters:(NSCharacterSet*)delimiters {
    NSString* string = [self xvim_string];
    
    NSUInteger index = MIN(beginPos, string.length - 1);
    NSUInteger result = NSNotFound;
    
    while( index != (NSUInteger)-1 ) {
        unichar currentCh = [string characterAtIndex:index];
        if( [charSet characterIsMember:currentCh] ) {
            result = index;
            break;
        } else if( [delimiters characterIsMember:currentCh] ) {
            break;
        }
        --index;
    }
    return result;
}


@end
