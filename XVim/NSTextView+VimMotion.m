//
//  NSTextView+VimMotion.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All 
//

#import "NSTextView+VimMotion.h"
#import "Logger.h"

//
// This category deals Vim's motion in NSTextView.
// Each method of motion should return the destination position of the motion.
// They shouldn't change the position of current insertion point(selected range)
// They also have some support methods for Vim motions such as obtaining next newline break.
//

////////////////////////
// Terms using here   //
////////////////////////

     // Let me know if terms are confusing espcially if its different from Vim's terms.
/**
 * "Character"
 * Characgter is a one unichar value. (any value including tabs,spaces)
 *
 * "EOF"
 * EOF is the position at the end of document(text).
 * If we have NSTextView with string "abc" the EOF is just after the 'c'.
 * The index of EOF is 3 in this case.
 * What we have to think about is a cursor can be on the EOF(when the previous letter is newline) but characterAtIndex: with index of EOF cause a exception.
 * We have to be careful about it when calculate and find the position of some motions.
 *
 * "Newline"
 * Newline is defined as "unichar determined by isNewLine function"
 **/

static NSArray* XVimWordDelimiterCharacterSets = nil;

@implementation NSTextView (VimMotion)
/////////////////////
// Character set   //
/////////////////////

#define CHARSET_ID_WHITESPACE 0
#define CHARSET_ID_KEYWORD 1 // This is named after 'iskeyword' in Vim

+ (NSArray*) wordDelimiterCharacterSets{
    if (XVimWordDelimiterCharacterSets == nil) {
        XVimWordDelimiterCharacterSets = [NSArray arrayWithObjects: [NSCharacterSet  whitespaceAndNewlineCharacterSet], // note: whitespace set is special and must be first in array
                                          [NSCharacterSet  characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_"],
                                          nil
                                          ];
    }    
    return XVimWordDelimiterCharacterSets;
}

- (NSInteger)wordCharSetIdForChar:(unichar)c {
    NSInteger cs_id=0;
    for (NSCharacterSet* cs in [NSTextView wordDelimiterCharacterSets]) {
        if ([cs characterIsMember:c])
            break;
        cs_id++;
    }
    return cs_id;
};



/////////////////////////
// support functions   //
/////////////////////////
#define UNDERSCORE_IS_WORD
BOOL isDigit(unichar ch) { return ch >= '0' && ch <= '9'; }
BOOL isWhiteSpace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL isNewLine(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; } // What's the defference with [NSCharacterSet newlineCharacterSet] characterIsMember:] ?
BOOL isNonAscii(unichar ch) { return ch > 128; } // is this not ch >= 128 ? (JugglerShu)
BOOL isAlpha(unichar ch) { 
    return (ch >= 'A' && ch <= 'Z') ||
    (ch >= 'a' && ch <= 'z') 
#ifdef UNDERSCORE_IS_WORD
    || ch == '_'
#endif
    ;
}
BOOL isDelimeter(unichar ch) {
    return (ch >= '!' && ch <= '/') ||
    (ch >= ':' && ch <= '@') ||
    (ch >= '[' && ch <= '`' && ch != '_') ||
    (ch >= '{' && ch <= '~');
}
BOOL isFuzzyWord(unichar ch) {
    return (!isWhiteSpace(ch)) && (!isNewLine(ch));
}
BOOL isNonBlank(unichar ch) {
    return (!isWhiteSpace(ch)) && (!isNewLine(ch));
}
BOOL isKeyword(unichar ch){ // same as Vim's 'iskeyword' except that Vim's one is only defined fo 1 byte char
    return isDigit(ch) || isAlpha(ch)  || ch >= 192;
}


/////////////////////////
// support methods     //
/////////////////////////

// Most of the support methods take index as current interest position and index can be at EOF

// The following macros asserts the range of index.
// WITH_EOF permits the index at EOF position.
// WITHOUT_EOF doesn't permit the index at EOF position.
#define ASSERT_VALID_RANGE_WITH_EOF(x) NSAssert( x <= [[self string] length], @"index can not exceed the length of string" )
#define ASSERT_VALID_RANGE_WITHOUT_EOF(x) NSAssert( x < [[self string] length], @"index can not exceed the length of string - 1" )

// Some methods assume that "index" is at valid cursor position in Normal mode.
// See isValidCursorPosition's description the condition of the valid cursor position.
#define ASSERT_VALID_CURSOR_POS(x) NSAssert( [self isValidCursorPosition:x], @"index can not be invalid cursor position" )


/**
 * Determine if the position specified with "index" is EOF.
 **/
- (BOOL) isEOF:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [[self string] length] == index;
}

