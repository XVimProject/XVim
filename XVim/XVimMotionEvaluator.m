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
#import "XVimKeyStroke.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimYankEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"



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
        _forceMotionType = NO;
    }
    return self;
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    NSTextView* view = [xvim sourceView];
    NSRange begin = [view selectedRange];
    NSUInteger motionFrom = begin.location;
    
	NSUInteger motionTo = (NSUInteger)[view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    
	return [self _motionFixedFrom:motionFrom To:motionTo Type:type XVim:xvim];
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    TRACE_LOG(@"from:%d to:%d type:%d", from, to, type);
    if( _forceMotionType ){
		if ( type == LINEWISE) {
			type = CHARACTERWISE_EXCLUSIVE;
		} else if ( type == CHARACTERWISE_EXCLUSIVE ){
            type = CHARACTERWISE_INCLUSIVE;
        } else if(type == CHARACTERWISE_INCLUSIVE) {
            type = CHARACTERWISE_EXCLUSIVE;
        }
   }    
    return [self motionFixedFrom:from To:to Type:type XVim:xvim];
}

// Methods to override by subclass
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    return nil;
}


////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] wordsBackward:from count:[self numericArg] option:MOTION_OPTION_NONE];
	return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)B:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] wordsBackward:from count:[self numericArg] option:BIGWORD];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

/*
// Since Ctrl-b, Ctrl-d is not "motion" but "scroll" 
// they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_b:(XVim*)xvim{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}
 
*/

