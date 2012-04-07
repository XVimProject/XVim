//
//  NSTextView+VimMotion.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All 
//

#import "NSTextView+VimMotion.h"
#import "Logger.h"
#import "XVim.h"
#import "XVimEvaluator.h"

//
// This category deals Vim's motion in NSTextView.
// Each method of motion should return the destination position of the motion.
// They shouldn't change the position of current insertion point(selected range)
// They also have some support methods for Vim motions such as obtaining next newline break.
//


@implementation NSTextView (VimMotion)
/////////////////////
// Character set   //
/////////////////////

#define CHARSET_ID_WHITESPACE 0
#define CHARSET_ID_KEYWORD 1 // This is named after 'iskeyword' in Vim

/////////////////////////
// support functions   //
/////////////////////////
BOOL isDigit(unichar ch) { return ch >= '0' && ch <= '9'; }
BOOL isWhiteSpace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL isNewLine(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; } // What's the defference with [NSCharacterSet newlineCharacterSet] characterIsMember:] ?
BOOL isNonAscii(unichar ch) { return ch > 128; } // is this not ch >= 128 ? (JugglerShu)
BOOL isAlpha(unichar ch) { 
    return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_';
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
BOOL isKeyword(unichar ch){ // same as Vim's 'iskeyword' except that Vim's one is only defined for 1 byte char
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
 * Determine if the position specified with "index" is white space.
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
 *   - EOF after Newline. Ex. The index 4 of "abc\n" is blankline. Note that index 4 is exceed the string length. But the cursor can be there.
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
 * Determine if the position specified with "index" is an empty line.
 * Empty line is one of them
 *   - Blankline
 *   - Only whitespace followed by Newline.
 **/
- (BOOL) isEmptyLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if ([self isBlankLine:index]) {
        return YES;
    }
    NSUInteger head = [self headOfLine:index];
    if (head == NSNotFound || [self nextNonBlankInALine:head] == NSNotFound){
        return YES;
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
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
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
 * Returns next non-blank character position after the position "index" in a current line.
 * If no non-blank character is found or the line is a blank line this returns NSNotFound.
 * NOTE: This searches non blank characters from "index" and NOT "index+1"
 *       If the character at "index" is non blank this returns "index" itself
 **/ 
- (NSUInteger)nextNonBlankInALine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
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

/**
 * Returns position of the first newline character when searching forwards from "index+1"
 * Searching starts from position "index"+1. The position index is not included to search newline.
 * Returns NSNotFound if no newline character is found.
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
 * Returns position of the first newline character when searching backwards from "index-1"
 * Searching starts from position "index"-1. The position index is not included to search newline.
 * Returns NSNotFound if no newline characer is found.
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
 * Returns position of the head of line of the current line specified by index.
 * Head of line is one of them which is found first when searching backwords from "index".
 *    - Character just after newline
 *    - Character at the head of document
 * If the size of document is 0 it does not have any head of line.
 * Blankline does NOT have headOfLine. So EOF is NEVER head of line.
 * Searching starts from position "index". So the "index" could be a head of line and may be returned.
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
 * Returns position of the first non-whitespace character past the head of line of the
 * current line specified by index.
 * If there is no head of line it returns NSNotFound
 **/
- (NSUInteger)headOfLineWithoutSpaces:(NSUInteger)index {
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger head = [self headOfLine:index];
    if( NSNotFound == head ){
        return NSNotFound;  
    }
    NSUInteger head_wo_space = [self nextNonBlankInALine:head];
    return head_wo_space;
}

/**
 * Returns position of the first non-blank character at the line specified by index
 * If its blank line it retuns position of newline character
 * If its a line with only white spaces it returns end of line.
 * This NEVER returns NSNotFound.
 **/
- (NSUInteger)firstNonBlankInALine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isBlankLine:index] ){
        return index;
    }
    NSUInteger head = [self headOfLine:index];
    NSUInteger end = [self endOfLine:head];
    NSUInteger head_wo_space = [self headOfLineWithoutSpaces:head];
    if( NSNotFound == head_wo_space ){
        return end;
    }else{
        return head_wo_space;
    }
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

/**
 * Returns column number of the position "index"
 * Column number starts from 0
 **/
- (NSUInteger)columnNumber:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger head = [self headOfLine:index];
    if( NSNotFound == head ){
        return 0; // This is balnkline
    }
    return index-head;
}