/**
 * Determine if the posiion is last character of the document
 **/
- (BOOL) isLastCharacter:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [[self string] length]-1 == index;
}

/**
 * Determine if the position specified with "index" is EOL.
 **/
- (BOOL) isEOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isEOF:index] == NO && [self isNewLine:index] == NO && [self isNewLine:index+1];
}

/**
 * Determine if the position specified with "index" is newline.
 **/
- (BOOL) isNewLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self string] length] ){
        return NO; // EOF is not a newline
    }
    return isNewLine([[self string] characterAtIndex:index]);
}

/**
 * Determine if the position specified with "index" is newline.
 **/
- (BOOL) isWhiteSpace:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self string] length] ){
        return NO; // EOF is not whitespace
    }
    
    return isWhiteSpace([[self string] characterAtIndex:index]);
}

/**
 * Determine if the position specified with "index" is blankline.
 * Blankline is one of them
 *   - Newline after Newline. Ex. Second '\n' in "abc\n\nabc" is a blankline. First one is not.  
 *   - Newline at begining of the document.
 *   - EOF after Newline. Ex. The index 4 of "abc\n" is blankline. Pay attension that index 4 is exceed the string length. But the cursor can be there.
 *   - EOF of 0 sized document.
 **/
- (BOOL) isBlankLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self string] length] || isNewLine([[self string] characterAtIndex:index])){
        if( 0 == index || isNewLine([[self string] characterAtIndex:index-1]) ){
            return YES;
        }
    }
    return NO;
}

/**
 * Determine if the position specified with "index" is valid cursor position in normal mode.
 * Valid position is followings
 *   - Non newline characters.
 *   - Blankline( including EOF after newline )
 **/
- (BOOL) isValidCursorPosition:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isBlankLine:index] ){
        return YES;
    }
    // "index" in not a blankline.
    // Then the EOF is not a valid cursor position.
    if( index == [[self string] length] ){
        return NO;
    }
    
    // index is never the position of EOF. We can call isNewLine with index.
    if( ![self isNewLine:index]){
        return YES;
    }
    
    return NO;
}

/**
 * Returns position of the first newline when searching backwards from "index"
 * Searching starts from position "index"-1. The position index is not included to search newline.
 * Returns NSNotFound if no newline found.
 **/
- (NSUInteger)prevNewLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 0 == index ){ //Nothing to search
        return NSNotFound;
    }
    for(NSUInteger i = index-1; ; i-- ){
        if( [self isNewLine:i] ){
            return i;
        }
        if( 0 == i ){
            break;
        }
    }
    return NSNotFound;
}

/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 **/
- (void)adjustCursorPosition{
    // If the current cursor position is not valid for normal mode move it.
    if( ![self isValidCursorPosition:[self selectedRange].location] ){
        // Here current cursor position is never at 0. We can substract 1.
        [self setSelectedRange:NSMakeRange([self selectedRange].location-1,0)];
    }
    return;
}

/**
 * Returns position of the head of line of the current line specified by index.
 * Head of line is one of them which is found first when searching backwords from "index".
 *    - Character just after newline
 *    - Character at the head of document
 * If the size of document is 0 it does not have any head of line.
 * Blankline does NOT have headOfLine.
 * Searching starts from position "index". So the "index" could be a head of line.
 **/
- (NSUInteger)headOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [[self string] length] == 0 ){
        return NSNotFound;
    }
    if( [self isBlankLine:index] ){
        return NSNotFound;
    }
    NSUInteger prevNewline = [self prevNewLine:index];
    if( NSNotFound == prevNewline ){
        return 0; // head of line is character at head of document since its not empty document.
    }
    
    return prevNewline+1; // Then this is the head of line
}

