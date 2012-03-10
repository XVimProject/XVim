//
//  XVimMotionEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "XVimSearchLineEvaluator.h"
#import "XVimGEvaluator.h"
#import "XVimZEvaluator.h"
#import "XVimLocalMarkEvaluator.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimYankEvaluator.h"


////////////////////////////////
// How to Implement Motion    //
////////////////////////////////

// On each key input calculate beginning and end of motion and call _motionFixedFrom:To:Type method (not motionFixedFrom:To:Type).
// It automatically treat switching inclusive/exclusive motion by 'v'.
// How the motion is treated depends on a subclass of the XVimMotionEvaluator.
// For example, XVimDeleteEvaluator will delete the letters represented by motion.

@implementation XVimMotionEvaluator

- (id)init
{
    self = [super init];
    if (self) {
        _inverseMotionType = NO;
    }
    return self;
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    NSUInteger motionFrom = begin.location;
    NSUInteger motionTo = [view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    return [self _motionFixedFrom:motionFrom To:motionTo Type:type];
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    TRACE_LOG(@"from:%d to:%d type:%d", from, to, type);
    if( _inverseMotionType ){
        if ( type == CHARACTERWISE_EXCLUSIVE ){
            type = CHARACTERWISE_INCLUSIVE;
        }else if(type == CHARACTERWISE_INCLUSIVE){
            type = CHARACTERWISE_EXCLUSIVE;
        }
   }    
    return [self motionFixedFrom:from To:to Type:type];
}

// Methods to override by subclass
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type {
    return nil;
}


////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b:(id)arg{
    return [self commonMotion:@selector(wordsBackward:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)B:(id)arg{
    return [self commonMotion:@selector(WORDSBackward:) Type:CHARACTERWISE_EXCLUSIVE];
}

/*
// Since Ctrl-b, Ctrl-d is not "motion" but "scroll" 
// they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_b:(id)arg{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}

- (XVimEvaluator*)C_d:(id)arg{
    return [self commonMotion:@selector(halfPageForward:) Type:LINEWISE];
}
*/

- (XVimEvaluator*)f:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    return eval;
}

- (XVimEvaluator*)F:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    return eval;
}

/*
 // Since Ctrl-f is not "motion" but "scroll" 
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
- (XVimEvaluator*)C_f:(id)arg{
    return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
}
*/

