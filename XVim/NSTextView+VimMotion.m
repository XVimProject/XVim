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
        XVimWordDelimiterCharacterSets = [NSArray arrayWithObjects:
                                          [NSCharacterSet  whitespaceAndNewlineCharacterSet], // note: whitespace set is special and must be first in array
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

- (NSUInteger)nextNewLine{
    NSRange r = [self selectedRange];
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
