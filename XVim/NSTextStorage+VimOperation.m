//
//  NSTextStorage+VimOperation.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/30/13.
//
//

//    Define __USE_DVTKIT__ if you use this category with DVTKit.
// DVTSourceTextStorage( inherited from NSTextStorage ) has some useful
// methods to help our needs.
//    But to make this category usable in any Cocoa environment code
// using DVTKit related code must be enclosed in #ifdef __USE_DVTKIT__
// preprocessors macros.
//    See "columnNumber" method in this category for the typical
// implementation of the code using DVTKit related class/methods.




#if XVIM_XCODE_VERSION == 5
#define __XCODE5__
#endif

#define __USE_DVTKIT__

#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "Logger.h"

#ifdef __USE_DVTKIT__
#import "DVTKit.h"
#endif


@implementation NSTextStorage (VimOperation)

- (NSString*)xvim_string{
#ifdef __USE_DVTKIT__
    NSString* str;
#ifdef __XCODE5__
    if( [self.class isSubclassOfClass:DVTTextStorage.class]){
        DVTTextStorage* storage = (DVTTextStorage*)self;
        str = storage.string;
        return str;
    }
#else
    if( [self.class isSubclassOfClass:DVTFoldingTextStorage.class]){
        DVTFoldingTextStorage* storage = (DVTFoldingTextStorage*)self;
        [storage increaseUsingFoldedRanges];
        str = storage.string;
        [storage decreaseUsingFoldedRanges];
        return str;
    }
#endif
#endif
    return self.string;
}

#pragma mark Properties

- (NSUInteger)endOfFile{
	return self.string.length;
}

- (NSUInteger)numberOfLines{
    // If "self" is a DVTSourceTextStorage
    // The "numberOfLines" in DVTSourceTextStorage is called and
    // control flow does not reach here. (Its by design)
    NSUInteger lines = 1;
    for( NSUInteger i = 0 ; i < self.length; i++ ){
        if( [self isNewline:i] ){
            lines++;
        }
    }
    return lines;
}


#pragma mark Definitions

- (BOOL) isEOF:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [[self xvim_string] length] == index;
}

- (BOOL) isEmpty{
    return [[self xvim_string] length] == 0;
}

- (BOOL) isLastCharacter:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEmpty] ){
        // Any index is not a last character
        return NO;
    }
    return [[self xvim_string] length]-1 == index;
}

- (BOOL) isLOL:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self isEOF:index] == NO && [self isNewline:index] == NO && [self isNewline:index+1];
}

/*
- (BOOL) isFOL:(NSUInteger)index{
}
*/

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
    return [self lineNumber:index] == [self numberOfLines];
}

- (BOOL) isFirstLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [self lineNumber:index] == 1;
}

- (BOOL) isNonblank:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEOF:index]){
        return YES;
    }
    return isNonblank([[self xvim_string] characterAtIndex:index]);
}

- (BOOL) isBlankline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self xvim_string] length] || isNewline([[self xvim_string] characterAtIndex:index])){
        if( 0 == index || isNewline([[self xvim_string] characterAtIndex:index-1]) ){
            return YES;
        }
    }
    return NO;
}

- (BOOL) isEmptyline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if ([self isBlankline:index]) {
        return YES;
    }
    NSUInteger head = [self firstOfLine:index];
    if (head == NSNotFound || [self nextNonblankInLine:head] == NSNotFound){
        return YES;
    }
    return NO;
}

- (BOOL) isValidCursorPosition:(NSUInteger)index{
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

- (NSUInteger)nextNonblankInLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    while (index < [[self xvim_string] length]) {
        if( [self isNewline:index] ){
            return NSNotFound; // Characters left in a line is whitespaces
        }
        if ( !isWhitespace([[self xvim_string] characterAtIndex:index])){
            break;
        }
        index++;
    }
    
    if( [self isEOF:index]){
        return NSNotFound;
    }
    return index;
}

- (NSUInteger)nextNewline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger length = [[self xvim_string] length];
    if( length == 0 ){
        return NSNotFound; // Nothing to search
    }
    
    if( index >= length - 1 ){
        return NSNotFound;
    }
    
    for( NSUInteger i = index+1; i < length ; i++ ){
        if( [self isNewline:i] ){
            return i;
        }
    }
    return NSNotFound;
}