- (XVimEvaluator*)g:(id)arg{
    return [[XVimGEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)G:(id)arg{
    NSTextView* view = [self textView];
    return [self _motionFixedFrom:[view selectedRange].location To:[view string].length Type:LINEWISE]; // Is this safe? Should it be [view string].length-1?
}

- (XVimEvaluator*)h:(id)arg{
    return [self commonMotion:@selector(prev:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)H:(id)arg{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)j:(id)arg{
    return [self commonMotion:@selector(nextLine:) Type:LINEWISE];
}

- (XVimEvaluator*)k:(id)arg{
    return [self commonMotion:@selector(prevLine:) Type:LINEWISE];
}

- (XVimEvaluator*)l:(id)arg{
    return [self commonMotion:@selector(next:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)L:(id)arg{
    return [self commonMotion:@selector(cursorBottom:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)M:(id)arg{
    return [self commonMotion:@selector(cursorCenter:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)n:(id)arg{
    [[self xvim] searchNext];
    return nil;
}

- (XVimEvaluator*)N:(id)arg{
    [[self xvim] searchPrevious];
    return nil;
}
/*
// Since Ctrl-u is not "motion" but "scroll" 
// it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_u:(id)arg{
    return [self commonMotion:@selector(halfPageBackward:) Type:LINEWISE];
}
*/

- (XVimEvaluator*)v:(id)arg{
    _inverseMotionType = !_inverseMotionType;
    return self;
}

- (XVimEvaluator*)w:(id)arg{
    return [self commonMotion:@selector(wordsForward:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)W:(id)arg{
    return [self commonMotion:@selector(WORDSBackward:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)z:(id)arg{
    return [[XVimZEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)NUM0:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange end = [view selectedRange];
    NSUInteger dest = [view selectedRange].location;
    [view setSelectedRange:begin];
    return [self _motionFixedFrom:begin.location To:dest Type:CHARACTERWISE_INCLUSIVE];
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE:(id)arg{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETOSTARTOFLINE xvimTarget:[self xvim]];
}
- (XVimEvaluator*)BACKQUOTE:(id)arg{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETO xvimTarget:[self xvim]];
}


// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    NSString* s = [[view textStorage] string];
    [view moveToBeginningOfLine:self];
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
    [view setSelectedRange:begin];
    return [self _motionFixedFrom:begin.location To:end.location Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)DOLLAR:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToEndOfLine:self];
    }
    NSRange end = [view selectedRange];
    [view setSelectedRange:begin];
    return [self _motionFixedFrom:begin.location To:end.location Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)PERCENT:(id)arg {
    // find matching bracketing character and go to it
    // as long as the nesting level matches up
    NSTextView* view = [self textView];
    NSString* s = [[view textStorage] string];
    NSRange at = [view selectedRange]; 
    if (at.location >= s.length-1) {
        // [[self xvim] statusMessage:@"leveled match not found" :ringBell TRUE]
        [[self xvim] ringBell];
        return self;
    }
    at.length = 1;
    
    NSString* start_with = [s substringWithRange:at];
    NSString* look_for;
    
    // note: these two much match up with regards to character order
    NSString* open_chars = @"{[(<";
    NSString* close_chars = @"}])>";
    
    NSInteger direction = 0;
    NSRange search = [open_chars rangeOfString:start_with];
    if (search.location != NSNotFound) {
        direction = 1;
        look_for = [close_chars substringWithRange:search];
    }
    if (direction == 0) {
        search = [close_chars rangeOfString:start_with];
        if (search.location != NSNotFound) {
            direction = -1;
            look_for = [open_chars substringWithRange:search];
        }
    }
    if (direction == 0) {
        // src is not an open or close char
        // vim does not produce an error msg for this so we won't either i guess
        // [[self xvim] statusMessage:@"Not a match character" :ringBell TRUE]
        [[self xvim] ringBell];
        return self;
    }
    
    unichar start_with_c = [start_with characterAtIndex:0];
    unichar look_for_c = [look_for characterAtIndex:0];
    NSInteger nest_level = 0;
    
    search.location = NSNotFound;
    search.length = 0;
    
    if (direction > 0) {
        for(NSUInteger x=at.location; x < s.length; x++) {
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
        for(NSUInteger x=at.location; ; x--) {
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
    
    if (search.location == NSNotFound) {
        // [[self xvim] statusMessage:@"leveled match not found" :ringBell TRUE]
        [[self xvim] ringBell];
    } else {
        [self _motionFixedFrom:at.location To:search.location Type:CHARACTERWISE_INCLUSIVE];
    }
    
    return self;
}

/* 
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SP:(id)arg{
    return [self l:arg];
}

/* 
 * Delete (DEL) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)DEL:(id)arg{
    return [self h:arg];
}

- (XVimEvaluator*)PLUS:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDown:self];
    }
    [view moveToBeginningOfLine:self];
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char, now that we are on the destination line
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
    [view setSelectedRange:begin];
    return [self _motionFixedFrom:begin.location To:end.location Type:LINEWISE];
}

/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(id)arg{
    return [self PLUS:arg];
}


- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char, now that we are on the destination line
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
    [view setSelectedRange:begin];
    return [self _motionFixedFrom:begin.location To:end.location Type:LINEWISE];
}


- (XVimEvaluator*)LSQUAREBRACKET:(id)arg{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET:(id)arg{
    // TODO: implement XVimRSquareBracketEvaluator
    return nil;
}


/*
 Definition of Sentence from gVim help
 
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
- (XVimEvaluator*)LBRACE:(id)arg{ // {
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger pos = begin.location;
    if( pos == 0 ){
        return nil;
    }
    NSUInteger prevpos = pos - 1;
    NSUInteger paragraph_head = NSNotFound;
    int paragraph_found = 0;
    BOOL newlines_skipped = NO;
    for( ; pos > 0 && NSNotFound == paragraph_head ; pos--,prevpos-- ){
        unichar c = [s characterAtIndex:pos];
        unichar prevc = [s characterAtIndex:prevpos];
        if( [[NSCharacterSet newlineCharacterSet] characterIsMember:c] && [[NSCharacterSet newlineCharacterSet] characterIsMember:prevc]){
            if( newlines_skipped ){
                paragraph_found++;
                if( [self numericArg] == paragraph_found ){
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
    
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)RBRACE:(id)arg{ // }
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger pos = begin.location;
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
        if( [[NSCharacterSet newlineCharacterSet] characterIsMember:c] && [[NSCharacterSet newlineCharacterSet] characterIsMember:prevc]){
            if( newlines_skipped ){
                paragraph_found++;
                if( [self numericArg] == paragraph_found ){
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
        paragraph_head = s.length-1;
    }
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE];
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
- (XVimEvaluator*)LPARENTHESIS:(id)arg{ // (
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger pos = begin.location;
    
    NSUInteger sentence_head = NSNotFound;
    int sentence_found = 0;
    // Search "." or "!" or "?" backwards and check if it is followed by spaces(and closing characters)
    for( ; pos > 0 && NSNotFound == sentence_head ; pos-- ){
        unichar c = [s characterAtIndex:pos];
        if( c == '.' || c == '!' || c == '?' ){
            // search forward for a space while ignoring ")","]",'"','''
            for( NSUInteger k = pos+1; k < s.length && k < begin.location ; k++ ){
                unichar c2 = [s characterAtIndex:k];
                if( c2 == ')' || c2 == ']' || c2 == '"' || c2 == '\'' ){
                    continue;
                }else if( [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:k]] || [[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:k]]){
                    // search next character(which is not white space) to find the head of sentence.
                    for( k++; k < s.length; k++ ){
                        if( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:k]] && ![[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:k]]){
                            // Found a head of sentence.
                            // if the current insertion point is the head of sentence we do not count it as we find a head of sentence.
                            if( begin.location != k ){
                                sentence_found++;
                                if( [self numericArg] == sentence_found ){
                                    sentence_head = k;
                                }
                            }
                            break;
                        }
                    }
                }else{
                    // not a head of sentence
                    break;
                }
                if( NSNotFound != sentence_head ){
                    // already found the position we want
                    break;
                }
            }   
        }
    }
    
    if( ((sentence_found+1) == [self numericArg] && pos == 0 ) ){
        //begining of document
        sentence_head = 0;
        
    }
    
    if( NSNotFound != sentence_head  ){
        return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE];
    }else{
        // no movement
        return nil;
    }
    
    
}

- (XVimEvaluator*)RPARENTHESIS:(id)arg{ // )
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger pos = begin.location;
    
    NSUInteger sentence_head = NSNotFound;
    int sentence_found = 0;
    // Search "." or "!" or "?" forward and check if it is followed by spaces(and closing characters)
    for( ; pos < s.length && NSNotFound == sentence_head ; pos++ ){
        unichar c = [s characterAtIndex:pos];
        if( c == '.' || c == '!' || c == '?' ){
            // search forward for a space while ignoring ")","]",'"','''
            for( NSUInteger k = pos+1; k < s.length ; k++ ){
                unichar c2 = [s characterAtIndex:k];
                if( c2 == ')' || c2 == ']' || c2 == '"' || c2 == '\'' ){
                    continue;
                }else if( [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:k]] || [[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:k]]){
                    // search next character(which is not white space) to find the head of sentence.
                    for( k++; k < s.length; k++ ){
                        if( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:k]] && ![[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:k]]){
                            // Found a head of sentence.
                            // if the current insertion point is the head of sentence we do not count it as we find a head of sentence.
                            if( begin.location != k ){
                                sentence_found++;
                                if( [self numericArg] == sentence_found ){
                                    sentence_head = k;
                                }
                            }
                            break;
                        }
                    }
                }else{
                    // not a end of sentence
                    break;
                }
                if( NSNotFound != sentence_head ){
                    // already found the position we want
                    break;
                }
            }   
        }
    }
    
    if( NSNotFound == sentence_head   ){
        // end of document
        sentence_head = s.length-1;
    }
    return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)Up:(id)arg{
    return [self k:(id)arg];
}

- (XVimEvaluator*)Down:(id)arg{
    return [self j:(id)arg];
    
}

- (XVimEvaluator*)Left:(id)arg{
    return [self h:(id)arg];
    
}
- (XVimEvaluator*)Right:(id)arg{
    return [self l:(id)arg];
}

- (XVimRegisterOperation)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    if (xregister.isRepeat)
    {
        return (xregister.text.length == 1) ? REGISTER_APPEND : REGISTER_IGNORE;
    }
    
    return [super shouldRecordEvent:event inRegister:xregister];
}

@end

