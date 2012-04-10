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
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "XVimCharacterSearch.h"
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
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    NSTextView* view = [window sourceView];
    NSRange begin = [view selectedRange];
    NSUInteger motionFrom = begin.location;
    
	NSUInteger motionTo = (NSUInteger)[view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    
	return [self _motionFixedFrom:motionFrom To:motionTo Type:type inWindow:window];
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
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
    return [self motionFixedFrom:from To:to Type:type inWindow:window];
}

// Methods to override by subclass
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    return nil;
}


////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsBackward:from count:[self numericArg] option:MOTION_OPTION_NONE];
	return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsBackward:from count:[self numericArg] option:BIGWORD];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

/*
// Since Ctrl-b, Ctrl-d is not "motion" but "scroll" 
// they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_b:(XVimWindow*)window{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}
 
*/

- (XVimEvaluator*)e:(XVimWindow*)window{
    NSUInteger realCount = [self numericArg];

    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSString *string = [[window sourceView] string];
    if (from + 1 < [string length] && from > 0){
        unichar curChar = [[[window sourceView] string] characterAtIndex:from];
        unichar nextChar = [[[window sourceView] string] characterAtIndex:from+1];
        if( [[window sourceView] isBlankLine:from] || (isNonBlank(curChar) != isNonBlank(nextChar)) || (isKeyword(curChar) != isKeyword(nextChar)) || (isWhiteSpace(curChar) && isWhiteSpace(nextChar))){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[window sourceView] wordsForward:from count:realCount option:MOTION_OPTION_NONE info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)E:(XVimWindow*)window{
    NSUInteger realCount = [self numericArg];
    
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSString *string = [[window sourceView] string];
    if (from + 1 < [string length]){
        unichar curChar = [[[window sourceView] string] characterAtIndex:from];
        unichar nextChar = [[[window sourceView] string] characterAtIndex:from+1];
        if (!isNonBlank(curChar) || !isNonBlank(nextChar)){
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[window sourceView] wordsForward:from count:realCount option:BIGWORD info:&info];
    if (info.isFirstWordInALine){
        to = info.lastEndOfLine;
    }else if( info.lastEndOfWord != NSNotFound){
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)f:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = NO;
    return eval;
}

- (XVimEvaluator*)F:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = NO;
    return eval;
}

/*
 // Since Ctrl-f is not "motion" but "scroll" 
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
- (XVimEvaluator*)C_f:(XVimWindow*)window{
    return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
}
*/

- (XVimEvaluator*)g:(XVimWindow*)window{
    return [[XVimGEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)G:(XVimWindow*)window{
    NSTextView* view = [window sourceView];
    NSUInteger end;
    if( [self numericMode] ){
        end = [view positionAtLineNumber:[self numericArg] column:0];
    }else{
        end = [view headOfLine:[[view string] length]];
        if( NSNotFound == end ){
            end = [[view string] length];
        }
    }
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)h:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] prev:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)H:(XVimWindow*)window{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)j:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger column = [[window sourceView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[window sourceView] nextLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger column = [[window sourceView] columnNumber:from]; // TODO: Keep column somewhere else
    NSUInteger to = [[window sourceView] prevLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)l:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] next:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)L:(XVimWindow*)window{
    return [self commonMotion:@selector(cursorBottom:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)M:(XVimWindow*)window{
    return [self commonMotion:@selector(cursorCenter:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)n:(XVimWindow*)window{
	XVimSearch* searcher = [[XVim instance] searcher];
    NSRange r = [searcher searchNextFrom:[window cursorLocation] inWindow:window];
	[searcher selectSearchResult:r inWindow:window];
    return nil;
}

- (XVimEvaluator*)N:(XVimWindow*)window{
	XVimSearch* searcher = [[XVim instance] searcher];
    NSRange r = [searcher searchPrevFrom:[window cursorLocation] inWindow:window];
	[searcher selectSearchResult:r inWindow:window];
    return nil;
}

/*
// Since Ctrl-u is not "motion" but "scroll" 
// it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_u:(XVimWindow*)window{
    // This should not be implemneted here
}
*/

- (XVimEvaluator*)t:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
    eval.forward = NO;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    _forceMotionType = !_forceMotionType;
    return self;
}

- (XVimEvaluator*)w:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:MOTION_OPTION_NONE info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)W:(XVimWindow*)window{
    XVimWordInfo info;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] wordsForward:from count:[self numericArg] option:BIGWORD info:&info];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)z:(XVimWindow*)window{
    return [[XVimZEvaluator alloc] initWithMotionEvaluator:self withRepeat:[self numericArg]];
}

- (XVimEvaluator*)NUM0:(XVimWindow*)window{
    NSRange begin = [[window sourceView] selectedRange];
    NSUInteger end = [[window sourceView] headOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)searchCurrentWordInWindow:(XVimWindow*)window forward:(BOOL)forward {
	XVimSearch* searcher = [[XVim instance] searcher];
	
	NSUInteger cursorLocation = [window cursorLocation];
	NSUInteger searchLocation = cursorLocation;
    NSRange found;
    for (NSUInteger i = 0; i < self.numericArg && found.location != NSNotFound; ++i){
        found = [searcher searchCurrentWordFrom:searchLocation forward:forward matchWholeWord:YES inWindow:window];
		searchLocation = found.location;
    }
	
	if (![searcher selectSearchResult:found inWindow:window])
	{
		return nil;
	}
    
	return [self motionFixedFrom:cursorLocation To:found.location Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)ASTERISK:(XVimWindow*)window{
	return [self searchCurrentWordInWindow:window forward:YES];
}

- (XVimEvaluator*)NUMBER:(XVimWindow*)window{
	return [self searchCurrentWordInWindow:window forward:NO];
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE:(XVimWindow*)window{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETOSTARTOFLINE];
}

- (XVimEvaluator*)BACKQUOTE:(XVimWindow*)window{
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_MOVETO];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(XVimWindow*)window{
    NSTextView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger head = [view headOfLineWithoutSpaces:r.location];
    if( NSNotFound == head ){
        head = r.location;
    }
    return [self _motionFixedFrom:r.location To:head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)DOLLAR:(XVimWindow*)window{
    NSRange begin = [[window sourceView] selectedRange];
    NSUInteger end = [[window sourceView] endOfLine:begin.location];
    if( NSNotFound == end ){
        return nil;
    }
    return [self _motionFixedFrom:begin.location To:end Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)PERCENT:(XVimWindow*)window {
    // find matching bracketing character and go to it
    // as long as the nesting level matches up
    NSTextView* view = [window sourceView];
    NSString* s = [[view textStorage] string];
    NSRange at = [view selectedRange]; 
    if (at.location >= s.length-1) {
        // [window statusMessage:@"leveled match not found" :ringBell TRUE]
        [window ringBell];
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
        // [window statusMessage:@"Not a match character" :ringBell TRUE]
        [window ringBell];
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
        // [window statusMessage:@"leveled match not found" :ringBell TRUE]
        [window ringBell];
        return self;
    }

    return [self _motionFixedFrom:at.location To:search.location Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

/* 
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SPACE:(XVimWindow*)window{
    return [self l:window];
}

/* 
 * Delete (DEL) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)DEL:(XVimWindow*)window{
    return [self h:window];
}

- (XVimEvaluator*)PLUS:(XVimWindow*)window{
    NSTextView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger to = [view nextLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE inWindow:window];
}
/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(XVimWindow*)window{
    return [self PLUS:window];
}

- (XVimEvaluator*)MINUS:(XVimWindow*)window{
    NSTextView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger to = [view prevLine:r.location column:0 count:[self numericArg] option:MOTION_OPTION_NONE];
    NSUInteger to_wo_space= [view nextNonBlankInALine:to];
    if( NSNotFound != to_wo_space){
        to = to_wo_space;
    }
    return [self _motionFixedFrom:r.location To:to Type:LINEWISE inWindow:window];
}


- (XVimEvaluator*)LSQUAREBRACKET:(XVimWindow*)window{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET:(XVimWindow*)window{
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
- (XVimEvaluator*)LBRACE:(XVimWindow*)window{ // {
    NSTextView* view = [window sourceView];
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
    
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)RBRACE:(XVimWindow*)window{ // }
    NSTextView* view = [window sourceView];
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
    return [self _motionFixedFrom:begin.location To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
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
- (XVimEvaluator*)LPARENTHESIS:(XVimWindow*)window{ // (
    NSTextView* view = [window sourceView];
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
        return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
    }else{
        // no movement
        return nil;
    }
    
    
}

- (XVimEvaluator*)RPARENTHESIS:(XVimWindow*)window{ // )
    NSTextView* view = [window sourceView];
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
    return [self _motionFixedFrom:begin.location To:sentence_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)COMMA:(XVimWindow*)window{
	XVimCharacterSearch* charSearcher = [[XVim instance] characterSearcher];
    NSTextView *view = [window sourceView];
    NSUInteger location = [view selectedRange].location;
    
	for (NSUInteger i = 0;;) {
        location = [charSearcher searchPrevCharacterFrom:location inWindow:window];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([charSearcher shouldSearchPreviousCharacter]){
            if ([charSearcher shouldSearchCharacterBackward]){
                location +=1;
            }else{
                location -= 1;
            }
        }
    }
    
    if (location == NSNotFound){
        [window ringBell];
    }else{
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        if( ![charSearcher shouldSearchCharacterBackward]  ){
            // If the last search was forward "comma" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type inWindow:window]; 
    }

    return nil;
}

- (XVimEvaluator*)SEMICOLON:(XVimWindow*)window
{
	XVimCharacterSearch* charSearcher = [[XVim instance] characterSearcher];
    NSTextView *view = [window sourceView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [charSearcher searchNextCharacterFrom:location inWindow:window];
        if (location == NSNotFound || ++i >= [self numericArg]){
            break;
        }
        
        if ([charSearcher shouldSearchPreviousCharacter]){
            if ([charSearcher shouldSearchCharacterBackward]){
                location -= 1;
            }else{
                location +=1;
            }
        }
    }
    
    if (location == NSNotFound){
        [window ringBell];
    }else{
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        // If its 'F' or 'T' motion the motion type is CHARACTERWISE_EXCLUSIVE
        if( [charSearcher shouldSearchCharacterBackward]  ){
            // If the last search was backward "semicolon" is backward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type inWindow:window]; 
    }
    return nil;
}

- (XVimEvaluator*)Up:(XVimWindow*)window{
    return [self k:(XVimWindow*)window];
}

- (XVimEvaluator*)Down:(XVimWindow*)window{
    return [self j:(XVimWindow*)window];
}

- (XVimEvaluator*)Left:(XVimWindow*)window{
    return [self h:(XVimWindow*)window];
}

- (XVimEvaluator*)Right:(XVimWindow*)window{
    return [self l:(XVimWindow*)window];
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
