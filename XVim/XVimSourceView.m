#import "XVimSourceView.h"
#import "NSString+VimHelper.h"
#import "DVTSourceTextView.h"
#import "DVTFoldingTextStorage.h"
#import "Logger.h"
#import "XVim.h"

@interface XVimSourceView() {
	__weak DVTSourceTextView *_view;
}
@end

@implementation XVimSourceView

- (id)initWithSourceView:(DVTSourceTextView*)sourceView
{
	if (self = [super init])
	{
		_view = sourceView;
	}
	return self;
}

- (NSView*)view
{
	return _view;
}

/////////////////////////
// support methods     //
/////////////////////////
#ifdef DEBUG
// Most of the support methods take index as current interest position and index can be at EOF
// The following macros asserts the range of index.
// WITH_EOF permits the index at EOF position.
// WITHOUT_EOF doesn't permit the index at EOF position.
#define ASSERT_VALID_RANGE_WITH_EOF(x) NSAssert( x <= [[self string] length] || [[self string] length] == 0, @"index can not exceed the length of string" )
#define ASSERT_VALID_RANGE_WITHOUT_EOF(x) NSAssert( x < [[self string] length] || [[self string] length] == 0, @"index can not exceed the length of string - 1" )

// Some methods assume that "index" is at valid cursor position in Normal mode.
// See isValidCursorPosition's description the condition of the valid cursor position.
#define ASSERT_VALID_CURSOR_POS(x) NSAssert( [self isValidCursorPosition:x], @"index can not be invalid cursor position" )
#else
#define ASSERT_VALID_RANGE_WITH_EOF(x)
#define ASSERT_VALID_RANGE_WITHOUT_EOF(x)
#define ASSERT_VALID_CURSOR_POS(x)
#endif

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
 * Returns position of the head of line specified by index.
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
 * Returns position of first character of the line specified by index.
 * Note that first character in the line is different from head of line.
 * First character may be newline when its blankline.
 * First character may be EOF if the EOF is blankline
 * In short words, its just after a newline or begining of document.
 * This never returns NSNotFound
 **/
- (NSUInteger)firstOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    while (index > 0)
    {
        if (isNewLine([[self string] characterAtIndex:index-1])) { break; }
        --index;
    }
    return index;
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
	DVTFoldingTextStorage *textStorage = (DVTFoldingTextStorage*)[_view textStorage];
	return [textStorage columnForPositionConvertingTabs:index];
}

- (NSUInteger)nextPositionFrom:(NSUInteger)pos matchingColumn:(NSUInteger)column
{
    // pos is at the line number "num" and column 0
    NSUInteger end = [self endOfLine:pos];
    if( NSNotFound == end ){
        return pos;
    }
	
	// Primitive search until the column number matches
	while (pos < end) {
		if ([self columnNumber:pos] == column) { break; }
		++pos;
	}
	return pos;
}

- (NSUInteger)positionAtLineNumber:(NSUInteger)num
{
    NSAssert(0 != num, @"line number starts from 1");
    
    // Primitive search to find line number
    // TODO: we may need to keep track line number and position by hooking insertText: method.
    NSUInteger pos = 0;
    num--; // line number starts from 1
	
	NSUInteger length = [[self string] length];
    while( pos < length && num != 0){ 
        if( [self isNewLine:pos] ){
            num--;
        }
        pos++;
    }
    
    if( num != 0 ){
        // Couldn't find the line
        return NSNotFound;
    }
	
	return pos;
}
	
- (NSUInteger)positionAtLineNumber:(NSUInteger)num column:(NSUInteger)column{
	NSUInteger idx = [self positionAtLineNumber:num];
	if (idx == NSNotFound) { return NSNotFound; }
	return [self nextPositionFrom:idx matchingColumn:column];
}

