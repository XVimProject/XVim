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
#import "XVimUndo.h"
#import "XVimBuffer.h"

@implementation NSTextStorage (VimOperation)

#pragma mark Definitions

- (BOOL) isEOF:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return self.length == index;
}

- (BOOL) isEOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isNewline:index] || [self isEOF:index];
}

- (BOOL) isNewline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == self.length ){
        return NO; // EOF is not a newline
    }
    return isNewline([self.xvim_buffer.string characterAtIndex:index]);
}

- (BOOL) isWhitespace:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == self.length ){
        return NO; // EOF is not whitespace
    }
    return isWhitespace([self.xvim_buffer.string characterAtIndex:index]);
}

- (BOOL) isNonblank:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEOF:index]){
        return YES;
    }
    return isNonblank([self.xvim_buffer.string characterAtIndex:index]);
}


/**
 * Determine if the position specified with "index" is blankline.
 * Blankline is one of followings
 *   - Newline after Newline. Ex. The second '\n' in "abc\n\nabc" is a blankline. First one is not.
 *   - Newline at begining of the document.
 *   - EOF after Newline. Ex. The index 4 of "abc\n" is blankline. Note that index 4 is exceed the string length. But the cursor can be there.
 *   - EOF of 0 sized document.
 **/
- (BOOL)isBlankline:(NSUInteger)index
{
    XVimBuffer *buffer = self.xvim_buffer;
    return [buffer indexRangeForLineAtIndex:index newLineLength:NULL].length == 0;
}

- (BOOL) isValidCursorPosition:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isBlankline:index] || ![self isEOL:index];
}

#pragma mark Searching Positions

/**
 * This does all the work need to do with vim '%' motion.
 * Find match pair character in the line and find the corresponding pair.
 * Returns NSNotFound if not found.
 **/