/**
 * Returns position of the first newline when searching forwards from "index"
 * Searching starts from position "index"+1. The position index is not included to search newline.
 * Returns NSNotFound if no newline is found.
 **/
- (NSUInteger)nextNewLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger length = [[self string] length];
    if( length == 0 ){
        return NSNotFound; // Nothing to search
    }
    
    if( index >= length - 1 ){
        return NSNotFound;
    }
    
    for( NSUInteger i = index+1; i < length ; i++ ){
        if( [self isNewLine:i] ){
            return i;
        }
    }
    return NSNotFound;
}


/**
 * Returns position of the tail of current line. 
 * Tail of line is one of followings
 *    - Newline character at the end of a line.
 *    - EOF of the last line of the document.
 * Blankline also has tail of line.
 **/
- (NSUInteger)tailOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    for( NSUInteger i = index; i < [[self string] length]; i++ ){
        if( [self isNewLine:i] ){
            return i;
        }
    }
    return [[self string] length]; //EOF
}

/**
 * Returns position of the end of line when the cursor is at "index"
 * End of line is one of following which is found first when searching forwords from "index".
 *    - Character just before newline if its not newlin
 *    - Character just before EOF if its not newline 
 * Blankline does not have end of line.
 * Searching starts from position "index". So the "index" could be an end of line.
 **/
- (NSUInteger)endOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    ASSERT_VALID_CURSOR_POS(index);
    if( [self isBlankLine:index] ){
        return NSNotFound;
    }
    NSUInteger nextNewLine = [self nextNewLine:index];
    if(NSNotFound == nextNewLine){
        return [[self string] length]-1;//just before EOF
    }
    return nextNewLine-1;
}

// Obsolete
- (NSUInteger)headOfLine{
    NSAssert(NO, @"Obsolete");//
    return [self headOfLine:[self selectedRange].location];
}

// Obsolete
- (NSUInteger)prevNewline{
    NSAssert(NO, @"Obsolete");//
    return [self prevNewLine:[self selectedRange].location];
}

// Obsolete
- (NSUInteger)endOfLine{
    NSAssert(NO, @"Obsolete");//
    return [self endOfLine:[self selectedRange].location];
}

// Obsolete
- (NSUInteger)nextNewline{
    NSAssert(NO, @"Obsolete");//
    return [self nextNewLine:[self selectedRange].location];
}

/**
 * Returns column number of the position "index"
 **/
- (NSUInteger)columnNumber:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger head = [self headOfLine:index];
    if( NSNotFound == head ){
        return 0; // This is balnkline
    }
    return index-head;
}

- (NSUInteger)nextNonBlankInALine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    // move to 1st non whitespace char, now that we are on the destination line
    while (index < [[self string] length]) {
        if( [self isNewLine:index] ){
            return NSNotFound; // Characters left in a line is whitespaces
        }
        if ( !isWhiteSpace([[self string] characterAtIndex:index])){
            break;
        }
        index++;
    }
    
    if( [self isEOF:index]){
        return NSNotFound;
    }
    return index;
}


/////////////
// Motions //
/////////////
- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_CURSOR_POS(index);
    if( 0 == index){
        return 0;
    }
    
    NSString* string = [self string];
    NSUInteger pos = index;
    for (NSUInteger i = 0; i < count && pos != 0 ; i++)
    {
        //Try move to prev position and check if its valid position.
        NSUInteger prev = pos-1; //This is the position where we are trying to move to.
        // If the position is new line and its not wrapable we stop moving
        if( opt == LEFT_RIGHT_NOWRAP && isNewLine([[self string] characterAtIndex:prev]) ){
            break; // not update the position
        }
        
        // If its wrapable, skip newline except its blankline
        if (isNewLine([string characterAtIndex:prev])) {
            if(![self isBlankLine:prev]) {
                // skip the newline letter at the end of line
                prev--;
            }
        }
        
        // Now the position can be move to the prev
        pos = prev;
    }   
    return pos;
}

- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    if( index == [[self string] length] )
        return [[self string] length];
    
    NSString* string = [self string];
    NSUInteger pos = index;
    // If the currenct cursor position is on a newline (blank line) and not wrappable never move the cursor
    if( opt == LEFT_RIGHT_NOWRAP && [self isBlankLine:pos]){
        return pos;
    }
    
    for (NSUInteger i = 0; i < count && pos < [string length]; i++) 
    {
        NSUInteger next = pos + 1;
        // If the next position is the end of docuement and current position is not a newline
        // Never move a cursor to the end of document.
        if( next == [string length] && !isNewLine([string characterAtIndex:pos]) ){
            break;
        }
        
        if( opt == LEFT_RIGHT_NOWRAP && isNewLine([[self string] characterAtIndex:next]) ){
            break;
        }
        
        // If the next position is newline and not a blankline skip it
        if (isNewLine([string characterAtIndex:next])) {
            if(![self isBlankLine:next]) {
                // skip the newline letter at the end of line
                next++;
            }
        }
        pos = next;
    }   
    return pos;
}

// Obsolete
- (NSUInteger)prev:(NSNumber*)count{ //h
    NSAssert(NO, @"Obsolete");//
    return [self prev:[self selectedRange].location count:[count unsignedIntValue] option:LEFT_RIGHT_NOWRAP];
}
// Obsolete
- (NSUInteger)next:(NSNumber*)count{ //l
    NSAssert(NO, @"Obsolete");//
    return [self next:[self selectedRange].location count:[count unsignedIntValue] option:LEFT_RIGHT_NOWRAP];
}

/**
 * Returns the position when a cursor goes to upper line.
 * @param index the position of the cursor
 * @param column the position of the column
 * @param count number of repeat
 * @param opt currntly nothing is supported
 *
 * "column" may be greater then number of characters in the current line.
 * Assume that you have following text.
 *     abcd
 *     ef
 *     12345678
 * When a cursor at character "4" goes up cursor will go at "f".
 * When a cursor goes up agein it should got at d. (This is default Vim motion)
 * To keep the column position you have to specifi the "column" argument.
 **/
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [[self string] length] == 0 ){
        return 0;
    }
    
    NSUInteger pos = index;
    for(NSUInteger i = 0; i < count; i++ ){
        pos = [self prevNewLine:pos];
        if( NSNotFound == pos ){
            pos = 0;
            break;
        }
    }

    NSUInteger head = [self headOfLine:pos];
    if( NSNotFound == head ){
        return pos;
    }
    NSUInteger end = [self endOfLine:head];
    NSAssert( end != NSNotFound, @"End can not be NSNotFound here" );
    if( head+column > end ){
        return end;
    }
    return head+column;
}

/**
 * See prevLine's description for meaning of arguments
 **/
- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    
    if (count == 0){
        return index;
    }
    
    // Search and count newlines.
    if( [self isBlankLine:index] ){
        count--; // Current position must be counted as newline in this case
    }

    // Move position along with newlines
    NSUInteger pos = index;
    for(NSUInteger i = 0; i < count; i++ ){
        NSUInteger next = [self nextNewLine:pos];
        if( NSNotFound == next){
            break;
        }
        pos = next;
    }
    
    // If "pos" is not on a newline here it means no newline is found and "pos == index".
    
    if( [self isNewLine:pos] ){
        // This is the case any newline was found.
        // pos is on a newline. The next line is the target line.
        // There is at least 1 more range available.
        pos++;
        NSUInteger end = [self endOfLine:pos];
        if( NSNotFound != end ){
            // adjust column position
            if( pos+column > end ){
                pos = end;
            }else{
                pos = pos + column;
            }
        }
        // If "end == NSNotFound" the current line is blankline
    }
    return pos; 
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
 * Returns position of next head of word.
 * @param index
 * @param count
 * @param option MOTION_OPTION_NONE or BIGWORD
 * @param info This is used with special cases explaind above such as 'cw' or 'w' crossing over the newline.
 **/
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSAssert(nil != info, @"Specify info");
    
    NSInteger pos = index;
    info->isFirstWordInALine = NO;
    info->lastEndOfLine = NSNotFound;
    info->lastEndOfWord = NSNotFound;
    
    if( [self isEOF:index] ){
        return index;
    }
    
    BOOL newLineStarts = NO;
    NSString* str = [self string];
    unichar lastChar= [str characterAtIndex:index];
    for(NSUInteger i = index+1 ; i <= [[self string] length]; i++ ){
        // Each time we encounter new word decrement "counter".
        // Remember blankline is a word
        
        unichar curChar;
        if( ![self isEOF:i] ){
            curChar = [str characterAtIndex:i];
        } 
        
        // End of line is one of following 2 cases. We must keep this to operate 'word' special case.
        //    - Last character of Non-Blankline
        //    - First character of Blankline 
        if(  [self isEOF:i] ||  (isNewLine(curChar) && ![self isBlankLine:i] ) || [self isBlankLine:i-1] ){
            info->lastEndOfLine = i - 1;
        }
        
        if( [self isEOF:i] || (isNonBlank(lastChar) && isWhiteSpace(curChar) ) ){
            info->lastEndOfWord = i - 1;
        }
        
        if( isNewLine(lastChar) ){
            newLineStarts = TRUE;
        }
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Any and EOF
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !BIGWORD)
        //    - newline and newline(blankline) 
        if( ( [self isEOF:i] ) ||
           ((isWhiteSpace(lastChar) || isNewLine(lastChar)) && isNonBlank(curChar))   ||
           ( opt != BIGWORD && isKeyword(lastChar) && !isKeyword(curChar) && !isWhiteSpace(curChar) && !isNewLine(curChar))   ||
           ( opt != BIGWORD && !isKeyword(lastChar) && !isWhiteSpace(lastChar) && !isNewLine(curChar) && isKeyword(curChar) )  ||
           ( isNewLine(lastChar) && [self isBlankLine:i] ) 
           ){
            count--; 
            if( newLineStarts ){
                info->isFirstWordInALine = YES;
                newLineStarts = NO;
            }else{
                info->isFirstWordInALine = NO;
            }
        }
     
        lastChar = curChar;
        if( 0 == count ){
            pos = i;
            break;
        }
    }
    return pos;
}


- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 1 >= index)
        return 0;
    
    NSUInteger pos = index-1;
    unichar lastChar= [[self string] characterAtIndex:pos];
    for(NSUInteger i = pos-1 ; i >= 0; i-- ){
        // Each time we encounter head of a word decrement "counter".
        // Remember blankline is a word
        
        unichar curChar = [[self string] characterAtIndex:i];
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !BIGWORD)
        //    - newline and newline(blankline) 
        if( 
           ((isWhiteSpace(curChar) || isNewLine(curChar)) && isNonBlank(lastChar))   ||
           ( opt != BIGWORD && isKeyword(curChar) && !isKeyword(lastChar) && !isWhiteSpace(lastChar) && !isNewLine(lastChar))   ||
           ( opt != BIGWORD && !isKeyword(curChar) && !isWhiteSpace(curChar) && !isNewLine(lastChar) && isKeyword(lastChar) )  ||
           ( isNewLine(curChar) && [self isBlankLine:i+1] ) 
           ){
            count--; 
        }
        
        lastChar = curChar;
        if( 0 == count ){
            pos = i+1;
            break;
        }
        if( 0 == i ){
            pos = 0;
            break;
        }
    }
    return pos;
}

- (NSUInteger)endOfWordForward:(NSUInteger)begin WholeWord:(BOOL)wholeWord{
    NSString *s = [[self textStorage] string];
    if (begin + 1 >= s.length) {
        return begin;
    }
    
    // Start search from the next character
    NSInteger curId = [self wordCharSetIdForChar:[s characterAtIndex:begin + 1]];
    for (NSUInteger x = begin; x + 1 < s.length; ++x) {
        NSInteger nextId = [self wordCharSetIdForChar:[s characterAtIndex:x + 1]];
        TRACE_LOG(@"curId: %d nextId: %d", curId, nextId);
        if (wholeWord && nextId == 0 && curId != 0) {
            return x;
        } else if (!wholeWord && curId != 0 && curId != nextId) {
            return x;
        }
        
        curId = nextId;
    }
    return s.length - 1;
}

