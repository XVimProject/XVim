
//
//  NSTextView+VimMotion.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "Logger.h"

//
// This category deals Vim's motion in NSTextView.
// Each method of motion should return the destination position of the motion.
// They shouldn't change the position of current insertion point(selected range)
// They also have some support methods for Vim motions such as obtaining next newline break.
//

static NSArray* XVimWordDelimiterCharacterSets = nil;

@implementation NSTextView (VimMotion)

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
BOOL isDigit(unichar ch) { return ch >= '0' && ch <= '9'; }
BOOL isWhiteSpace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL isNewLine(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; } // What's the defference with [NSCharacterSet newlineCharacterSet] characterIsMember:] ?
BOOL isNonAscii(unichar ch) { return ch > 128; }
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

- (BOOL) isBlankLine:(NSUInteger)index{
    if( index == [[self string] length] || isNewLine([[self string] characterAtIndex:index])){
        if( 0 == index || isNewLine([[self string] characterAtIndex:index-1]) ){
            return YES;
        }
    }
    return NO;
}

/////////////
// Motions //
/////////////

// This is tempral stub. Do not use this from new code.
- (NSUInteger)prev:(NSNumber*)count{ //h
    return [self prev:[self selectedRange].location count:count option:LEFT_RIGHT_NOWRAP];
}