// Returns first position that is non-whitespace. If newline or eof encountered, returns index.
- (NSUInteger)skipWhiteSpace:(NSUInteger)index
{
	NSUInteger length = [[self string] length];
	for (NSUInteger i = index; i < length; ++i)
	{
		if ([self isNewLine:i]) { break; }
		if (![self isWhiteSpace:i]) { return i; }
	}
	return index;
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
	
	return [self nextPositionFrom:head matchingColumn:column];
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
		return [self nextPositionFrom:pos matchingColumn:column];
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
    
    NSUInteger pos = index;
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
    NSString* s = [self string];
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
            unichar c2;
            // Skip )]"'
            for( ; k < s.length ; k++ ){
                c2 = [s characterAtIndex:k];
                if( c2 != ')' && c2 != ']' && c2 != '"' && c2  != '\'' ){
                    break;
                }
            }
            // after )]"' must be space to be end of a sentence.
            if( k < s.length && !isNonBlank(c2) ){ // !isNonBlank == isBlank
                // This is a end of sentence.
                // Now search for next non blank character to find head of sentence
                for( k++ ; k < s.length ; k++ ){
                    c2 = [s characterAtIndex:k];
                    if(isNonBlank(c2)){
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
            sentence_head = [self endOfFile];
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
    NSString* s = [self string];
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
            unichar c2;
            // Skip )]"'
            for( ; k < lastSearchBase ; k++ ){
                c2 = [s characterAtIndex:k];
                if( c2 != ')' && c2 != ']' && c2 != '"' && c2 != '\'' ){
                    break;
                }
            }
            // after )]"' must be space to be end of a sentence.
            if( k < lastSearchBase && !isNonBlank(c2) ){ // !isNonBlank == isBlank
                // This is a end of sentence.
                // Now search for next non blank character
                for( k++ ; k < lastSearchBase ; k++ ){
                    c2 = [s characterAtIndex:k];
                    if(isNonBlank(c2)){
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
 Also note that this does not include a '{' or '}' in the first column.  When
 the '{' flag is in 'cpoptions' then '{' in the first column is used as a
 paragraph boundary |posix|.
 */

- (NSUInteger)paragraphsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    NSUInteger pos = index;
    NSString* s = [self string];
    if( 0 == pos ){
        pos = 1;
    }
    NSUInteger prevpos = pos - 1;
    
    NSUInteger paragraph_head = NSNotFound;
    int paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos < s.length && NSNotFound == paragraph_head ; pos++,prevpos++ ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if( isNewLine(c) && isNewLine(prevc)){
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
        paragraph_head = [self endOfFile];
        while( ![self isValidCursorPosition:paragraph_head] ){
            paragraph_head--;
        }
    }
    
    return paragraph_head;
}

- (NSUInteger)paragraphsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{ //(
    NSUInteger pos = index;
    NSString* s = [self string];
    if( pos == 0 ){
        return NSNotFound;
    }
    if( pos == s.length )
    {
        pos = pos - 1;
    }
    NSUInteger prevpos = pos - 1;
    NSUInteger paragraph_head = NSNotFound;
    int paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos > 0 && NSNotFound == paragraph_head ; pos--,prevpos-- ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if(isNewLine(c) && isNewLine(prevc)){
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
    

////////////////
// Scrolling  //
////////////////
#define XVimAddPoint(a,b) NSMakePoint(a.x+b.x,a.y+b.y)  // Is there such macro in Cocoa?
#define XVimSubPoint(a,b) NSMakePoint(a.x-b.x,a.y-b.y)  // Is there such macro in Cocoa?

- (NSUInteger)halfPageForward:(NSUInteger)index count:(NSUInteger)count{ // C-d
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat halfSize = visibleRect.size.height/2.0f;
    
    CGFloat scrollSize = halfSize*count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y + scrollSize ); // This may beyond the end of document (intentionally)
    
    // Cursor position relative to left-top origin shold be kept after scroll ( Exception is when it scrolls beyond the end of document)
    NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:container];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    NSUInteger cursorIndexAfterScroll= [[_view layoutManager] glyphIndexForPoint:cursorAfterScroll inTextContainer:container fractionOfDistanceThroughGlyph:NULL];
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(cursorIndexAfterScroll,0) inTextContainer:container];
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
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    
    NSRect visibleRect = [scrollView contentView].bounds;
    CGFloat halfSize = visibleRect.size.height/2.0f;
    
    CGFloat scrollSize = halfSize*count;
    NSPoint scrollPoint = NSMakePoint(visibleRect.origin.x, visibleRect.origin.y - scrollSize ); // This may beyond the head of document (intentionally)
    
    // Cursor position relative to visible rect origin should be kept after scroll ( Exception is when it scrolls beyond the end of document)
    NSRect currentInsertionRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(index,0) inTextContainer:container];
    NSPoint relativeInsertionPoint = XVimSubPoint(currentInsertionRect.origin, visibleRect.origin);
    
    // Cursor Position after scroll
    NSPoint cursorAfterScroll = XVimAddPoint(scrollPoint,relativeInsertionPoint);
    
    // Nearest character index to the cursor position after scroll
    NSUInteger cursorIndexAfterScroll= [[_view layoutManager] glyphIndexForPoint:cursorAfterScroll inTextContainer:container fractionOfDistanceThroughGlyph:NULL];
    // We do not want to change the insert point relative position from top of visible rect
    // We have to calc the distance between insertion point befor/after scrolling to keep the position.
    NSRect insertionRectAfterScroll = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(cursorIndexAfterScroll,0) inTextContainer:container];
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
        [_view pageDown:self];
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
        [_view pageUp:self];
    }
    // Find first non blank character at the line
    // If there is not the end of line is the target position
    return [self firstNonBlankInALine:[self selectedRange].location];
}

- (NSUInteger)scrollBottom:(NSNumber*)count{ // zb / z-
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
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
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
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
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
    return [self selectedRange].location;
}

- (void)scrollTo:(NSUInteger)location
{
    NSRange characterRange;
    characterRange.location = location;
    characterRange.length = [self isBlankLine:characterRange.location] ? 0 : 1;
    
    // Must call ensureLayoutForGlyphRange: to fix a bug where it will not scroll
    // to the appropriate glyph due to non contiguous layout
    NSRange glyphRange = [[_view layoutManager] glyphRangeForCharacterRange:characterRange actualCharacterRange:NULL];
    [[_view layoutManager] ensureLayoutForGlyphRange:NSMakeRange(0, glyphRange.location + glyphRange.length)];
    
    NSTextContainer *container = [_view textContainer];
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:container];

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
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
    NSPoint bottom = [[scrollView contentView] bounds].origin;
    bottom.y += [[scrollView contentView] bounds].size.height - NSHeight(glyphRect) / 2.0f;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:bottom], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorCenter:(NSNumber*)count{ // M
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSPoint center = [[scrollView contentView] bounds].origin;
    center.y += [[scrollView contentView] bounds].size.height / 2;
    NSRange range = { [[scrollView documentView] characterIndexForInsertionAtPoint:center], 0 };
    
    [self setSelectedRange:range];
    return [self selectedRange].location;
}

- (NSUInteger)cursorTop:(NSNumber*)count{ // H
    NSScrollView *scrollView = [_view enclosingScrollView];
    NSTextContainer *container = [_view textContainer];
    NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:[self selectedRange] inTextContainer:container];
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
    ASSERT_VALID_RANGE_WITH_EOF(range->location);
	NSUInteger starti = range->location;
	NSUInteger taili = [self tailOfLine:starti];
    NSUInteger length = range->length;
    // We do not need to check if "taili > range->location"(Integer Undeflow) since taili is result of tailofLine based on the location 
    length = MIN(range->length, taili - range->location);
	range->length = length;
}

