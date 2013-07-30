//
//  NSTextStorage+VimOperation.m
//  XVim
//
//  Created by Suzuki Shuichiro on 7/30/13.
//
//

#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "DVTKit.h"


@implementation NSTextStorage (VimOperation)

#pragma mark Properties

- (NSUInteger)endOfFile{
	return self.string.length;
}

- (NSUInteger)numberOfLines{
    if( [self.class isSubclassOfClass:[DVTSourceTextStorage class]] ){
        return [((DVTSourceTextStorage*)self) numberOfLines];
    }else{
        NSUInteger lines = 1;
        for( NSUInteger i = 0 ; i < self.length; i++ ){
            if( [self isNewline:i] ){
                lines++;
            }
        }
        return lines;
    }
}


#pragma mark Definitions

- (BOOL) isEOF:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    return [[self string] length] == index;
}

- (BOOL) isEmpty{
    return [[self string] length] == 0;
}

- (BOOL) isLastCharacter:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( [self isEmpty] ){
        // Any index is not a last character
        return NO;
    }
    return [[self string] length]-1 == index;
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
    if( index == [[self string] length] ){
        return NO; // EOF is not a newline
    }
    return isNewline([[self string] characterAtIndex:index]);
}

- (BOOL) isWhitespace:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self string] length] ){
        return NO; // EOF is not whitespace
    }
    return isWhitespace([[self string] characterAtIndex:index]);
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
    return isNonblank([[self string] characterAtIndex:index]);
}

- (BOOL) isBlankline:(NSUInteger)index{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if( index == [[self string] length] || isNewline([[self string] characterAtIndex:index])){
        if( 0 == index || isNewline([[self string] characterAtIndex:index-1]) ){
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
    while (index < [[self string] length]) {
        if( [self isNewline:index] ){
            return NSNotFound; // Characters left in a line is whitespaces
        }
        if ( !isWhitespace([[self string] characterAtIndex:index])){
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
    NSUInteger length = [[self string] length];
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
    if( [[self string] length] == 0 ){
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
        return [[self string] length]-1;//just before EOF
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
    for( NSUInteger i = index; i < [[self string] length]; i++ ){
        if( [self isNewline:i] ){
            return i;
        }
    }
    return [[self string] length]; //EOF
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
	
	NSUInteger length = [[self string] length];
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
    if( [self.class isSubclassOfClass:DVTSourceTextStorage.class]){
        return (NSUInteger)[((DVTSourceTextStorage*)self) columnForPositionConvertingTabs:index];
    }else{
        return index - [self beginningOfLine:index];
    }
}


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


#pragma mark Operations on string

- (void)delete:(XVimPosition)pos{
    
}

- (void)deleteLine:(NSUInteger)lineNumber{
    
}

- (void)deleteLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2{
    
}

- (void)deleteRestOfLine:(XVimPosition)pos{
    
}

- (void)deleteBlockFrom:(XVimPosition)pos1 to:(XVimPosition)pos2{
    
}

- (void)joinAtLine:(NSUInteger)lineNumber{
    
}

- (void)vimJoinAtLine:(NSUInteger)lineNumber{
    
}

@end