/**
 * Returns position at line number "num" and column number "column"
 * If the "column" exceeds the end of line it returns position of  the end of line.
 * Line number starts from 1.
 **/
- (NSUInteger)positionAtLineNumber:(NSUInteger)num column:(NSUInteger)column{
    NSAssert(0 != num, @"line number starts from 1");
    
    // Premitive search to find line number
    // TODO: we may need to keep track line number and position by hooking insertText: method.
    NSUInteger pos = 0;
    num--; // line number starts from 1
    while( pos < [[self string] length] && num != 0){ 
        if( [self isNewLine:pos] ){
            num--;
        }
        pos++;
    }
    
    if( num != 0 ){
        // Coundn't find the line
        return NSNotFound;
    }
    
    // pos is at the line number "num" and column 0
    NSUInteger end = [self endOfLine:pos];
    if( NSNotFound == end ){
        return pos;
    }
    
    // check if there is enough columns at the current line
    if( end - pos >= column ){
        return pos + column;
    }else{
        return end;
    }
    
}

- (NSUInteger)lineNumber:(NSUInteger)index{
    NSUInteger newLines=1;
    for( NSUInteger pos = 0 ; pos < index && pos < [[self string] length]; pos++ ){
        if( [self isNewLine:pos] ){
            newLines++;
        }
    }
    return newLines;
}

- (NSUInteger)numberOfLines{
    DVTSourceTextView* storage = (DVTSourceTextView*)[self textStorage];
    return [storage numberOfLines]; //  This is DVTSourceTextStorage method
}

////////////////
// Selection  //
////////////////
- (void)moveCursorWithBoundsCheck:(NSUInteger)to{
    if( to > [self string].length ){
        to = [self string].length;
    }    
    
    [self setSelectedRange:NSMakeRange(to,0)];
}

- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to{
    // This is exclusive selection
	
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
        to = [self string].length;
    }
    
    [self setSelectedRange:NSMakeRange(from, to-from)];
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
        if(  [self isEOF:i] ||  (isNonBlank(lastChar) && isNewLine(curChar)) || [self isBlankLine:i - 1]){
            info->lastEndOfLine = i - 1;
        }
        
        if( [self isEOF:i] || (isNonBlank(lastChar) && isWhiteSpace(curChar)) || (!isWhiteSpace(lastChar) && (isKeyword(lastChar) != isKeyword(curChar)))){
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
        if( isNewLine(curChar) && opt == LEFT_RIGHT_NOWRAP ){
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
    if( 1 >= index)
        return 0;
    
    NSUInteger pos = index-1;
    unichar lastChar= [[self string] characterAtIndex:pos];
    for(NSUInteger i = pos-1 ; ; i-- ){
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
        if( 0 == i ){
            pos = 0;
            break;
        }
        if( 0 == count || (isNewLine(curChar) && opt == LEFT_RIGHT_NOWRAP) ){
            pos = i+1;
            break;
        }
    }
    return pos;
}

- (NSUInteger)sentencesForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)sentencesBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)paragraphsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)paragraphsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)sectionsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}

- (NSUInteger)sectionsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    return 0;
}
    

////////////////
// Scrolling  //
////////////////
#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