- (void)clampRangeToBuffer:(NSRange*)range {
    ASSERT_VALID_RANGE_WITH_EOF(range->location);
	NSUInteger taili = [self endOfFile];
	NSUInteger length = range->length;
    // We do not need to check if "taili > range->location"(Integer Undeflow) since taili(endOfFile) is equal or greater the location (which is checked by assersion)
    length = MIN(range->length, taili - range->location);    
	range->length = length;
}

- (void)toggleCaseForRange:(NSRange)range {
	
    NSString* text = [self string];
	[self clampRangeToBuffer:&range];
	
	NSMutableString *substring = [[text substringWithRange:range] mutableCopy];
	for (NSUInteger i = 0; i < range.length; ++i) {
		NSRange currentRange = NSMakeRange(i, 1);
		NSString *currentCase = [substring substringWithRange:currentRange];
		NSString *upperCase = [currentCase uppercaseString];
		
		NSRange replaceRange = NSMakeRange(i, 1);
		if ([currentCase isEqualToString:upperCase]){
			[substring replaceCharactersInRange:replaceRange withString:[currentCase lowercaseString]];
		}else{
			[substring replaceCharactersInRange:replaceRange withString:upperCase];
		}	
	}
	
	[self insertText:substring replacementRange:range];
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

- (NSRange)getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    
    if( type == CHARACTERWISE_EXCLUSIVE ){
    }else if( type == CHARACTERWISE_INCLUSIVE ){
		to++;
    }else if( type == LINEWISE ){
        to = [self tailOfLine:to] + 1;
        NSUInteger head = [self headOfLine:from];
        if( NSNotFound != head ){
            from = head; 
        }
    }
	
	return NSMakeRange(from, to - from);
}