- (NSUInteger)positionOfMatchedPair:(NSUInteger)pos
{
    XVimBuffer *buffer = self.xvim_buffer;
    NSString *s = buffer.string;

    // find matching bracketing character and go to it
    // as long as the nesting level matches up

    xvim_string_buffer_t sb;
    xvim_sb_init(&sb, s, pos, pos, [buffer endOfLine:pos]);

#define pairs "{}[]()"
    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@pairs];

    unichar start_with_c, look_for_c;
    BOOL search_forward;
    NSInteger nest_level = 0;

    if (xvim_sb_find_forward(&sb, charset)) {
        start_with_c = xvim_sb_peek(&sb);
        xvim_sb_init(&sb, s, xvim_sb_index(&sb), 0, s.length);

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

- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt info:(XVimMotionInfo*)info{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(nil != info, @"Specify info");
    
    NSUInteger pos = index;
    info->isFirstWordInLine = NO;
    info->lastEndOfLine = NSNotFound;
    info->lastEndOfWord = NSNotFound;
    
    if( [self isEOF:index] ){
        return index;
    }
    
    NSString* str = self.xvim_buffer.string;
    unichar lastChar= [str characterAtIndex:index];
    BOOL wordInLineFound = NO;
    for(NSUInteger i = index+1 ; i <= [self length]; i++ ){
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
                if(isKeyword(lastChar) != isKeyword(curChar) && opt != MOPT_BIGWORD){
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
        if( isNewline(curChar) && opt == MOPT_NOWRAP ){
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

- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 1 >= index )
        return 0;
    NSUInteger indexBoundary = NSNotFound;
    NSUInteger pos = index-1;
    unichar lastChar = [self.xvim_buffer.string characterAtIndex:pos];
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
        unichar curChar = [self.xvim_buffer.string characterAtIndex:i];
        
        // this branch handles the case that we found a placeholder.
        // must update the pointer into the string and update the current character found to be at the current index.
        if(indexBoundary != NSNotFound){
            count--;
            i = indexBoundary;
            if (count == 0) {
                pos = i;
                break;
            }
            curChar = [self.xvim_buffer.string characterAtIndex:i];
        }
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !MOPT_BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !MOPT_BIGWORD)
        //    - newline and newline(blankline) 
        else if(
           ((isWhitespace(curChar) || isNewline(curChar)) && isNonblank(lastChar))   ||
           ( opt != MOPT_BIGWORD && isKeyword(curChar) && !isKeyword(lastChar) && !isWhitespace(lastChar) && !isNewline(lastChar))   ||
           ( opt != MOPT_BIGWORD && !isKeyword(curChar) && !isWhitespace(curChar) && !isNewline(lastChar) && isKeyword(lastChar) )  ||
           ( isNewline(curChar) && [self isBlankline:i+1] )
           ){
            count--; 
        }
        
        lastChar = curChar;
        if( 0 == i ){
            pos = 0;
            break;
        }
        if( 0 == count || (isNewline(curChar) && opt == MOPT_NOWRAP) ){
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
- (NSUInteger)endOfWordsForward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert( 0 != count , @"count must be greater than 0");

    NSUInteger length = self.length;

    if (index >= length - 1) {
        return index;
    }

    NSUInteger p;
    if( opt & MOPT_CHANGE_WORD ){
        p = index;
    } else {
        p = index+1; // We start searching end of word from next character
    }
    NSString *string = self.xvim_buffer.string;
    while (p < length - 1) {
        unichar curChar = [string characterAtIndex:p];
        unichar nextChar = [string characterAtIndex:p+1];
        // Find the border of words.
        // Vim defines "Blank Line as a word" but 'e' does not stop on blank line.
        // Thats why we are not seeing blank line as a border of a word here (commented out the condition currently)
        // We may add some option to specify if we count a blank line as a word here.
        if( opt & MOPT_BIGWORD ){
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
- (NSUInteger)endOfWordsBackward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
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
- (NSUInteger)sentencesForward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{ //(
    NSUInteger pos = index+1;
    NSUInteger sentence_head = NSNotFound;
    NSString* s = self.xvim_buffer.string;
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

- (NSUInteger)sentencesBackward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{ //(
    if( 0 == index ){
        return NSNotFound;
    }
    
    NSUInteger pos = index-1; 
    NSUInteger lastSearchBase = index;
    NSUInteger sentence_head = NSNotFound;
    NSString* s = self.xvim_buffer.string;
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

- (NSUInteger)moveFromIndex:(NSUInteger)index paragraphs:(NSInteger)count option:(XVimMotionOptions)opt
{
    XVimBuffer *buffer = self.xvim_buffer;
    NSUInteger  length = buffer.length;
    NSUInteger  nlLen;
    BOOL skippingBlankLines = YES, forward;
    NSRange range;

    if (count > 0) {
        forward = YES;
    } else {
        forward = NO;
        count   = -count;
    }

    while (forward ? index < length : index-- > 0) {
        BOOL isParaSep = NO;

        range = [buffer indexRangeForLineAtIndex:index newLineLength:&nlLen];
        if (!forward) {
            index = range.location;
        }
        if (range.length == 0) {
            isParaSep = YES;
        } else if (opt & MOPT_PARA_BOUND_BLANKLINE) {
            if ([buffer firstNonblankInLineAtIndex:index allowEOL:NO] == NSNotFound) {
                isParaSep = YES;
            }
        }
        if (skippingBlankLines) {
            skippingBlankLines = isParaSep;
        } else if (isParaSep) {
            if (--count == 0) {
                return index;
            }
            skippingBlankLines = YES;
        }
        if (forward) {
            index = NSMaxRange(range) + nlLen;
        }
    }

    return forward ? length : 0;
}

- (NSUInteger)sectionsForward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{ //(
    return 0;
}

- (NSUInteger)sectionsBackward:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{ //(
    return 0;
}

- (NSUInteger)nextCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEOF:index] ){
        return NSNotFound;
    }
    NSUInteger p = index+1;
    NSUInteger end = [self.xvim_buffer endOfLine:p];
    if( NSNotFound == end ){
        return NSNotFound;
    }
    
    for( ; p <= end; p++ ){
        if( [self.xvim_buffer.string characterAtIndex:p] == character ){
            count--;
            if( 0 == count ){
                return p;
            }
        }
    }
    return NSNotFound;
}

- (NSUInteger)prevCharacterInLine:(NSUInteger)index count:(NSUInteger)count character:(unichar)character option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 0 == index ){
        return NSNotFound;
    }
    NSUInteger p = index-1;
    NSUInteger head = [self.xvim_buffer firstOfLine:p];
    if( NSNotFound == head ){
        return NSNotFound;
    }
    
    for( ; p >= head ; p-- ){
        if( [self.xvim_buffer.string characterAtIndex:p] == character ){
            count--;
            if( 0 == count ){
                return p;
            }
        }
    }
    return NSNotFound;
}

- (NSRange)searchRegexForward:(NSString*)pattern from:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(pattern != nil, @"pattern must not be nil");
    
    NSRange ret = NSMakeRange(NSNotFound,0);
    
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if( opt & MOPT_SEARCH_CASEINSENSITIVE ){
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
    
    // Then look for the position in range of [BOF,index] if MOPT_SEARCH_WRAP
    if( 0 != count && opt & MOPT_SEARCH_WRAP ){
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

- (NSRange)searchRegexBackward:(NSString*)pattern from:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(pattern != nil, @"pattern must not be nil");
    
    NSRange ret = NSMakeRange(NSNotFound,0);
    
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if( opt & MOPT_SEARCH_CASEINSENSITIVE ){
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
    
    // Then look for the position in range of [index,EOF] if MOPT_SEARCH_WRAP
    if( 0 != count && opt & MOPT_SEARCH_WRAP ){
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
    NSString*  string;
    NSUInteger strLen;
    NSInteger  index;
    
} NSStringHelper;
static void initNSStringHelper(NSStringHelper*, NSString* string, NSUInteger strLen);
static void initNSStringHelperBackward(NSStringHelper*, NSString* string, NSUInteger strLen);
static unichar characterAtIndex(NSStringHelper*, NSInteger index);

- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(XVimMotionOptions)opt{
    NSString* string = self.xvim_buffer.string;
    NSInteger maxIndex = self.length - 1;
    if (index > maxIndex) { return NSMakeRange(NSNotFound, 0); }
    
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
        
        if ( opt & MOPT_BIGWORD) {
            NSCharacterSet *charSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
            wordSet = charSet;
        }
        else {
            NSMutableCharacterSet *charSet = [[[NSCharacterSet alphanumericCharacterSet] mutableCopy] autorelease];
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
        if ( !(opt & MOPT_TEXTOBJECT_INNER)) {
            NSInteger newEnd = end;
            if (end < maxIndex) {
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
static void initNSStringHelper(NSStringHelper* h, NSString* string, NSUInteger strLen)
{
    h->string = string;
    h->strLen = strLen;
    h->index  = -ITERATE_STRING_BUFFER_SIZE;
}

static void initNSStringHelperBackward(NSStringHelper* h, NSString* string, NSUInteger strLen)
{
    h->string = string;
    h->strLen = strLen;
    h->index  = strLen;
}

static NSInteger fetchSubStringFrom(NSStringHelper* h, NSInteger index)
{
    NSInteger copyBegin = index;
    NSInteger size      = (index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

static NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index)
{
    NSInteger copyBegin = (index + 1) >= ITERATE_STRING_BUFFER_SIZE ? index + 1 - ITERATE_STRING_BUFFER_SIZE : 0;
    NSInteger size      = (index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

static unichar characterAtIndex(NSStringHelper* h, NSInteger index)
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

static NSInteger xv_caret(NSString *string, NSInteger index)
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

static NSInteger xv_0(NSString *string, NSInteger index)
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
static int findmatchlimit(NSString* string, NSInteger pos, unichar initc, BOOL cpo_match)
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
        if (idx >= [string length]) {
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
		NSMutableCharacterSet *charSet = [[[wordSet invertedSet] mutableCopy] autorelease];
		[charSet removeCharactersInString:@" \t"];
		searchSet = charSet;
	}
	
	return searchSet;
}

static NSInteger find_next_quote(NSString* string, NSInteger start, NSInteger max, unichar quote, BOOL ignoreEscape)
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

static NSInteger find_prev_quote(NSString* string, NSInteger start, unichar quote, BOOL ignoreEscape)
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

#pragma GCC diagnostic pop

@end