- (NSUInteger)halfPageForward:(NSUInteger)index count:(NSUInteger)count{ // C-d
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat halfSize = visibleRect.size.height/2.0f;
    
    CGFloat scrollSize = halfSize*count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize ); // This may beyond the end of document (intentionally)
    
    // Cursor position relative to left-top origin shold be kept after scroll ( Exception is when it scrolls beyond the end of document)
    NSRect currentInsertionRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:container];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    NSUInteger cursorIndexAfterScroll= [[self layoutManager] glyphIndexForPoint:cursorAfterScroll inTextContainer:container fractionOfDistanceThroughGlyph:NULL];
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(cursorIndexAfterScroll,0) inTextContainer:container];
    NSPoint relativeInsertionPointAfterScroll = XVimSubPoint(insertionRectAfterScroll.origin, scrollPoint);
    CGFloat heightDiff = relativeInsertionPointAfterScroll.y - relativeInsertionPoint.y;
    scrollPoint.y += heightDiff;
    // Prohibit scroll beyond the end of document
    if( scrollPoint.y > [[scrollView documentView] frame].size.height - visibleRect.size.height ){
        scrollPoint.y = [[scrollView documentView] frame].size.height - visibleRect.size.height ;
    }
    [[scrollView contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    
    // half page down returns first character of the line
    return [self firstNonBlankInALine:cursorIndexAfterScroll];
}

- (NSUInteger)halfPageBackward:(NSUInteger)index count:(NSUInteger)count{ // C-u
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat halfSize = visibleRect.size.height/2.0f;
    
    CGFloat scrollSize = halfSize*count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y - scrollSize ); // This may beyond the head of document (intentionally)
    
    // Cursor position relative to visible rect origin should be kept after scroll ( Exception is when it scrolls beyond the end of document)
    NSRect currentInsertionRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:container];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    NSUInteger cursorIndexAfterScroll= [[self layoutManager] glyphIndexForPoint:cursorAfterScroll inTextContainer:container fractionOfDistanceThroughGlyph:NULL];
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(cursorIndexAfterScroll,0) inTextContainer:container];
    NSPoint relativeInsertionPointAfterScroll = XVimSubPoint(insertionRectAfterScroll.origin, scrollPoint);
    CGFloat heightDiff = relativeInsertionPointAfterScroll.y - relativeInsertionPoint.y;
    scrollPoint.y += heightDiff;
    // Prohibit scroll beyond the head of document
    if( scrollPoint.y < 0.0 ){
        scrollPoint.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    
    // half page down returns first character of the line
    return [self firstNonBlankInALine:cursorIndexAfterScroll];
}

- (NSUInteger)pageForward:(NSUInteger)index count:(NSUInteger)count{ // C-f
    // FIXME: This category methods MUST NOT call setSelectedRange.
    //        Just calculate the position where the cursor should be.
    [self setSelectedRange:NSMakeRange(index,0)];
    
    for( int i = 0 ; i < count; i++ ){
        [self pageDown:self];
    }
    // Find first non blank character at the line
    // If there is not the end of line is the target position
    return [self firstNonBlankInALine:[self selectedRange].location];
}

- (NSUInteger)pageBackward:(NSUInteger)index count:(NSUInteger)count{ // C-f
    // FIXME: This category methods MUST NOT call setSelectedRange.
    //        Just calculate the position where the cursor should be.
    [self setSelectedRange:NSMakeRange(index,0)];
    
    for( int i = 0 ; i < count; i++ ){
        [self pageUp:self];
    }
    // Find first non blank character at the line
    // If there is not the end of line is the target position
    return [self firstNonBlankInALine:[self selectedRange].location];
}