- (NSUInteger)prev:(NSUInteger)begin count:(NSNumber*)count option:(MOTION_OPTION)opt{
    if( 0 == begin ){
        return 0;
    }
    
    NSString* string = [self string];
    NSUInteger pos = begin;
    for (NSUInteger i = 0; i < [count unsignedIntValue] && pos != 0 ; i++)
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



- (NSUInteger)next:(NSUInteger)begin count:(NSNumber*)count option:(MOTION_OPTION)opt{
    if( begin == [[self string] length] )
        return [[self string] length];
    
    NSString* string = [self string];
    NSUInteger pos = begin;
    // If the currenct cursor position is on a newline (blank line) and not wrappable never move the cursor
    if( opt == LEFT_RIGHT_NOWRAP && [self isBlankLine:pos]){
        return pos;
    }
    
    for (NSUInteger i = 0; i < [count unsignedIntValue] && pos < [string length]; i++) 
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

// This is tempral stub. Do not use this from new code.
- (NSUInteger)next:(NSNumber*)count{ //l
    return [self next:[self selectedRange].location count:count option:LEFT_RIGHT_NOWRAP];
}

- (NSUInteger)prevLine:(NSNumber*)count{ //k
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)nextLine:(NSNumber*)count{ //j
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)wordForward:(NSUInteger)begin{
    NSRange rr = NSMakeRange(begin, 0);
    NSRange save = rr;
    NSString *s = [[self textStorage] string];
    NSInteger start_cs_id = [self wordCharSetIdForChar:[s characterAtIndex:save.location]];
    NSUInteger x;
    for (x = save.location+1; x < s.length; x++) {
        NSInteger xid = [self wordCharSetIdForChar:[s characterAtIndex:x]];
        if (xid != start_cs_id)
            break;
    }
    if (x >= s.length) { // hit end
        x = s.length-1;
        return x;
    }
    if (start_cs_id == 0) {// started in whitespace so we are done
        return x;
    }
    // did not start in whitespace if now we are in in non-whitespace we are done
    NSInteger cs_id_2 = [self wordCharSetIdForChar:[s characterAtIndex:x]];
    if (cs_id_2 != 0) {
        return x;
    }
    // moved out of word into whitespace, move past whitespace
    for (; x < s.length; x++) {
        if ([self wordCharSetIdForChar:[s characterAtIndex:x]] != cs_id_2)
            break;
    }
    if (x >= s.length)
        x = s.length-1;
    return x;    
}
- (NSUInteger)wordsForward:(NSNumber*)count{ //w
    METHOD_TRACE_LOG();
    NSRange r = [self selectedRange];
    for(NSUInteger i = 0 ; i < [count unsignedIntValue]; i++ ){
        r.location = [self wordForward:r.location];
    }
    return r.location;
}


- (NSUInteger)WORDSForward:(NSNumber*)count{ //W
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordForward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}


- (NSUInteger)endOfWordsForward:(NSNumber*)count{ //e
    return 0;
}

- (NSUInteger)endOfWORDSForward:(NSNumber*)count{ //E
    return 0;
}

- (NSUInteger)wordBackward:(NSUInteger)begin{
    // summary --
    // if we are on a boundary start on prev char
    // move back to start of 1st span
    // if 1st span was not whitespace we are done
    // if it was then move back one char and then move to start of 2nd span
    NSRange rr = NSMakeRange(begin,0);
    NSRange save = rr;
    NSString *s = [[self textStorage] string];
    if (save.location == 0) {
        return save.location;
    }
    // if we are on a boundary start on prev char
    NSUInteger x = save.location;
    NSInteger start_cs_id = [self wordCharSetIdForChar:[s characterAtIndex:x]];
    NSInteger cs_id_2 = [self wordCharSetIdForChar:[s characterAtIndex:x-1]];
    if (start_cs_id != cs_id_2) {
        start_cs_id = cs_id_2;
        x--;
    }
    // move back to start of current span
    for (; x > 0; x--) { 
        NSInteger xid = [self wordCharSetIdForChar:[s characterAtIndex:x]];
        if (xid != start_cs_id) {
            x++;
            break;
        }
    }
    // if 1st span was not whitespace we are done
    if (start_cs_id != 0) {
        return x;
    }
    // move back one char
    x--;
    if (x == 0) { // start of file. done
        return x;
    }
    //  move to start of 2nd span
    cs_id_2 = [self wordCharSetIdForChar:[s characterAtIndex:x]];
    for (; x > 0; x--) {
        if ([self wordCharSetIdForChar:[s characterAtIndex:x]] != cs_id_2) {
            x++;
            break;
        }
    }
    return x;   
}

- (NSUInteger)wordsBackward:(NSNumber*)count{ //b
    NSRange r = [self selectedRange];
    for(NSUInteger i = 0 ; i < [count unsignedIntValue]; i++ ){
        r.location = [self wordBackward:r.location];
    }
    return r.location;
}

- (NSUInteger)WORDSBackward:(NSNumber*)count{ //B
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordBackward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

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
    NSPoint center = NSMakePoint(0.0, [[scrollView documentView] bounds].size.height / 2);
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



// How I think newline as here...
// "Newline" (which is CR or LF) is the last letter of a line.

// This dose not care about whitespaces.
- (NSUInteger)headOfLine{
    NSRange r = [self selectedRange];
    NSUInteger prevNewline = [self prevNewline];
    if( NSNotFound == prevNewline ){
        return 0; // begining of document
    }
    return prevNewline+1;
}

// may retrun NSNotFound
- (NSUInteger)prevNewline{
    NSRange r = [self selectedRange];
    if( r.location == 0 ){
        return NSNotFound;
    }
    // if the current location is newline, skip it.
    if( [[NSCharacterSet newlineCharacterSet] characterIsMember:[[self string] characterAtIndex:r.location]] ){
        r.location--;
    }
    NSRange prevNewline = [[self string] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, r.location+1)];
    return prevNewline.location;
    
}

// may retrun NSNotFound
- (NSUInteger)nextNewline{
    NSRange r = [self selectedRange];
    if( r.location >= [self string].length-1 ){
        return r.location;
    }
    // if the current location is newline, skip it.
    if( [[NSCharacterSet newlineCharacterSet] characterIsMember:[[self string] characterAtIndex:r.location]] ){
        r.location++;
    }
    NSRange nextNewline = [[self string] rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:NSMakeRange(r.location, [self string].length-r.location)];
    return nextNewline.location;
}

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
        // end of document
        from = [self string].length -1;
        to = [self string].length -1;
        return;
    }
    if( to >= [self string].length ){
        to = [self string].length - 1;
    }
    
    [self setSelectedRange:NSMakeRange(from, to-from+1)];
}
@end