- (XVimEvaluator*)e:(XVim*)xvim{
    NSUInteger realCount = [self numericArg];

    XVimWordInfo info;
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSString *string = [[xvim sourceView] string];
    if (from + 1 < [string length] && from > 0){
        unichar curChar = [[[xvim sourceView] string] characterAtIndex:from];
        unichar nextChar = [[[xvim sourceView] string] characterAtIndex:from+1];
        if( [[xvim sourceView] isBlankLine:from] || (isNonBlank(curChar) != isNonBlank(nextChar)) || (isKeyword(curChar) != isKeyword(nextChar)) || (isWhiteSpace(curChar) && isWhiteSpace(nextChar))){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[xvim sourceView] wordsForward:from count:realCount option:MOTION_OPTION_NONE info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)E:(XVim*)xvim{
    NSUInteger realCount = [self numericArg];
    
    XVimWordInfo info;
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSString *string = [[xvim sourceView] string];
    if (from + 1 < [string length]){
        unichar curChar = [[[xvim sourceView] string] characterAtIndex:from];
        unichar nextChar = [[[xvim sourceView] string] characterAtIndex:from+1];
        if (!isNonBlank(curChar) || !isNonBlank(nextChar)){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[xvim sourceView] wordsForward:from count:realCount option:BIGWORD info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)f:(XVim*)xvim{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = NO;
    return eval;
}

- (XVimEvaluator*)F:(XVim*)xvim{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = NO;
    return eval;
}

/*
 // Since Ctrl-f is not "motion" but "scroll" 
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
- (XVimEvaluator*)C_f:(XVim*)xvim{
    return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
}
*/

- (XVimEvaluator*)g:(XVim*)xvim{
    return [[XVimGEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)G:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSUInteger end;
    if( [self numericMode] ){
        end = [view positionAtLineNumber:[self numericArg] column:0];
    }else{
        end = [view headOfLine:[[view string] length]];
        if( NSNotFound == end ){
            end = [[view string] length];
        }
    }
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
}

- (XVimEvaluator*)h:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] prev:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)H:(XVim*)xvim{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)j:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger column = [[xvim sourceView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[xvim sourceView] nextLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)k:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger column = [[xvim sourceView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[xvim sourceView] prevLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)l:(XVim*)xvim{
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] next:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)L:(XVim*)xvim{
    return [self commonMotion:@selector(cursorBottom:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)M:(XVim*)xvim{
    return [self commonMotion:@selector(cursorCenter:) Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)n:(XVim*)xvim{
    [xvim searchNext];
    return nil;
}

- (XVimEvaluator*)N:(XVim*)xvim{
    [xvim searchPrevious];
    return nil;
}

/*
// Since Ctrl-u is not "motion" but "scroll" 
// it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_u:(XVim*)xvim{
    // This should not be implemneted here
}
*/

- (XVimEvaluator*)t:(XVim*)xvim{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T:(XVim*)xvim{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)v:(XVim*)xvim{
    _forceMotionType = !_forceMotionType;
    return self;
}

- (XVimEvaluator*)w:(XVim*)xvim{
    XVimWordInfo info;
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)W:(XVim*)xvim{
    XVimWordInfo info;
    NSUInteger from = [[xvim sourceView] selectedRange].location;
    NSUInteger to = [[xvim sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)z:(XVim*)xvim{
    return [[XVimZEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)NUM0:(XVim*)xvim{
    NSRange begin = [[xvim sourceView] selectedRange];
    NSUInteger end = [[xvim sourceView] headOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)ASTERISK:(XVim*)xvim{
    NSRange found;
    for (NSUInteger i = 0; i < self.numericArg && found.location != NSNotFound; ++i){
        found = [xvim.searcher searchCurrentWord:YES matchWholeWord:YES];
    }
    
    if (NSNotFound == found.location){
        [xvim errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }

    //Move cursor and show the found string
    NSRange begin = [[xvim sourceView] selectedRange];
    [[xvim sourceView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[xvim sourceView] scrollToCursor];
    [[xvim sourceView] showFindIndicatorForRange:found];

    return [self motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)NUMBER:(XVim*)xvim{
    NSRange found;
    for (NSUInteger i = 0; i < self.numericArg && found.location != NSNotFound; ++i){
        found = [xvim.searcher searchCurrentWord:NO matchWholeWord:YES];
    }
    
    if (NSNotFound == found.location){
        [xvim errorMessage:[NSString stringWithFormat: @"Cannot find '%@'",xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }
    
    //Move cursor and show the found string
    NSRange begin = [[xvim sourceView] selectedRange];
    [[xvim sourceView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[xvim sourceView] scrollToCursor];
    [[xvim sourceView] showFindIndicatorForRange:found];
    
    return [self motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE:(XVim*)xvim{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETOSTARTOFLINE xvimTarget:xvim];
}

- (XVimEvaluator*)BACKQUOTE:(XVim*)xvim{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETO xvimTarget:xvim];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange r = [view selectedRange];
    NSUInteger head = [view headOfLineWithoutSpaces:r.location];
    if( NSNotFound == head ){
        head = r.location;
    }
    return [self _motionFixedFrom:r.location To:head Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)DOLLAR:(XVim*)xvim{
    NSRange begin = [[xvim sourceView] selectedRange];
    NSUInteger end = [[xvim sourceView] endOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)PERCENT:(XVim*)xvim {
    // find matching bracketing character and go to it
    // as long as the nesting level matches up
    NSTextView* view = [xvim sourceView];
    NSString* s = [[view textStorage] string];
    NSRange at = [view selectedRange]; 
    if (at.location >= s.length-1) {
        // [xvim statusMessage:@"leveled match not found" :ringBell TRUE]
        [xvim ringBell];
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
        // [xvim statusMessage:@"Not a match character" :ringBell TRUE]
        [xvim ringBell];
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
        // [xvim statusMessage:@"leveled match not found" :ringBell TRUE]
        [xvim ringBell];
        return self;
    }

    return [self _motionFixedFrom:at.location To:search.location Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
}

/* 
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SPACE:(XVim*)xvim{
    return [self l:xvim];
}

/* 
 * Delete (DEL) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)DEL:(XVim*)xvim{
    return [self h:xvim];
}

- (XVimEvaluator*)PLUS:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange r = [view selectedRange];
    NSUInteger to = [view nextLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE XVim:xvim];
}
/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(XVim*)xvim{
    return [self PLUS:xvim];
}

- (XVimEvaluator*)MINUS:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange r = [view selectedRange];
    NSUInteger to = [view prevLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE XVim:xvim];
}


- (XVimEvaluator*)LSQUAREBRACKET:(XVim*)xvim{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET:(XVim*)xvim{
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
- (XVimEvaluator*)LBRACE:(XVim*)xvim{ // {
    NSTextView* view = [xvim sourceView];
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
    
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)RBRACE:(XVim*)xvim{ // }
    NSTextView* view = [xvim sourceView];
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
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
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
- (XVimEvaluator*)LPARENTHESIS:(XVim*)xvim{ // (
    NSTextView* view = [xvim sourceView];
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
        return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
    }else{
        // no movement
        return nil;
    }
    
    
}

- (XVimEvaluator*)RPARENTHESIS:(XVim*)xvim{ // )
    NSTextView* view = [xvim sourceView];
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
    return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)COMMA:(XVim*)xvim{
    NSTextView *view = [xvim sourceView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [xvim searchCharacterPrevious:location];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([xvim shouldSearchPreviousCharacter]){
            if ([xvim shouldSearchCharacterBackward]){
                location +=1;
            }else{
                location -= 1;
            }
        }
    }
    
    if (location == NSNotFound){
        [xvim ringBell];
    }else{
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        if( ![xvim shouldSearchCharacterBackward]  ){
            // If the last search was forward "comma" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type XVim:xvim]; 
    }

    return nil;
}

- (XVimEvaluator*)SEMICOLON:(XVim*)xvim{
    NSTextView *view = [xvim sourceView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [xvim searchCharacterNext:location];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([xvim shouldSearchPreviousCharacter]){
            if ([xvim shouldSearchCharacterBackward]){
                location -= 1;
            }else{
                location +=1;
            }
        }
    }
    
    if (location == NSNotFound){
        [xvim ringBell];
    }else{
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        if( [xvim shouldSearchCharacterBackward]  ){
            // If the last search was backward "semicolon" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type XVim:xvim]; 
    }
    return nil;
}

- (XVimEvaluator*)Up:(XVim*)xvim{
    return [self k:(XVim*)xvim];
}

- (XVimEvaluator*)Down:(XVim*)xvim{
    return [self j:(XVim*)xvim];
}

- (XVimEvaluator*)Left:(XVim*)xvim{
    return [self h:(XVim*)xvim];
}

- (XVimEvaluator*)Right:(XVim*)xvim{
    return [self l:(XVim*)xvim];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if (xregister.isRepeat){
        if (xregister.nonNumericKeyCount == 1){
            if([keyStroke classResponds:[XVimMotionEvaluator class]] || keyStroke.isNumeric){
                return REGISTER_APPEND;
            }
        }

        return REGISTER_IGNORE;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
