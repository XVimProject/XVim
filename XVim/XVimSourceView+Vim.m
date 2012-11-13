//
//  XVimSourceView+VimOption.m
//  XVim
//
//  Created by Tomas Lundell on 30/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.

#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "NSString+VimHelper.h"
#import "XVim.h"
#import "DVTKit.h"

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

#define charat(x) [[self string] characterAtIndex:(x)]

@implementation XVimSourceView(Vim)

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

- (void)deleteTextIntoYankRegister:(XVimRegister*)xregister
{
	[self cutText];
	[self adjustCursorPosition];
    [[XVim instance] onDeleteOrYank:xregister];
}

- (void)sortLinesInRange:(NSRange)range withOptions:(XVimSortOptions)options
{
    NSUInteger beginPos = [self positionAtLineNumber:range.location];
    NSUInteger endPos = [self positionAtLineNumber:range.location + range.length];
    NSRange characterRange = NSMakeRange(beginPos, endPos - beginPos);
    [self clampRangeToBuffer:&characterRange];
    NSString *str = [[self string] substringWithRange:characterRange];
    
    NSMutableArray *lines = [[str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    if ([[lines lastObject] length] == 0) {
        [lines removeLastObject];
    }
    [lines sortUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        NSStringCompareOptions compareOptions = 0;
        if (options & XVimSortOptionNumericSort) {
            compareOptions |= NSNumericSearch;
        }
        if (options & XVimSortOptionIgnoreCase) {
            compareOptions |= NSCaseInsensitiveSearch;
        }
        
        if (options & XVimSortOptionReversed) {
            return [str2 compare:str1 options:compareOptions];
        } else {
            return [str1 compare:str2 options:compareOptions];
        }
    }];
    
    if (options & XVimSortOptionRemoveDuplicateLines) {
        NSMutableIndexSet *removeIndices = [NSMutableIndexSet indexSet];
        [lines enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
            if (idx < [lines count] - 1) {
                NSString *nextStr = [lines objectAtIndex:idx + 1];
                if ([str isEqualToString:nextStr]) {
                    [removeIndices addIndex:idx + 1];
                }
            }
        }];
        [lines removeObjectsAtIndexes:removeIndices];
    }
    
    NSString *sortedLinesString = [[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    [self insertText:sortedLinesString replacementRange:characterRange];
}

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
        NSRange currentRange = [self selectedRange];
        [self selectPreviousPlaceholder];
        NSRange prevPlaceHolder = [self selectedRange];
        if( currentRange.location != prevPlaceHolder.location && currentRange.location == (prevPlaceHolder.location + prevPlaceHolder.length) ){
            //The condition here means that just before current insertion point is a placeholder.
            //So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
        }else{
            [self setSelectedRange:NSMakeRange(currentRange.location-1, 0)];
        }
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
 *Find and return an NSArray* with the placeholders in a current line.
 * the placeholders are returned as NSValue* objects that encode NSRange structs.
 * Returns an empty NSArray if there are no placeholders on the line.
 */
-(NSArray*)placeholdersInLine:(NSUInteger)position{
    NSMutableArray* placeholders = [[NSMutableArray alloc] initWithCapacity:2];
    NSUInteger p = [self headOfLine:position];
    
    for(NSUInteger curPos = p; curPos < [[self string] length]; curPos++){
        NSRange retval = [(DVTCompletingTextView*)[self view] rangeOfPlaceholderFromCharacterIndex:curPos forward:YES wrap:NO limit:50];
        if(retval.location != NSNotFound){
            curPos = retval.location + retval.length;
            [placeholders addObject:[NSValue valueWithRange:retval]];
        }
        if ([self isEOL:curPos] || [self isEOF:curPos]) {
            return [placeholders autorelease];
        }
    }
    
    return [placeholders autorelease];
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
 * Returns position of the head of count words forward and an info structure that handles the end of word boundaries.
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
    
    NSString* str = [self string];
    unichar lastChar= [str characterAtIndex:index];
    BOOL inWord = isNonBlank(lastChar);
    BOOL newLineStarts = isNewLine(lastChar);
    BOOL foundNonBlanks = inWord;
    for(NSUInteger i = index+1 ; i <= [[self string] length]; i++ ){
        // Each time we encounter new word decrement "counter".
        // Remember blankline is a word
        unichar curChar; 
        
        if( ![self isEOF:i] ){
            curChar = [str characterAtIndex:i];
        }else {
            //EOF found so return this position.
            info->lastEndOfLine = i-1;
            info->lastEndOfWord = i-1;
            return i-1;
        } 
        
        //parse the next character. 
        if(newLineStarts){
            if(isNewLine(curChar)){
                //two newlines in a row.
                inWord = FALSE;
                if(!info->findEndOfWord){
                    --count;
                    info->lastEndOfWord = i-1; 
                    info->lastEndOfLine = i-1; 
                }
            }else if(isNonBlank(curChar)){
                inWord = TRUE;
                --count;
                newLineStarts = FALSE;
                info->isFirstWordInALine = FALSE;
            }else {
                inWord = FALSE; 
                newLineStarts = FALSE;
                info->isFirstWordInALine = FALSE;
            }
        }else if(inWord){
            if(isNewLine(curChar)){
                //from word to newline
                newLineStarts = TRUE;
                inWord = FALSE;
                foundNonBlanks = FALSE;
                info->lastEndOfLine = i-1;
                info->lastEndOfWord = i-1;
            }else if(isNonBlank(curChar)){
                inWord = TRUE;
                newLineStarts = FALSE;
                if(isKeyword(lastChar) != isKeyword(curChar) && opt != BIGWORD){
                    --count;
                    info->lastEndOfLine = i-1;
                    info->lastEndOfWord = i-1;
                }
            }else if(!isNonBlank(curChar)){
                newLineStarts = FALSE;
                inWord = FALSE;
                info->lastEndOfLine = i-1;
                info->lastEndOfWord = i-1;
            }
        }else { //on a blank character that is not a newline
            if(isNewLine(curChar)){
                //not in word
                newLineStarts = TRUE;
                info->isFirstWordInALine = TRUE;
                info->lastEndOfLine = info->lastEndOfWord;
                inWord = FALSE;
            }else if(isNonBlank(curChar)){
                // blank to word boundary. 
                inWord = TRUE;
                newLineStarts = FALSE;
                --count;
            }else{
                //is blank character
                //nothing to do here.
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
    if( 1 >= index )
        return 0;
    NSUInteger indexBoundary = NSNotFound;
    NSUInteger pos = index-1;
    unichar lastChar = [[self string] characterAtIndex:pos];
    NSArray* placeholdersInLine = [self placeholdersInLine:pos];
    
    for(NSUInteger i = pos-1 ; ; i-- ){
        // Each time we encounter head of a word decrement "counter".
        // Remember blankline is a word
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
        unichar curChar = [[self string] characterAtIndex:i];
        
        // this branch handles the case that we found a placeholder.
        // must update the pointer into the string and update the current character found to be at the current index.
        if(indexBoundary != NSNotFound){
            count--;
            i = indexBoundary;
            if (count == 0) {
                pos = i;
                break;
            }
            curChar = [[self string] characterAtIndex:i];
        }
        // new word starts between followings.( keyword is determined by 'iskeyword' in Vim )
        //    - Whitespace(including newline) and Non-Blank
        //    - keyword and non-keyword(without whitespace)  (only when !BIGWORD)
        //    - non-keyword(without whitespace) and keyword  (only when !BIGWORD)
        //    - newline and newline(blankline) 
        else if(
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
 
 Note: if MOPT_PARA_BOUND_BLANKLINE is passed in then blank lines with whitespace are paragraph boundaries. This is to get propper function for the delete a paragraph command(dap).
 
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
        if(isNewLine(prevc) && !isNewLine(c)){
            if([self nextNonBlankInALine:pos] == NSNotFound && opt == MOPT_PARA_BOUND_BLANKLINE){
                paragraph_found++;
                if(count == paragraph_found){
                    paragraph_head = pos;
                    break;
                }
            }
        }
        if( (isNewLine(c) && isNewLine(prevc)) ){
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

////////////////
// Scrolling  //
////////////////

- (NSUInteger)pageForward:(NSUInteger)index count:(NSUInteger)count
{ // C-f
    // FIXME: This category methods MUST NOT call setSelectedRange.
    //        Just calculate the position where the cursor should be.
    [self setSelectedRange:NSMakeRange(index,0)];
    
    for( int i = 0 ; i < count; i++ ){
        [self pageDown];
    }
    // Find first non blank character at the line
    // If there is not the end of line is the target position
    return [self firstNonBlankInALine:[self selectedRange].location];
}

- (NSUInteger)pageBackward:(NSUInteger)index count:(NSUInteger)count
{ // C-f
    // FIXME: This category methods MUST NOT call setSelectedRange.
    //        Just calculate the position where the cursor should be.
    [self setSelectedRange:NSMakeRange(index,0)];
    
    for( int i = 0 ; i < count; i++ ){
        [self pageUp];
    }
    // Find first non blank character at the line
    // If there is not the end of line is the target position
    return [self firstNonBlankInALine:[self selectedRange].location];
}

- (NSUInteger)halfPageForward:(NSUInteger)index count:(NSUInteger)count
{ // C-d
	NSUInteger cursorIndexAfterScroll = [self halfPageDown:index count:count];
    return [self firstNonBlankInALine:cursorIndexAfterScroll];
}

- (NSUInteger)halfPageBackward:(NSUInteger)index count:(NSUInteger)count
{ // C-u
	NSUInteger cursorIndexAfterScroll = [self halfPageUp:index count:count];
    return [self firstNonBlankInALine:cursorIndexAfterScroll];
}

- (NSUInteger)lineForward:(NSUInteger)index count:(NSUInteger)count
{ // C-e
  return [self lineDown:index count:count];
}

- (NSUInteger)lineBackward:(NSUInteger)index count:(NSUInteger)count
{ // C-y
  return [self lineUp:index count:count];
}

// TODO: Fix the warnings
// There are too many warning in following codes.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wuninitialized"
#pragma GCC diagnostic ignored "-Wconversion"
////////////////////
/// Text Object ////
////////////////////
static NSCharacterSet* get_search_set( unichar c, NSCharacterSet* set, NSCharacterSet*);
static NSInteger seek_backwards(NSString*,NSInteger,NSCharacterSet*);
static NSInteger seek_forwards(NSString*,NSInteger,NSCharacterSet*);

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


