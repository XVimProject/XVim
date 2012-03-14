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

- (NSUInteger)prev:(NSNumber*)count{ //h
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveLeft:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)next:(NSNumber*)count{ //l
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveRight:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
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

- (NSUInteger)wordForward:(NSUInteger)begin WholeWord:(BOOL)wholeWord{
   NSString *s = [[self textStorage] string];
    if (begin + 1 >= s.length) {
        return begin;
    }
    
    // Start search from the next character
    NSInteger curId = [self wordCharSetIdForChar:[s characterAtIndex:begin]];
    for (NSUInteger x = begin; x < s.length; ++x) {
        NSInteger nextId = [self wordCharSetIdForChar:[s characterAtIndex:x]];
        TRACE_LOG(@"curId: %d nextId: %d", curId, nextId);
        if (wholeWord && nextId != 0 && curId == 0) {
            return x;
        } else if (!wholeWord && nextId != 0 && curId != nextId) {
            return x;
        }
        
        curId = nextId;
    }
    return s.length - 1;
}

- (NSUInteger)wordsForward:(NSNumber*)count{ //w
    METHOD_TRACE_LOG();
    NSRange r = [self selectedRange];
    for(NSUInteger i = 0 ; i < [count unsignedIntValue]; i++ ){
        r.location = [self wordForward:r.location WholeWord:NO];
    }
    return r.location;
}

- (NSUInteger)WORDSForward:(NSNumber*)count{ //W
    NSRange r = [self selectedRange];
    for(NSUInteger i = 0 ; i < [count unsignedIntValue]; i++ ){
        r.location = [self wordForward:r.location WholeWord:YES];
    }
    return r.location;
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