- (NSUInteger)prevNewline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( 0 == index ){ //Nothing to search
        return NSNotFound;
    }
    for(NSUInteger i = index-1; ; i-- ){
        if( [self isNewline:i] ){
            return i;
        }
        if( 0 == i ){
            break;
        }
    }
    return NSNotFound;
}

- (NSUInteger)firstOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [[self xvim_string] length] == 0 ){
        return NSNotFound;
    }
    if( [self isBlankline:index] ){
        return NSNotFound;
    }
    NSUInteger prevNewline = [self prevNewline:index];
    if( NSNotFound == prevNewline ){
        return 0; // head of line is character at head of document since its not empty document.
    }
    
    return prevNewline+1; // Then this is the head of line
}

- (NSUInteger)lastOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    ASSERT_VALID_CURSOR_POS(index);
    if( [self isBlankline:index] ){
        return NSNotFound;
    }
    if( [self isEOL:index] ){
        // Its not blank but tail
        return index-1;
    }
    NSUInteger nextNewline = [self nextNewline:index];
    if(NSNotFound == nextNewline){
        return [[self xvim_string] length]-1;//just before EOF
    }
    return nextNewline-1;
}

- (NSUInteger)beginningOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    while (index > 0) {
        if ( [self isNewline:index-1] ){
            // If the prev character is newline "index" is the beginning of the line
            break;
        }
        --index;
    }
    return index;
}

- (NSUInteger)endOfLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    for( NSUInteger i = index; i < [[self xvim_string] length]; i++ ){
        if( [self isNewline:i] ){
            return i;
        }
    }
    return [[self xvim_string] length]; //EOF
}

- (NSUInteger)firstOfLineWithoutSpaces:(NSUInteger)index {
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger head = [self firstOfLine:index];
    if( NSNotFound == head ){
        return NSNotFound;  
    }
    NSUInteger head_wo_space = [self nextNonblankInLine:head];
    return head_wo_space;
}

- (NSUInteger)firstNonblankInLine:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isBlankline:index] ){
        return index;
    }
    NSUInteger head = [self firstOfLine:index];
    NSUInteger end = [self endOfLine:head];
    NSUInteger head_wo_space = [self firstOfLineWithoutSpaces:head];
    if( NSNotFound == head_wo_space ){
        return end;
    }else{
        return head_wo_space;
    }
}

- (NSUInteger)positionAtLineNumber:(NSUInteger)num{
    NSAssert(0 != num, @"line number starts from 1");
    
    // Primitive search to find line number
    // TODO: we may need to keep track line number and position by hooking insertText: method.
    NSUInteger pos = 0;
    num--; // line number starts from 1
	
	NSUInteger length = [[self xvim_string] length];
    while( pos < length && num != 0){
        if( [self isNewline:pos] ){
            num--;
        }
        pos++; // may be EOF if EOF is blank line
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
	return [self nextPositionFrom:idx matchingColumn:column returnNotFound:NO];
}

- (NSUInteger)maxColumnAtLineNumber:(NSUInteger)num{
    // Column starts from 0
    NSUInteger firstIdx = [self positionAtLineNumber:num];
    if( NSNotFound == firstIdx ){
        //There no such line in the text.
        return NSNotFound;
    }
    NSUInteger eol = [self endOfLine:firstIdx];
    return eol-firstIdx;
}

// Note: This method may return position on the newline character.
//       For example, blankline have only newlin character and it is column number at "0"
- (NSUInteger)nextPositionFrom:(NSUInteger)pos matchingColumn:(NSUInteger)column returnNotFound:(BOOL)notfound{
    NSUInteger end = [self endOfLine:pos];

	// Primitive search until the column number matches
    // If tab is included in the line the values "columnNumber" returns does not continuous.
    // So "¥t¥t¥tabc" may rerturn 0,4,8,9,10,11 as a column numbers for each index.
	while (pos <= end) {
		if ([self columnNumber:pos] == column) { return pos; }
        if ([self columnNumber:pos] > column){ pos--; return pos; }
		++pos;
	}
    
    // No matching column is found
    if( notfound ){
        return NSNotFound;
    }else{
        return --pos;
    }
}

- (NSUInteger)lineNumber:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    NSUInteger newLines=1;
    for( NSUInteger pos = 0 ; pos < index && pos < self.length; pos++ ){
        if( [self isNewline:pos] ){
            newLines++;
        }
    }
    return newLines;
}

