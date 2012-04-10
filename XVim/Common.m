
//
//  Common.c
//  XVim
//
//  Created by Morris on 12-2-26.
//  Copyright (c) 2012年 http://warwithinme.com . All rights reserved.
//

#import "Common.h"
#import <Foundation/NSCharacterSet.h>

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

NSInteger xv_dollar(NSString *string, NSInteger index)
{
    NSInteger strLen = [string length];
    
    NSStringHelper helper;
    initNSStringHelper(&helper, string, strLen);
    
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

NSInteger xv_dollar_inc(NSString *string, NSInteger index)
{
    NSInteger strLen = [string length];
    
    NSStringHelper helper;
    initNSStringHelper(&helper, string, strLen);
    
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

NSInteger xv_g_(NSString *string, NSInteger index)
{
    index  = xv_dollar(string, index);
    while (index > 0)
    {
        --index;
        if (!testWhiteSpace([string characterAtIndex:index]))
            break;
    }
    return index;
}

NSInteger xv_caret(NSString *string, NSInteger index)
{
    NSInteger resultIndex  = index;
    NSInteger seekingIndex = index;
    
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

NSInteger xv_percent(NSString *string, NSInteger index)
{
    NSInteger idxBefore = index;
    
    // Find the first brace in this line that is after the caret.
    NSCharacterSet* set  = [NSCharacterSet characterSetWithCharactersInString:@"([{)]}"];
    NSRange    range     = NSMakeRange(idxBefore, xv_dollar(string, index) - idxBefore);
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

NSInteger xv_0(NSString *string, NSInteger index)
{    
    while (index > 0)
    {
        if (testNewLine([string characterAtIndex:index-1])) { break; }
        --index;
    }
    return index;
}

NSInteger xv_h(NSString *string, NSInteger index, int repeatCount)
{
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

NSInteger xv_l(NSString *string, NSInteger index, int repeatCount, BOOL stepForward)
{
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

NSInteger xv_w(NSString *string, NSInteger index, int repeatCount, BOOL bigWord)
{
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

NSInteger xv_w_motion(NSString *string, NSInteger index, int repeatCount, BOOL bigWord)
{
    NSInteger oldIdx  = index;
    // Reduce index if we are at the beginning indentation of another line.
    NSInteger newIdx  = xv_w(string, index, repeatCount, bigWord);
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

NSInteger xv_b(NSString *string, NSInteger index, int repeatCount, BOOL bigWord)
{
    // 'b' If we are not at the beginning of a word, go to the beginning of it.
    // Otherwise go to the beginning of the word before it.
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

NSInteger xv_e(NSString *string, NSInteger index, int repeatCount, BOOL bigWord)
{
    // 'e' If we are not at the end of a word, go to the end of it.
    // Otherwise go to the end of the word after it.
    
    // Test in MacVim, when dealing with 'e', 
    // the blank line is not consider a word.
    // So whitespace and newline are totally ingored.
    
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

NSInteger xv_columnToIndex(NSString *string, NSInteger index, NSUInteger column)
{
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

NSRange xv_current_block(NSString *string, NSUInteger index, NSUInteger count, BOOL inclusive, char what, char other)
{
    NSInteger idx    = index;
    
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
            NSInteger oldIdx = index;
            index = end_pos;
            NSInteger idx = xv_caret(string, index);
            
            if (idx == end_pos)
            {
                // The '}' is only preceded by indent, skip that indent.
                end_pos = (int) xv_0(string, index) - 1;
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
	while (end < [string length])
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

NSRange xv_current_word(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive, BOOL bigword)
{    
    NSInteger maxIndex = [string length] - 1;
	if (index > maxIndex) { return NSMakeRange(NSNotFound, 0); }
	
	NSInteger rangeStart = index;
	NSInteger rangeEnd = index;
	
	// repeatCount loop starts here
	while (repeatCount--)
	{
		// Skip past newline
		while (index < maxIndex && testNewLine([string characterAtIndex:index]))
		{
			++index;
		}
		
		if (index > maxIndex) { break; }
		
		NSCharacterSet *wsSet = [NSCharacterSet whitespaceCharacterSet];
		NSCharacterSet *wordSet = nil;
		
		if (bigword)
		{
			NSCharacterSet *charSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
			wordSet = charSet;
		}
		else
		{
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
		if (inclusive)
		{
			NSInteger newEnd = end;
			
			if (end < maxIndex)
			{
				if (initialCharIsWs)
				{
					unichar c = [string characterAtIndex:end];
					searchSet = get_search_set(c, wsSet, wordSet);
					newEnd = seek_forwards(string, end, searchSet);
				}
				else
				{
					newEnd = seek_forwards(string, end, wsSet);
				}
			}
			
			// If we couldn't eat anything from the end, try to eat start
			NSInteger newBegin = begin;
			if (newEnd == end)
			{
				if (!initialCharIsWs)
				{
					newBegin = seek_backwards(string, begin, wsSet);
					
					// Never remove a line's leading whitespace
					if (newBegin == 0 || testNewLine([string characterAtIndex:newBegin - 1]))
					{
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

NSInteger find_next_quote(NSString* string, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape);
NSInteger find_next_quote(NSString* string, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape)
{
	BOOL ignoreNextChar = NO;
	
    while (start < max)
    {
        unichar ch = [string characterAtIndex:start];
		if (testNewLine(ch)) { break; }
		
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
        if (testNewLine(ch)) { break; }
		
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
	
	if (begin == -1)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	NSInteger end = find_next_quote(string, begin + 1, [string length], what, NO);
	if (end == -1)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	if (inclusive)
	{
		end = end + 1;
		
		NSInteger newBegin = begin;
		NSInteger newEnd = end;
		
		if (index >= begin)
		{
			newEnd = seek_forwards(string, end, [NSCharacterSet whitespaceCharacterSet]);
		}
		
		if (index < begin || newEnd == end)
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
										  
										  
NSRange xv_current_tagblock(NSString *string, NSUInteger index, NSUInteger repeatCount, BOOL inclusive)
{
    // TODO: Implement tag block text object.
    return NSMakeRange(NSNotFound, 0);
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