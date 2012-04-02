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
#import "NSTextView+VimMotion.h"



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
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsBackward:from count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)B:(id)arg{
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsBackward:from count:[self numericArg] option:BIGWORD];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

/*
// Since Ctrl-b, Ctrl-d is not "motion" but "scroll" 
// they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_b:(id)arg{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}
 
*/

- (XVimEvaluator*)e:(id)arg{
    NSUInteger realCount = [self numericArg];

    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSString *string = [[self textView] string];
    if (from + 1 < [string length] && from > 0){
        unichar lastChar = [[[self textView] string] characterAtIndex:from-1];
        unichar curChar = [[[self textView] string] characterAtIndex:from];
        unichar nextChar = [[[self textView] string] characterAtIndex:from+1];
        if( [[self textView] isBlankLine:from] || (isNonBlank(curChar) != isNonBlank(nextChar)) || (isKeyword(curChar) != isKeyword(nextChar)) || (isWhiteSpace(curChar) && isWhiteSpace(nextChar))){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[self textView] wordsForward:from count:realCount option:MOTION_OPTION_NONE info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)E:(id)arg{
    NSUInteger realCount = [self numericArg];
    
    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSString *string = [[self textView] string];
    if (from + 1 < [string length]){
        unichar curChar = [[[self textView] string] characterAtIndex:from];
        unichar nextChar = [[[self textView] string] characterAtIndex:from+1];
        if (!isNonBlank(curChar) || !isNonBlank(nextChar)){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[self textView] wordsForward:from count:realCount option:BIGWORD info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)f:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = NO;
    return eval;
}

- (XVimEvaluator*)F:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = NO;
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
    NSUInteger end;
    if( [self numericMode] ){
        end = [view positionAtLineNumber:[self numericArg] column:0];
    }else{
        end = [view headOfLine:[[view string] length]];
        if( NSNotFound == end ){
            end = [[view string] length];
        }
    }
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}

- (XVimEvaluator*)h:(id)arg{
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] prev:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)H:(id)arg{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)j:(id)arg{
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger column = [[self textView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[self textView] nextLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)k:(id)arg{
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger column = [[self textView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[self textView] prevLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)l:(id)arg{
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] next:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
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
    // This should not be implemneted here
}
*/

- (XVimEvaluator*)t:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)v:(id)arg{
    _inverseMotionType = !_inverseMotionType;
    return self;
}

- (XVimEvaluator*)w:(id)arg{
    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)W:(id)arg{
    XVimWordInfo info;
    NSUInteger from = [[self textView] selectedRange].location;
    NSUInteger to = [[self textView] wordsForward:from count:[self numericArg] option:BIGWORD info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)z:(id)arg{
    return [[XVimZEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)NUM0:(id)arg{
    NSRange begin = [[self textView] selectedRange];
    NSUInteger end = [[self textView] headOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)ASTERISK:(id)arg{
    NSTextView *view = [self textView];

    NSRange begin = [view selectedRange];
    NSString *string = [view string];
    NSUInteger searchStart = begin.location;
    NSUInteger firstNonBlank = NSNotFound;
    while (![view isEOF:searchStart]) {
        unichar curChar = [string characterAtIndex:searchStart];
        if (isNewLine(curChar)){
            searchStart = NSNotFound;
            break;
        }

        if (isKeyword(curChar)){
            break;
        }

        if (isNonBlank(curChar) && firstNonBlank == NSNotFound){
            firstNonBlank = searchStart;
        }

        ++searchStart;
    }

    if (searchStart == NSNotFound){
        searchStart = firstNonBlank;
    }

    if (searchStart == NSNotFound){
        [self.xvim ringBell];
        return nil;
    }

    XVimWordInfo info;
    NSUInteger wordStart = searchStart;
    if (wordStart > 0){
        unichar curChar = [string characterAtIndex:wordStart];
        unichar lastChar = [string characterAtIndex:wordStart-1];
        if ((isKeyword(curChar) && isKeyword(lastChar)) ||
            (!isKeyword(curChar) && isNonBlank(curChar) && !isKeyword(lastChar) && isNonBlank(lastChar))){
            wordStart = [view wordsBackward:searchStart count:1 option:LEFT_RIGHT_NOWRAP];
        }
    }

    NSUInteger wordEnd = [view wordsForward:wordStart count:1 option:LEFT_RIGHT_NOWRAP info:&info];
    if (info.lastEndOfWord != NSNotFound){
        wordEnd = info.lastEndOfWord;
    }

    // Search for the word
    NSRange wordRange = NSMakeRange(wordStart, wordEnd - wordStart + 1);
    NSString *searchWord = [[view string] substringWithRange:wordRange];
    NSString *escapedSearchWord = [NSRegularExpression escapedPatternForString:searchWord];
    [self.xvim commandDetermined:[@"/" stringByAppendingString:escapedSearchWord]];

    if (searchStart != begin.location){
        [[self xvim] searchNext];
    }

    NSRange end = [view selectedRange];
    return [self motionFixedFrom:begin.location To:end.location Type:CHARACTERWISE_EXCLUSIVE];
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
    NSRange r = [view selectedRange];
    NSUInteger head = [view headOfLineWithoutSpaces:r.location];
    if( NSNotFound == head ){
        head = r.location;
    }
    return [self _motionFixedFrom:r.location To:head Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)DOLLAR:(id)arg{
    NSRange begin = [[self textView] selectedRange];
    NSUInteger end = [[self textView] endOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE];
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
    NSUInteger eol = [view endOfLine:at.location];
    if (eol == NSNotFound){
        at.length = 1;
    }else{
        at.length = eol - at.location + 1;
    }

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

    if (search.location == NSNotFound) {
        // [[self xvim] statusMessage:@"leveled match not found" :ringBell TRUE]
        [[self xvim] ringBell];
        return self;
    }

    return [self _motionFixedFrom:at.location To:search.location Type:CHARACTERWISE_INCLUSIVE];
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
    NSRange r = [view selectedRange];
    NSUInteger to = [view nextLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE];
}
/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(id)arg{
    return [self PLUS:arg];
}

- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    NSUInteger to = [view prevLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE];
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

- (XVimEvaluator*)COMMA:(id)arg{
    NSTextView *view = [self textView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [[self xvim] searchCharacterPrevious:location];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([[self xvim] shouldSearchPreviousCharacter]){
            if ([[self xvim] shouldSearchCharacterBackward]){
                location +=1;
            }else{
                location -= 1;
            }
        }
    }
    
    if (location == NSNotFound){
        [[self xvim] ringBell];
    }else{
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        if( ![[self xvim] shouldSearchCharacterBackward]  ){
            // If the last search was forward "comma" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type]; 
    }

    return nil;
}

- (XVimEvaluator*)SEMICOLON:(id)arg{
    NSTextView *view = [self textView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [[self xvim] searchCharacterNext:location];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([[self xvim] shouldSearchPreviousCharacter]){
            if ([[self xvim] shouldSearchCharacterBackward]){
                location -= 1;
            }else{
                location +=1;
            }
        }
    }
    
    if (location == NSNotFound){
        [[self xvim] ringBell];
    }else{
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        if( [[self xvim] shouldSearchCharacterBackward]  ){
            // If the last search was backward "semicolon" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type]; 
    }
    return nil;
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
    if (xregister.isRepeat){
        if (xregister.nonNumericKeyCount == 1){
            NSString *key = [XVimEvaluator keyStringFromKeyEvent:event];
            SEL handler = NSSelectorFromString([key stringByAppendingString:@":"]);
            if([[XVimMotionEvaluator class] instancesRespondToSelector:handler] || [key hasPrefix:@"NUM"]){
                return REGISTER_APPEND;
            }
        }

        return REGISTER_IGNORE;
    }
    
    return [super shouldRecordEvent:event inRegister:xregister];
}

@end