- (NSUInteger)scrollBottom:(NSNumber*)count{ // zb / z-
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
    bottom.y -= NSHeight([[scrollView contentView] bounds]);
    if( bottom.y < 0.0 ){
        bottom.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:bottom];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollCenter:(NSNumber*)count{ // zz / z.
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint center = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    center.y -= NSHeight([[scrollView contentView] bounds]) / 2.0f;
    if( center.y < 0.0 ){
        center.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:center];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (NSUInteger)scrollTop:(NSNumber*)count{ // zt / z<CR>
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (void)scrollToCursor{
    XVim *xvim = [self viewWithTag:XVIM_TAG];

    NSRange characterRange;
    characterRange.location = xvim.currentEvaluator.insertionPoint;
    characterRange.length = [self isBlankLine:characterRange.location] ? 0 : 1;
    
    // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
    // to the appropriate glyph due to non contiguous layout
    NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
    [[self layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
    
    NSTextContainer *container = [self textContainer];
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:container];

    CGFloat glyphLeft = NSMidX(glyphRect) - NSWidth(glyphRect) / 2.0f;
    CGFloat glyphRight = NSMidX(glyphRect) + NSWidth(glyphRect) / 2.0f;

    NSRect contentRect = [[scrollView contentView] bounds];
    CGFloat viewLeft = contentRect.origin.x;
    CGFloat viewRight = contentRect.origin.x + NSWidth(contentRect);

    NSPoint scrollPoint = contentRect.origin;
    if (glyphRight > viewRight){
        scrollPoint.x = glyphLeft - NSWidth(contentRect) / 2.0f;
    }else if (glyphLeft < viewLeft){
        scrollPoint.x = glyphRight - NSWidth(contentRect) / 2.0f;
    }

    CGFloat glyphBottom = NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f;
    CGFloat glyphTop = NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f;

    CGFloat viewTop = contentRect.origin.y;
    CGFloat viewBottom = contentRect.origin.y + NSHeight(contentRect);

    if (glyphTop < viewTop){
        if (viewTop - glyphTop > NSHeight(contentRect)){
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphTop;
        }
    }else if (glyphBottom > viewBottom){
        if (glyphBottom - viewBottom > NSHeight(contentRect)) {
            scrollPoint.y = glyphBottom - NSHeight(contentRect) / 2.0f;
        }else{
            scrollPoint.y = glyphBottom - NSHeight(contentRect);
        }
    }

    scrollPoint.x = MAX(0, scrollPoint.x);
    scrollPoint.y = MAX(0, scrollPoint.y);

    [[scrollView  contentView] scrollToPoint:scrollPoint];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}

- (NSUInteger)cursorBottom:(NSNumber*)count{ // L
    NSScrollView *scrollView = [self enclosingScrollView];
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height - NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
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
    NSTextContainer *container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = [[scrollView contentView] bounds].origin;
    top.y += NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:top], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)endOfFile
{
	return self.string.length;
}

- (void)clampRangeToEndOfLine:(NSRange*)range {
	int starti = range->location;
	int taili = [self tailOfLine:starti];
	int length = MIN(range->length, taili - range->location);
	range->length = length;
}

- (void)clampRangeToBuffer:(NSRange*)range {
	int taili = [self endOfFile];
	int length = MIN(range->length, taili - range->location);
	range->length = length;
}

- (void)toggleCaseForRange:(NSRange)range {
	
    NSString* s = [self string];
	[self clampRangeToBuffer:&range];
	
	unichar* characters = (unichar*)malloc(sizeof(unichar) * range.length);
	[s getCharacters:&characters[0] range:range];
	for (int i = 0; i < range.length; ++i)
	{
		unichar c = characters[i];
		if (c >= 'a' && c <= 'z') { c += 'A' - 'a'; }
		else if (c >= 'A' && c <= 'Z') { c += 'a' - 'A'; }
		characters[i] = c;
	}
	
	[self insertText:[NSString stringWithCharacters:characters length:range.length] replacementRange:range];
	free(characters);
}

- (void)uppercaseRange:(NSRange)range {
    NSString* s = [self string];
	[self clampRangeToBuffer:&range];
	
	[self insertText:[[s substringWithRange:range] uppercaseString] replacementRange:range];
}

- (void)lowercaseRange:(NSRange)range {
    NSString* s = [self string];
	[self clampRangeToBuffer:&range];
	
	[self insertText:[[s substringWithRange:range] lowercaseString] replacementRange:range];
}

@end