- (NSUInteger)columnNumber:(NSUInteger)index {
    ASSERT_VALID_RANGE_WITH_EOF(index);
#ifdef __USE_DVTKIT__
#ifdef __XCODE5__
    if( [self.class isSubclassOfClass:DVTTextStorage.class]){
        DVTTextStorage* storage = (DVTTextStorage*)self;
        NSUInteger column = (NSUInteger)[storage columnForPositionConvertingTabs:index];
        return column;
    }
#else
    if( [self.class isSubclassOfClass:DVTFoldingTextStorage.class]){
        DVTFoldingTextStorage* storage = (DVTFoldingTextStorage*)self;
        NSUInteger column = (NSUInteger)[storage columnForPositionConvertingTabs:[storage realLocationForFoldedLocation:index]];
        return column;
    }
#endif
#endif
    return index - [self beginningOfLine:index];
}

- (NSRange)characterRangeForLineRange:(NSRange)arg1{
    // If thie is a DVTSourceTextStorage its method is called and
    // control flow does not reach here.
    NSAssert(false, @"You must implement this method if you want to use this method with NSTextStorage class." );
    
    return NSMakeRange(NSNotFound,0);
}


/**
 * This does all the work need to do with vim '%' motion.
 * Find match pair character in the line and find the corresponding pair.
 * Returns NSNotFound if not found.
 **/
- (NSUInteger)positionOfMatchedPair:(NSUInteger)pos{
    // find matching bracketing character and go to it
    // as long as the nesting level matches up
    NSString* s = self.string;
    NSRange at =  NSMakeRange(pos,0);
    if (pos >= s.length-1) {
        return NSNotFound;
    }
    NSUInteger eol = [self endOfLine:pos];
    at.length = eol - at.location;

    NSString* search_string = [s substringWithRange:at];
    NSString* start_with;
    NSString* look_for;

    // note: these two must match up with regards to character order
    NSString *open_chars = @"{[(";
    NSString *close_chars = @"}])";
    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:[open_chars stringByAppendingString:close_chars]];

    NSInteger direction = 0;
    NSUInteger start_location = 0;
    NSRange search = [search_string rangeOfCharacterFromSet:charset];
    if (search.location != NSNotFound) {
        start_location = at.location + search.location;
        start_with = [search_string substringWithRange:search];
        NSRange search = [open_chars rangeOfString:start_with];
        if (search.location == NSNotFound){
            direction = -1;
            search = [close_chars rangeOfString:start_with];
            look_for = [open_chars substringWithRange:search];
        }else{
            direction = 1;
            look_for = [close_chars substringWithRange:search];
        }
    }else{
        // src is not an open or close char
        // vim does not produce an error msg for this so we won't either i guess
        return NSNotFound;
    }

    unichar start_with_c = [start_with characterAtIndex:0];
    unichar look_for_c = [look_for characterAtIndex:0];
    NSInteger nest_level = 0;

    search.location = NSNotFound;
    search.length = 0;

    if (direction > 0) {
        for(NSUInteger x=start_location; x < s.length; x++) {
            if ([s characterAtIndex:x] == look_for_c) {
                nest_level--;
                if (nest_level == 0) { // found match at proper level
                    search.location = x;
                    break;
                }
            } else if ([s characterAtIndex:x] == start_with_c) {
                nest_level++;
            }
        }
    } else {
        for(NSUInteger x=start_location; ; x--) {
            if ([s characterAtIndex:x] == look_for_c) {
                nest_level--;
                if (nest_level == 0) { // found match at proper level
                    search.location = x;
                    break;
                }
            } else if ([s characterAtIndex:x] == start_with_c) {
                nest_level++;
            }
            if( 0 == x ){
                break;
            }
        }
    }

    return search.location;
}

