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
    
    NSString* string = [self xvim_string];
    NSUInteger pos = index;
    for (NSUInteger i = 0; i < count && pos != 0 ; i++)
    {
        //Try move to prev position and check if its valid position.
        NSUInteger prev = pos-1; //This is the position where we are trying to move to.
        // If the position is new line and its not wrapable we stop moving
        if( opt == LEFT_RIGHT_NOWRAP && isNewline([[self xvim_string] characterAtIndex:prev]) ){
            break; // not update the position
        }
        
        // If its wrapable, skip newline except its blankline
        if (isNewline([string characterAtIndex:prev])) {
            if(![self isBlankline:prev]) {
                // skip the newline letter at the end of line
                prev--;
            }
        }
        
        if(charat(prev) == '>' && prev){
            //possible autocomplete glyph that we should skip.
            if(charat(prev - 1) == '#'){
                NSUInteger findstart = prev;
                while (--findstart ) {
                    if(charat(findstart) == '#'){
                        if(charat(findstart - 1) == '<'){
                            prev = findstart - 1;
                            break;
                        }
                    }
                }
            }
        }
        
        // Now the position can be move to the prev
        pos = prev;
    }
    return pos;
}

- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info{
    info->reachedEndOfLine = NO;
    
    if( index == [[self xvim_string] length] )
        return [[self xvim_string] length];
    
    NSString* string = [self xvim_string];
    NSUInteger pos = index;
    // If the currenct cursor position is on a newline (blank line) and not wrappable never move the cursor
    if( opt == LEFT_RIGHT_NOWRAP && [self isBlankline:pos]){
        return pos;
    }
    
    for (NSUInteger i = 0; i < count && pos < self.length; i++) {
        NSUInteger next = pos + 1;
        // If the next position is the end of docuement and current position is not a newline
        // Never move a cursor to the end of document.
        if( [self isEOF:next] && !isNewline([string characterAtIndex:pos]) ){
            info->reachedEndOfLine = YES;
            break;
        }
        
        if( opt == LEFT_RIGHT_NOWRAP && isNewline([[self xvim_string] characterAtIndex:next]) ){
            info->reachedEndOfLine = YES;
            break;
        }
        
        // If the next position is newline and not a blankline skip it
        if (isNewline([string characterAtIndex:next])) {
            if(![self isBlankline:next]) {
                // skip the newline letter at the end of line
                next++;
            }
        }
        pos = next;
    }
    return pos;
}

- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);

    NSUInteger lno = [self xvim_lineNumberAtIndex:index];

    lno = lno < count ? 1 : lno - count;
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

- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimMotionInfo*)info{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(nil != info, @"Specify info");
    
    NSUInteger pos = index;
    info->isFirstWordInLine = NO;
    info->lastEndOfLine = NSNotFound;
    info->lastEndOfWord = NSNotFound;
    
    if( [self isEOF:index] ){
        return index;
    }
    
    NSString* str = [self xvim_string];
    unichar lastChar= [str characterAtIndex:index];
    BOOL wordInLineFound = NO;
    for(NSUInteger i = index+1 ; i <= [[self xvim_string] length]; i++ ){
        // Each time we encounter new word decrement "counter".
        // Remember blankline is a word
        unichar curChar; 
        
        if( ![self isEOF:i] ){
            curChar = [str characterAtIndex:i];
        }else {
            //EOF found so return this position.
            if( isNonblank(lastChar)){
                info->lastEndOfLine = i-1;
                info->lastEndOfWord = i-1;
            }
            info->reachedEndOfLine = YES;
            return i-1;
        } 
        
        //Check relation between last and current character to determine the word boundary
        if(isNewline(lastChar)){
            if(isNewline(curChar)){
                //two newlines in a row (means blank line)
                //blank line is a word so count it.
                --count;
                info->lastEndOfWord = i-1;
                info->lastEndOfLine = i-1;
                info->isFirstWordInLine = YES;
                wordInLineFound = YES;
            }else if(isNonblank(curChar)){
                // A word found
                --count;
                info->isFirstWordInLine = YES;
                wordInLineFound = YES;
            }else {
                // Nothing
            }
        }else if(isNonblank(lastChar)){
            if(isNewline(curChar)){
                //from word to newline
                info->lastEndOfLine = i-1;
                info->lastEndOfWord = i-1;
                wordInLineFound = NO;
            }else if(isNonblank(curChar)){
                if(isKeyword(lastChar) != isKeyword(curChar) && opt != BIGWORD){
                    --count;
                    info->lastEndOfLine = i-1;
                    info->lastEndOfWord = i-1;
                    info->isFirstWordInLine = NO;
                    wordInLineFound = YES;
                }
            }else{
                // non-blank to blank
                info->lastEndOfWord = i-1;
            }
        }else { //on a blank character that is not a newline
            if(isNewline(curChar)){
                //blank to newline boundary
                info->lastEndOfLine = i-1;
                info->isFirstWordInLine = YES;
                wordInLineFound = NO;
            }else if(isNonblank(curChar)){
                // blank to non-blank. A word found.
                --count;
                if( !wordInLineFound){
                    info->isFirstWordInLine = YES;
                    wordInLineFound = YES;
                }else{
                    info->isFirstWordInLine = NO;
                }
            }else{
                //Two blanks in a row...
                //nothing to do here.
            }
        }
        
        lastChar = curChar;
        if( isNewline(curChar) && opt == LEFT_RIGHT_NOWRAP ){
            pos = i-1;
            break;
        }
        
        if( 0 == count ){
            pos = i;
            break;
        }
    }
    return pos;
}

- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 1 >= index )
        return 0;
    NSUInteger indexBoundary = NSNotFound;
    NSUInteger pos = index-1;
    unichar lastChar = [[self xvim_string] characterAtIndex:pos];
    // FIXME: This must consider the placeholders
    //        The reason currently commented out is that this method is in NSTextStorage
    //        but the placeholder related codes are in DVTSourceTextView
    //        There should be some method to obtain placeholder range in DVTSourceTextStorage
    // NSArray* placeholdersInLine = [self placeholdersInLine:pos];
    
    for(NSUInteger i = pos-1 ; ; i-- ){
        // Each time we encounter head of a word decrement "counter".
        // Remember blankline is a word
        /*
        indexBoundary = NSNotFound;
        for (NSUInteger currentPlaceholders = 0; currentPlaceholders < [placeholdersInLine count]; currentPlaceholders++) {
            NSValue* currentRange;
            NSUInteger lowIndex, highIndex;
            
            //get the range returned from the placeholderinline function
            currentRange = (NSValue*)[placeholdersInLine objectAtIndex:currentPlaceholders];
            lowIndex = [currentRange rangeValue].location;
            highIndex = [currentRange rangeValue].location + [currentRange rangeValue].length;
            
            // check if we are in the placeholder boundary and if we are we should break and count it as a word.
            if(i >= lowIndex && i <= highIndex){
                indexBoundary = lowIndex;
                break;
            }
        }
         */
        unichar curChar = [[self xvim_string] characterAtIndex:i];
        
        // this branch handles the case that we found a placeholder.
        // must update the pointer into the string and update the current character found to be at the current index.
        if(indexBoundary != NSNotFound){
            count--;
            i = indexBoundary;
            if (count == 0) {
                pos = i;
                break;
            }
            curChar = [[self xvim_string] characterAtIndex:i];
        }
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !BIGWORD)
        //    - newline and newline(blankline) 
        else if(
           ((isWhitespace(curChar) || isNewline(curChar)) && isNonblank(lastChar))   ||
           ( opt != BIGWORD && isKeyword(curChar) && !isKeyword(lastChar) && !isWhitespace(lastChar) && !isNewline(lastChar))   ||
           ( opt != BIGWORD && !isKeyword(curChar) && !isWhitespace(curChar) && !isNewline(lastChar) && isKeyword(lastChar) )  ||
           ( isNewline(curChar) && [self isBlankline:i+1] )
           ){
            count--; 
        }
        
        lastChar = curChar;
        if( 0 == i ){
            pos = 0;
            break;
        }
        if( 0 == count || (isNewline(curChar) && opt == LEFT_RIGHT_NOWRAP) ){
            pos = i+1;
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

    NSUInteger length = self.length;

    if (index >= length - 1) {
        return index;
    }

    NSUInteger p;
    if( opt & MOTION_OPTION_CHANGE_WORD ){
        p = index;
    } else {
        p = index+1; // We start searching end of word from next character
    }
    NSString *string = [self xvim_string];
    while (p < length - 1) {
        unichar curChar = [string characterAtIndex:p];
        unichar nextChar = [string characterAtIndex:p+1];
        // Find the border of words.
        // Vim defines "Blank Line as a word" but 'e' does not stop on blank line.
        // Thats why we are not seeing blank line as a border of a word here (commented out the condition currently)
        // We may add some option to specify if we count a blank line as a word here.
        if( opt & BIGWORD ){
            if( /*[self isBlankline:p]                               || */// blank line
               (isNonblank(curChar) && !isNonblank(nextChar))             // non blank to blank
               ){
                count--;
            }
        }else{
            if( /*[self isBlankline:p]                               || */// blank line
               (isNonblank(curChar) && !isNonblank(nextChar))       ||   // non blank to blank
               (isKeyword(curChar) && !isKeyword(nextChar))         ||   // keyword to non keyword
               (isNonblank(curChar) && !isKeyword(curChar) && isKeyword(nextChar))              // non keyword-non blank to keyword
               ){
                count--;
            }
        }
        
        if( 0 == count){
            break;
        }
        p++;
    }
    
    return p;
}

/**
 * Returns position of the end of count words backward.
 **/
- (NSUInteger)endOfWordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    // TODO: Implement!
    return index;
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
    
    for( ; p <= end; p++ ){
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

- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSString* string = [self xvim_string];
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
        NSCharacterSet *wsSet = [NSCharacterSet whitespaceCharacterSet];
        NSCharacterSet *wordSet = nil;
        
        if ( opt & BIGWORD) {
            NSCharacterSet *charSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
            wordSet = charSet;
        }
        else {
            NSMutableCharacterSet *charSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
            [charSet addCharactersInString:@"_"];
            wordSet = charSet;
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
        /* cursor on ')' or '}', move cursor just after it */
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
         * Put this position in curwin->w_cursor.
         */
        if ((end_pos = findmatchlimit(string, end_pos, other, NO)) == -1) {
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

@end
