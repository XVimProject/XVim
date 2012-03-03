//
//  Common.c
//  XVim
//
//  Created by Morris on 12-2-26.
//  Copyright (c) 2012年 http://warwithinme.com . All rights reserved.
//

#import "Common.h"

// ==========
// Testing
BOOL testDigit(unichar ch) { return ch >= '0' && ch <= '9'; }
BOOL testWhiteSpace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL testNewLine(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; }
BOOL testNonAscii(unichar ch) { return ch > 128; }
BOOL testAlpha(unichar ch) { 
    return (ch >= 'A' && ch <= 'Z') ||
    (ch >= 'a' && ch <= 'z') 
#ifdef UNDERSCORE_IS_WORD
    || ch == '_'
#endif
    ;
}
BOOL testDelimeter(unichar ch) {
    return (ch >= '!' && ch <= '/') ||
    (ch >= ':' && ch <= '@') ||
    (ch >= '[' && ch <= '`' && ch != '_') ||
    (ch >= '{' && ch <= '~');
}
BOOL testFuzzyWord(unichar ch) {
    return (!testWhiteSpace(ch)) && (!testNewLine(ch));
}


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
    NSInteger copyBegin = index;
    NSInteger size      = (index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index);
NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index)
{
    NSInteger copyBegin = (index + 1) >= ITERATE_STRING_BUFFER_SIZE ? index + 1 - ITERATE_STRING_BUFFER_SIZE : 0;
    NSInteger size      = index - copyBegin + 1;
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




// ==========
// Common vim implementation.
struct XVBuffer {
    NSString* string;
    NSInteger index;
};

static struct XVBuffer xv_buffer = {};

void xv_set_string(NSString* s) { xv_buffer.string = s; }
void xv_set_index (NSInteger i) { xv_buffer.index = i;  }


NSInteger xv_dollar()
{
    NSInteger strLen = [xv_buffer.string length];
    NSInteger index  = xv_buffer.index;
    
    NSStringHelper helper;
    initNSStringHelper(&helper, xv_buffer.string, strLen);
    
    while (index < strLen)
    {
        if (testNewLine(characterAtIndex(&helper, index)))
        {
            break;
        }
        ++index;
    }
    return index; 
}

NSInteger xv_dollar_inc()
{
    NSInteger index  = xv_buffer.index;
    NSInteger strLen = [xv_buffer.string length];
    
    NSStringHelper helper;
    initNSStringHelper(&helper, xv_buffer.string, strLen);
    
    while (index < strLen)
    {
        if (testNewLine(characterAtIndex(&helper, index)))
        {
            ++index;
            break;
        }
        ++index;
    }
    return index;
}

NSInteger xv_g_()
{
    NSInteger index  = xv_dollar();
    NSString* string = xv_buffer.string;
    while (index > 0)
    {
        --index;
        if (!testWhiteSpace([string characterAtIndex:index]))
            break;
    }
    return index;
}

NSInteger xv_caret()
{
    NSInteger index        = xv_buffer.index;
    NSInteger resultIndex  = index;
    NSInteger seekingIndex = index;
    NSString* string       = xv_buffer.string;
    
    while (seekingIndex > 0) {
        unichar ch = [string characterAtIndex:seekingIndex-1];
        if (testNewLine(ch)) {
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
            if (testNewLine(ch) || testWhiteSpace(ch) == NO) {
                break;
            }
            ++resultIndex;
        }
    }
    
    return resultIndex;
}

NSInteger xv_percent()
{
    NSString* string    = xv_buffer.string;
    NSInteger idxBefore = xv_buffer.index;
    
    // Find the first brace in this line that is after the caret.
    NSCharacterSet* set  = [NSCharacterSet characterSetWithCharactersInString:@"([{)]}"];
    NSRange    range     = NSMakeRange(idxBefore, xv_dollar() - idxBefore);
    NSInteger  idxNew    = [string rangeOfCharacterFromSet:set 
                                                   options:0 
                                                     range:range].location;
    if (idxNew != NSNotFound)
    {
        // Found brace, switch to the corresponding one.
        unichar correspondingCh = 0;
        unichar ch     = [string characterAtIndex:idxNew];
        int     dir    = 1;
        switch (ch) {
            case '(': correspondingCh = ')'; break;
            case '[': correspondingCh = ']'; break;
            case '{': correspondingCh = '}'; break;
            case ')': correspondingCh = '('; dir = -1; break;
            case ']': correspondingCh = '['; dir = -1; break;
            case '}': correspondingCh = '{'; dir = -1; break;
        }
        
        NSInteger maxIdx = [string length] - 1;
        int nOpen  = 0;
        int nClose = 0;
        
        NSStringHelper helper;
        NSStringHelper* h = &helper;
        dir == 1 ? initNSStringHelper(h, string, maxIdx+1) : initNSStringHelperBackward(h, string, maxIdx+1);
        
        while (idxNew <= maxIdx && idxNew > 0)
        {
            unichar c = characterAtIndex(h, idxNew);
            if (c == ch) {
                ++nOpen;
            } else if (c == correspondingCh) {
                ++nClose;
                if (nOpen == nClose)
                {
                    return idxNew;
                }
            }
            idxNew += dir;
        }
    }
    
    return idxBefore;
}

NSInteger xv_0()
{    
    NSInteger index = xv_buffer.index;
    while (index > 0)
    {
        if (testNewLine([xv_buffer.string characterAtIndex:index-1])) { break; }
        --index;
    }
    return index;
}

NSInteger xv_h(int repeatCount)
{
    NSInteger  index  = xv_buffer.index;
    NSString*  string = xv_buffer.string;
    
    for (int i = 0; i < repeatCount; ++i)
    {
        if (index == 0) { 
            return 0;
        } else if (index == 1) {
            return 0;
        }
        
        // When moveing left and right, we should never place the caret
        // before the CR, unless the line is a blank line.
        
        --index;
        if ([string characterAtIndex:index] == '\n') {
            if ([string characterAtIndex:index - 1] != '\n') {
                --index;
            }
        }
    }
    
    return index;
}

NSInteger xv_l(int repeatCount, BOOL stepForward)
{
    NSString* string   = xv_buffer.string;
    NSInteger index    = xv_buffer.index;
    NSInteger maxIndex = [string length] - 1;
    
    for (int i = 0; i < repeatCount; ++i) {
        if (index >= maxIndex) {
            return index;
        }
        
        ++index;
        if ([string characterAtIndex:index] == '\n' && stepForward) {
            ++index;
        }
    }
    return index;
}

typedef BOOL (*testAscii) (unichar);
testAscii testForChar(unichar ch);
testAscii testForChar(unichar ch)
{
    if (testDigit(ch)) return testDigit;
    if (testAlpha(ch)) return testAlpha;
    if (testWhiteSpace(ch)) return testWhiteSpace;
    if (testNewLine(ch)) return testNewLine;
    if (testNonAscii(ch)) return testNonAscii;
    return testDelimeter;
}

NSInteger xv_w(int repeatCount, BOOL bigWord)
{
    NSString* string = xv_buffer.string;
    NSInteger index  = xv_buffer.index;
    NSInteger maxIndex = [string length] - 1;
    
    if (index == maxIndex) { return maxIndex + 1; }
    
    for (int i = 0; i < repeatCount && index < maxIndex; ++i)
    {
        unichar ch = [string characterAtIndex:index];
        
        // If this the ch is a newLine(CR): e.g. ABC|(CR)
        // We move the caret forward and consider we are at the
        // beginning of the next word.
        
        BOOL blankLine = NO;
        if (testNewLine(ch)) {
            ++index;
            blankLine = YES;
        } else {
            testAscii test = bigWord ? testFuzzyWord : testForChar(ch);
            do {
                ++index;
            } while (index < maxIndex && test([string characterAtIndex:index]));
        }
        
        while (index < maxIndex)
        {
            ch = [string characterAtIndex:index];
            if (blankLine == NO && testNewLine(ch)) {
                blankLine = YES;
            } else if (testWhiteSpace(ch)) {
                blankLine = NO;
            } else {
                break;
            }
            ++index;
        }
    }
    
    if (index == maxIndex && 
        testNewLine([string characterAtIndex:index]) &&
        !testNewLine([string characterAtIndex:index - 1]))
    {
        ++index;
    }
    
    return index;
}

NSInteger xv_w_motion(int repeatCount, BOOL bigWord)
{
    NSString* string  = xv_buffer.string;
    NSInteger oldIdx  = xv_buffer.index;
    // Reduce index if we are at the beginning indentation of another line.
    NSInteger newIdx  = xv_w(repeatCount, bigWord);
    NSInteger testIdx = newIdx - 1;
    
    while (testIdx > oldIdx)
    {
        unichar ch = [string characterAtIndex:testIdx];
        if (testWhiteSpace(ch)) {
            --testIdx;
            continue;
        } else if (!testNewLine(ch))
        {
            // We can't reach the line before, the newIdx should not change.
            return newIdx;
        }
        break;
    }
    
    return oldIdx == testIdx ? newIdx : testIdx;
}

NSInteger xv_b(int repeatCount, BOOL bigWord)
{
    // 'b' If we are not at the beginning of a word, go to the beginning of it.
    // Otherwise go to the beginning of the word before it.
    NSInteger index  = xv_buffer.index;
    NSString* string = xv_buffer.string;
    NSInteger maxI   = [string length] - 1;
    if (index >= maxI) { index = maxI; }
    
    for (int i = 0; i < repeatCount && index > 0; ++i)
    {
        unichar ch = [string characterAtIndex:index];
        
        // There are three situations that the ch is a newLine(CR):
        // 1. (CR)|(CR) // We are between two CR.
        // 2. ABC|(CR)  // We are at the end of the line, because the 
        //                 user place the caret with mouse.
        // For s1, we move the caret backward once.
        if (testNewLine(ch) && testNewLine([string characterAtIndex:index - 1])) {
            --index;
            if (index == 0) { return 0; }
        }
        
        BOOL      blankLine = NO;
        testAscii test      = bigWord ? testFuzzyWord : testForChar(ch);
        BOOL      inWord    = test([string characterAtIndex:index - 1]);
        
        if (inWord == NO || testWhiteSpace(ch))
        {
            // We are at the beginning of a word, or in the
            // middle of whitespaces. Move to the end of the
            // word before. Blank line is consider a word.
            while (index > 0)
            {
                --index;
                ch = [string characterAtIndex:index];
                if (testWhiteSpace(ch)) {
                    blankLine = NO;
                } else if (testNewLine(ch)) {
                    if (blankLine == YES) {
                        ++index;
                        break;
                    }
                    blankLine = YES;
                } else {
                    break;
                }
            }
        }
        
        // Now ch is the character after the caret.
        if (index == 0) {
            return 0;
        } else if (testNewLine(ch) == NO)
        {
            test = bigWord ? testFuzzyWord : testForChar(ch);
            while (index > 0) {
                ch = [string characterAtIndex:index - 1];
                if (test(ch) == NO) {
                    break;
                }
                --index;
            }
        }
    }
    
    return index;
}

NSInteger xv_e(int repeatCount, BOOL bigWord)
{
    // 'e' If we are not at the end of a word, go to the end of it.
    // Otherwise go to the end of the word after it.
    
    // Test in MacVim, when dealing with 'e', 
    // the blank line is not consider a word.
    // So whitespace and newline are totally ingored.
    
    NSString* string   = xv_buffer.string;
    NSInteger index    = xv_buffer.index;
    NSInteger maxIndex = [string length] - 1;
    
    for (int i = 0; i < repeatCount && index < maxIndex; ++i)
    {
        unichar   ch      = [string characterAtIndex:index];
        testAscii test    = bigWord ? testFuzzyWord : testForChar(ch);
        BOOL      inWord  = test([string characterAtIndex:index + 1]);
        
        if (inWord == NO || testWhiteSpace(ch) || testNewLine(ch))
        {
            while (index < maxIndex)
            {
                ++index;
                ch = [string characterAtIndex:index];
                if (testWhiteSpace(ch) || testNewLine(ch)) {
                    continue;
                } else {
                    break;
                }
            }
        }
        
        // Now ch is the character after the caret.
        if (index < maxIndex)
        {
            test = bigWord ? testFuzzyWord : testForChar(ch);
            while (index < maxIndex) {
                ch = [string characterAtIndex:index + 1];
                if (test(ch) == NO) {
                    break;
                }
                ++index;
            }
        }
        
        if (index == maxIndex && testNewLine([string characterAtIndex:index])) {
            return maxIndex + 1;
        }
    }
    
    return index;
}

NSInteger xv_columnToIndex(NSUInteger column)
{
    NSInteger index  = xv_buffer.index;
    NSString* string = xv_buffer.string;
    NSInteger strLen = [string length];
    
    if (index >= strLen) { return index; }
    
    NSStringHelper helper;
    initNSStringHelperBackward(&helper, string, strLen);
    
    NSInteger lastLineEnd = index;
    for (; lastLineEnd >= 0; --lastLineEnd)
    {
        unichar ch = characterAtIndex(&helper, lastLineEnd);
        if (testNewLine(ch)) { break; }
    }
    
    // If we are at a blank line, return the current index.
    if (lastLineEnd == index &&
        (index == 0 || testNewLine(characterAtIndex(&helper, index - 1)) )) { return index; }
    
    NSInteger thisLineEnd = index + 1;
    for (; thisLineEnd < strLen; ++thisLineEnd) {
        unichar ch = characterAtIndex(&helper, thisLineEnd);
        if (testNewLine(ch)) { break; }
    }
    
    index = lastLineEnd + column;
    return index < thisLineEnd ? index : thisLineEnd;
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
            
            if (testNewLine(characterAtIndex(h, pos)))
            {
                // At prev line.
                do_quotes = -1;
            }
        } else {  // Forward search
            if (pos == maxIndex) { break; } // At end of file
            
            if (testNewLine(characterAtIndex(h, pos))) {
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
            while (ptr > 0 && !testNewLine([string characterAtIndex:ptr-1])) { --ptr; }
            NSInteger sta = ptr;
            
            while (ptr < maxIndex && 
                   !testNewLine(characterAtIndex(h, ptr)))
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
                    !testNewLine(characterAtIndex(h, ptr+1))) 
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
                        if (testNewLine(c2) || c2 != '\\') {
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
                            if (testNewLine(characterAtIndex(h, p1))) {
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
                        if (pos < maxIndex && !testNewLine(characterAtIndex(h, pos + 1)))
                        {
                            if (characterAtIndex(h, pos + 1) == '\\' &&
                                (pos < maxIndex - 2) &&
                                !testNewLine(characterAtIndex(h, pos + 2)) &&
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
                            if (testNewLine(c2) || c2 != '\\') {
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

NSRange xv_current_block(int count, BOOL inclusive, char what, char other)
{
    NSString* string = xv_buffer.string;
    NSInteger idx    = xv_buffer.index;
    
    if ([string characterAtIndex:idx] == what)
    {
        /* cursor on '(' or '{', move cursor just after it */
        ++idx;
        if (idx >= [string length]) {
            return NSMakeRange(NSNotFound, 0);
        }
    }
    
    int start_pos = (int)idx;
    int end_pos   = (int)idx;
    
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
            NSInteger oldIdx = xv_buffer.index;
            xv_buffer.index = end_pos;
            NSInteger idx = xv_caret();
            
            if (idx == end_pos)
            {
                // The '}' is only preceded by indent, skip that indent.
                end_pos = (int) xv_0() - 1;
            }
            xv_buffer.index = oldIdx;
        }
    } else {
        ++end_pos;
    }
    
    return NSMakeRange(start_pos, end_pos - start_pos);
}

NSRange xv_current_word(int repeatCount, BOOL inclusive, BOOL fuzzy)
{    
    NSString* string   = xv_buffer.string;
    NSInteger index    = xv_buffer.index;
    NSInteger maxIndex = [string length] - 1;
    
    if (index > maxIndex) { return NSMakeRange(NSNotFound, 0); }
    
    unichar    ch    = [string characterAtIndex:index];
    testAscii  test  = testWhiteSpace(ch) ? testWhiteSpace : (fuzzy ? testFuzzyWord : testForChar(ch));
    
    NSInteger begin = index;
    NSInteger end   = index;
    
    while (begin > 0)
    {
        if (test([string characterAtIndex:begin - 1]) == NO) { break; }
        --begin;
    }
    
    NSInteger oldIdx = xv_buffer.index;
    
    //
    // Word is like (  word  )
    if (testWhiteSpace(ch) == inclusive)
    {
        xv_buffer.index = index;
        
        // If inclusive and at whitespace, whitespace is included: ("  word"  )
        // If exclusive and not at whitespace, then: (  "word"  )
        // That means we should find the end of the word.
        end = xv_e(repeatCount, fuzzy) + 1;
        xv_buffer.index = oldIdx;
    } else {
        xv_buffer.index = end;
        
        // If inclusive and not at whitespace: (  "word  ")
        // If exclusive and at whitespace, then: ("  "word  )
        
        if (repeatCount > 1) {
            // Select more words.
            xv_buffer.index = xv_w(repeatCount - 1, fuzzy);
        }
        // If the end index is at beginning indent of next line,
        // Go back to prev line.
        end = xv_w_motion(1, fuzzy);
        
        xv_buffer.index = oldIdx;
        
        // If we don't have any trailing whitespace,
        // Extend begin to include whitespace.
        if (!testWhiteSpace([string characterAtIndex:end - 1]))
        {
            while (begin > 0 && testWhiteSpace([string characterAtIndex:begin - 1]))
            {
                --begin;
            }
        }
    }
    
    return NSMakeRange(begin, end - begin);
}

NSInteger find_next_quote(NSStringHelper* h, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape);
NSInteger find_next_quote(NSStringHelper* h, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape)
{
    while (start <= max)
    {
        unichar ch = characterAtIndex(h, start);
        if (ch == quote)     { return start; }
        if (!ignoreEscape && ch == '\\')
        {
            ++start;
            if (start > max) { return -1; }
            ch = characterAtIndex(h, start);
        }
        if (testNewLine(ch)) { return -1; }
        ++start;
    }
    
    return -1;
}

NSInteger find_prev_quote(NSStringHelper* h, NSInteger start, unichar quote, BOOL ignoreEscape);
NSInteger find_prev_quote(NSStringHelper* h, NSInteger start, unichar quote, BOOL ignoreEscape)
{
    while (start > 0)
    {
        --start;
        if (testNewLine(characterAtIndex(h, start))) { break; }
        
        int n = 1;
        if (!ignoreEscape)
        {
            while (start - n >= 0)
            {
                unichar ch = characterAtIndex(h, start - n);
                if (ch == '\\') {
                    ++n;
                } else if (testNewLine(ch))
                {
                    --n;
                    break;
                } else {
                    break;
                }
            }
        }
        
        if (n & 1) {
            // Even escape.
            if (characterAtIndex(h, start) == quote) { return start; }
        } else {
            start -= (n - 1);
        }
    }
    
    return -1;
}

NSRange xv_current_quote(int repeatCount, BOOL inclusive, char what)
{
    // Rules:
    // 1. If the quote is escaped, ignore it, unless it's the first quote in the line.
    // 2. If the char under the caret is a quote, mark it as openning if there are even
    //    quotes before. Otherwise, mark it as closing.
    // 3. Find out the closest quotes near the caret.
    // 4. If repeatCount is greater than 1, it will always include the quote,
    //    regardless of inclusive.
    // 5. a" will include the trailing space, if no trailing space, extend to include any
    //    preceeding space.
    
    NSString* string = xv_buffer.string;
    NSInteger idx    = xv_buffer.index;
    NSInteger maxIdx = [string length] - 1;
    NSInteger start  = 0;
    NSInteger end    = 0;
    
    NSStringHelper helper;
    NSStringHelper* h = &helper;
    
    NSInteger oldIdx = xv_buffer.index;
    
    if ([string characterAtIndex:idx] == what)
    {
        initNSStringHelper(h, string, maxIdx + 1);
        // Find start quote.
        xv_buffer.index = idx;
        start = xv_0();
        xv_buffer.index = oldIdx;
        
        end   = start;
        while (YES)
        {
            start = find_next_quote(h, start,   maxIdx, what, YES);
            if (start == -1) { return NSMakeRange(NSNotFound, 0); }
            end   = find_next_quote(h, start+1, maxIdx, what, YES);
            if (end   == -1) { return NSMakeRange(NSNotFound, 0); }
            if (start <= idx && idx <= end) { break; } // Found.
            start = end + 1;
        }
    } else {
        initNSStringHelperBackward(h, string, maxIdx + 1);
        start = find_prev_quote(h, idx, what, NO); 
        
        initNSStringHelper(h, string, maxIdx + 1);
        if (start == -1) {
            // No quote before. Find quote afterward.
            start = find_next_quote(h, idx, maxIdx, what, YES);
            if (start == -1) { return NSMakeRange(NSNotFound, 0); }
        }
        end   = find_next_quote(h, idx + 1, maxIdx, what, YES);
        if (end == -1) { return NSMakeRange(NSNotFound, 0); }
    }
    
    if (inclusive)
    {
        xv_buffer.index = end;
        end = xv_w(1, NO);
        xv_buffer.index = oldIdx;
        
        if (end > maxIdx || !testWhiteSpace(characterAtIndex(h, end - 1)))
        {
            // Include preceeding whitespace.
            while (start > 0 && testWhiteSpace([string characterAtIndex:start - 1]))
                --start;
        }
    } else {
        if (repeatCount > 1) {
            ++end;
        } else {
            ++start;
        }
    }
    
    return NSMakeRange(start, end - start);
}
NSRange xv_current_tagblock(int repeatCount, BOOL inclusive)
{
    // TODO: Implement tag block text object.
    return NSMakeRange(NSNotFound, 0);
}

NSInteger xv_findChar(int repeatCount, char command, unichar what, BOOL inclusive)
{
    int increment = command <= 'Z' ? -1 : 1; // Capital means backward.
    
    NSString* string = xv_buffer.string;
    NSInteger maxIdx = [string length] - 1;
    NSInteger idx    = xv_buffer.index;
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
        } else if (testNewLine(ch))
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