- (NSUInteger)endOfWordsForward:(NSNumber*)count{ //e
    METHOD_TRACE_LOG();
    NSRange r = [self selectedRange];
    for(NSUInteger i = 0 ; i < [count unsignedIntValue]; i++ ){
        r.location = [self endOfWordForward:r.location WholeWord:NO];
    }
    return r.location;
}

- (NSUInteger)endOfWORDSForward:(NSNumber*)count{ //E
    NSRange r = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        r.location = [self endOfWordForward:r.location WholeWord:YES];
    }
    return r.location;
}

////////////////
// Scrolling  //
////////////////

- (NSUInteger)halfPageForward:(NSNumber*)count{ // C-d
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)halfPageBackward:(NSNumber*)count{ // C-u
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)pageForward:(NSNumber*)count{ // C-f
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)pageBackward:(NSNumber*)count{ // C-b
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)scrollBottom:(NSNumber*)count{ // zb / z-
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint bottom = NSMakePoint(0.0, -[[scrollView documentView] bounds].size.height);
    [[scrollView contentView] scrollToPoint:bottom];
    return [self selectedRange].location;
}

- (NSUInteger)scrollCenter:(NSNumber*)count{ // zz / z.
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint center = NSMakePoint(0.0, 0.0f);
    [[scrollView contentView] scrollToPoint:center];
    return [self selectedRange].location;
}

- (NSUInteger)scrollTop:(NSNumber*)count{ // zt / z<CR>
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint top = NSMakePoint(0.0, [[scrollView documentView] bounds].size.height);
    [[scrollView contentView] scrollToPoint:top];
    return [self selectedRange].location;
}

- (NSUInteger)cursorBottom:(NSNumber*)count{ // L
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
    [self moveUp:self]; // moveUp because it is one past the bottom
    return [self selectedRange].location;
}

- (NSUInteger)cursorCenter:(NSNumber*)count{ // M
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:center], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorTop:(NSNumber*)count{ // H
    NSScrollView *scrollView = [self enclosingScrollView];
    NSPoint top = [[scrollView contentView] bounds].origin;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:top], 0 };
    
    [self setSelectedRange:range];
    [self moveDown:self]; // moveDown because it is one past the top
    return [self selectedRange].location;
}

- (NSUInteger)sentencesBackward:(NSNumber*)count{ //(
    return 0;
}

- (NSUInteger)sentencesForward:(NSNumber*)count{ //)
    return 0;
}

- (NSUInteger)pragraphsBackward:(NSNumber*)count{ //{
    return 0;
}

- (NSUInteger)pragraphsForward:(NSNumber*)count{ //{
    return 0;
}

- (NSUInteger)sectionsBackward:(NSNumber*)count{ //[[
    return 0;
}

- (NSUInteger)sectionsForward:(NSNumber*)count{ //]]
    return 0;
}

////////////////
// Selection  //
////////////////
- (void)moveCursorWithBoundsCheck:(NSUInteger)to{
    if( [self string].length == 0 ){
        // nothing to do;
        return;
    }
    
    if( to >= [self string].length ){
        to = [self string].length - 1;
    }    
    
    [self setSelectedRange:NSMakeRange(to,0)];
}

- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to{
    // This is inclusive selection, which means the letter at "from" and "to" is included in the result of selction.
    // You can not use this method to move cursor since this method select 1 letter at leaset.
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }    
    
    if( [self string].length == 0 ){
        // nothing to do;
        return;
    }
    
    if( from >= [self string].length ){
        [self setSelectedRange:NSMakeRange([[self string] length], 0)]; 
        return;
    }
    
    if( to >= [self string].length ){
        to = [self string].length - 1;
    }
    
    [self setSelectedRange:NSMakeRange(from, to-from+1)];
}
@end