- (void)selectOperationTargetFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
	NSRange opRange = [self getOperationRangeFrom:from To:to Type:type];
    [self setSelectedRangeWithBoundsCheck:opRange.location To:opRange.location + opRange.length];
}

//////////////////////////////////////////////////////////////////////// 
// Pass-through functions to NSTextView or DVTSourceTextView

- (NSUInteger)numberOfLines{
    XVimSourceView* storage = [_view textStorage];
    return [storage numberOfLines]; //  This is DVTSourceTextStorage method
}

- (NSString *)string
{
	return [_view string];
}

- (void)indentCharacterRange:(NSRange)range
{
	[[_view textStorage] indentCharacterRange:range undoManager:[_view undoManager]];
}

- (void)shiftLeft
{
	[_view shiftLeft:self];
}

- (void)shiftRight
{
	[_view shiftRight:self];
}

- (long long)currentLineNumber
{
	return [_view _currentLineNumber];
}

- (NSUInteger)glyphIndexForPoint:(NSPoint)point
{
	NSUInteger glyphIndex = [[_view layoutManager] glyphIndexForPoint:point inTextContainer:[_view textContainer]];
	return glyphIndex;
}

- (NSRect)boundingRectForGlyphIndex:(NSUInteger)glyphIndex
{
	NSRect glyphRect = [[_view layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[_view textContainer]];
	return glyphRect;
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color
{
	[_view _drawInsertionPointInRect_:rect color:color];
}

- (void)hideCompletions
{
	[[_view completionController] hideCompletions];
}

- (void)selectNextPlaceholder
{
	[_view selectNextPlaceholder:self];
}

- (void)deleteText
{
	[_view delete:self];
}

- (void)cutText
{
	[_view cut:self];
}

- (void)copyText
{
	[_view copy:self];
}

- (void)deleteTextIntoYankRegister:(XVimRegister*)xregister
{
	[_view cut:self];
	[self adjustCursorPosition];
    [[XVim instance] onDeleteOrYank:xregister];
}

- (void)moveUp
{
	[_view moveUp:self];
}

- (void)moveDown
{
	[_view moveDown:self];
}

- (void)moveForward
{
	[_view moveForward:self];
}

- (void)moveForwardAndModifySelection
{
	[_view moveForwardAndModifySelection:self];
}

- (void)moveBackward
{
	[_view moveBackward:self];
}

- (void)moveBackwardAndModifySelection
{
	[_view moveBackwardAndModifySelection:self];
}
	 
- (void)moveToBeginningOfLine
{
	[_view moveToBeginningOfLine:self];
}

- (void)moveToEndOfLine
{
	[_view moveToEndOfLine:self];
}

- (void)deleteForward
{
	[_view deleteForward:self];
}

- (void)insertText:(NSString*)text
{
	[_view insertText:text];
}
- (void)insertText:(NSString*)text replacementRange:(NSRange)range
{
	[_view insertText:text replacementRange:range];
}

- (void)insertNewline
{
	[_view insertNewline:self];
}

- (void)keyDown:(NSEvent*)event
{
	[_view keyDown_:event];
}

- (void)undo
{
	[[_view undoManager] undo];
}

- (void)redo
{
	[[_view undoManager] redo];
}

- (void)setWrapsLines:(BOOL)wraps
{
	[_view setWrapsLines:wraps];
}

- (void)updateInsertionPointStateAndRestartTimer
{
	[_view updateInsertionPointStateAndRestartTimer:YES];
}

- (NSColor*)insertionPointColor
{
	return [_view insertionPointColor];
}

- (void)showFindIndicatorForRange:(NSRange)range
{
	[_view showFindIndicatorForRange:range];
}

- (NSRange)selectedRange
{
	return [_view selectedRange];
}

- (void)setSelectedRange:(NSRange)range
{
	[_view setSelectedRange:range];
}

// TODO: Fix the warnings
// There are too many warning in following codes.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wuninitialized"
#pragma GCC diagnostic ignored "-Wconversion"
////////////////////
/// Text Object ////
////////////////////
- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSString* string = [self string];
    NSInteger maxIndex = [string length] - 1;
    if (index > maxIndex) { return NSMakeRange(NSNotFound, 0); }
    
    NSInteger rangeStart = index;
    NSInteger rangeEnd = index;
    
    // repeatCount loop starts here
    while (count--) {
        // Skip past newline
        while (index < maxIndex && isNewLine([string characterAtIndex:index])) {
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
        if ( opt & INCLUSIVE) {
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
                    if (newBegin == 0 || isNewLine([string characterAtIndex:newBegin - 1])) {
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
    NSInteger copyBegin = index;
    NSInteger size      = (index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
    [h->string getCharacters:h->buffer range:NSMakeRange(copyBegin, size)];
    return copyBegin;
}

NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index);
NSInteger fetchSubStringEnds(NSStringHelper* h, NSInteger index)
{
    NSInteger copyBegin = (index + 1) >= ITERATE_STRING_BUFFER_SIZE ? index + 1 - ITERATE_STRING_BUFFER_SIZE : 0;
    NSInteger size      = (index + ITERATE_STRING_BUFFER_SIZE) > h->strLen ? h->strLen - index : ITERATE_STRING_BUFFER_SIZE;
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
        if (isNewLine(ch)) {
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
            if (isNewLine(ch) || isWhiteSpace(ch) == NO) {
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
        if (isNewLine([string characterAtIndex:index-1])) { break; }
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
            
            if (isNewLine(characterAtIndex(h, pos)))
            {
                // At prev line.
                do_quotes = -1;
            }
        } else {  // Forward search
            if (pos == maxIndex) { break; } // At end of file
            
            if (isNewLine(characterAtIndex(h, pos))) {
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
            while (ptr > 0 && !isNewLine([string characterAtIndex:ptr-1])) { --ptr; }
            NSInteger sta = ptr;
            
            while (ptr < maxIndex && 
                   !isNewLine(characterAtIndex(h, ptr)))
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
                    !isNewLine(characterAtIndex(h, ptr+1))) 
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
                        if (isNewLine(c2) || c2 != '\\') {
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
                            if (isNewLine(characterAtIndex(h, p1))) {
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
                        if (pos < maxIndex && !isNewLine(characterAtIndex(h, pos + 1)))
                        {
                            if (characterAtIndex(h, pos + 1) == '\\' &&
                                (pos < maxIndex - 2) &&
                                !isNewLine(characterAtIndex(h, pos + 2)) &&
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
                            if (isNewLine(c2) || c2 != '\\') {
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
		if (isNewLine(ch)) { break; }
		
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
        if (isNewLine(ch)) { break; }
		
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
        } else if (isNewLine(ch))
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
@end