#pragma mark Vim operation related methods

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
    
    for (NSUInteger i = 0; i < count && pos < [string length]; i++) {
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
    if( [[self xvim_string] length] == 0 ){
        return 0;
    }
    
    NSUInteger pos = index;
    for(NSUInteger i = 0; i < count; i++ ){
        pos = [self prevNewline:pos];
        if( NSNotFound == pos ){
            pos = 0;
            break;
        }
    }

    NSUInteger head = [self firstOfLine:pos];
    if( NSNotFound == head ){
        return pos;
    }
	
	return [self nextPositionFrom:head matchingColumn:column returnNotFound:NO];
}

- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    
    if (count == 0){
        return index;
    }
    
    // Search and count newlines.
    if( [self isBlankline:index] ){
        count--; // Current position must be counted as newline in this case
    }

    // Move position along with newlines
    NSUInteger pos = index;
    for(NSUInteger i = 0; i < count; i++ ){
        NSUInteger next = [self nextNewline:pos];
        if( NSNotFound == next){
            break;
        }
        pos = next;
    }
    
    // If "pos" is not on a newline here it means no newline is found and "pos == index".
    
    if( [self isNewline:pos] ){
        // This is the case any newline was found.
        // pos is on a newline. The next line is the target line.
        // There is at least 1 more range available.
        pos++;
		return [self nextPositionFrom:pos matchingColumn:column returnNotFound:NO];
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
    if( [self isEOF:index] || [self isLastCharacter:index]){
        return index;
    }
    
    NSUInteger p = index+1; // We start searching end of word from next character
    NSString *string = [self xvim_string];
    while( ![self isLastCharacter:p] ){
        unichar curChar = [string characterAtIndex:p];
        unichar nextChar = [string characterAtIndex:p+1];
        // Find the border of words.
        // Vim defines "Blank Line as a word" but 'e' does not stop on blank line.
        // Thats why we are not seeing blank line as a border of a word here (commented out the condition currently)
        // We may add some option to specify if we count a blank line as a word here.
        if( opt == BIGWORD ){
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
    int paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos < s.length && NSNotFound == paragraph_head ; pos++,prevpos++ ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if(isNewline(prevc) && !isNewline(c)){
            if([self nextNonblankInLine:pos] == NSNotFound && opt == MOPT_PARA_BOUND_BLANKLINE){
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
        paragraph_head = [self endOfFile];
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
    int paragraph_found = 0;
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
    NSUInteger p = index+1;
    NSUInteger end = [self endOfLine:p];
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
    NSUInteger p = index-1;
    NSUInteger head = [self firstOfLine:p];
    if( NSNotFound == head ){
        return NSNotFound;
    }
    
    for( ; p >= head ; p-- ){
        if( [[self xvim_string] characterAtIndex:p] == character ){
            count--;
            if( 0 == count ){
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
    NSString*  string;
    NSUInteger strLen;
    NSInteger  index;
    
} NSStringHelper;
void initNSStringHelper(NSStringHelper*, NSString* string, NSUInteger strLen);
void initNSStringHelperBackward(NSStringHelper*, NSString* string, NSUInteger strLen);
unichar characterAtIndex(NSStringHelper*, NSInteger index);

- (NSRange) currentWord:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt{
    NSString* string = [self xvim_string];
    NSInteger maxIndex = [string length] - 1;
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
        
        if ( opt & BIGWORD) {
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
        if ( !(opt & TEXTOBJECT_INNER)) {
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

- (XVimPosition)XVimPositionFromIndex:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return XVimMakePosition([self lineNumber:index], [self columnNumber:index]);
}

- (NSUInteger)IndexFromXVimPosition:(XVimPosition)pos{
    return [self positionAtLineNumber:pos.line column:pos.column];
    
}

- (NSUInteger)convertToValidCursorPositionForNormalMode:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    // If the current cursor position is not valid for normal mode move it.
    if( ![self isValidCursorPosition:index] ){
        return index-1;
    }
    return index;
}



@end
