//
//  XVimMotionEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "XVimSearchLineEvaluator.h"
#import "XVimGMotionEvaluator.h"
#import "XVimZEvaluator.h"
#import "XVimMarkMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "XVimCharacterSearch.h"
#import "Logger.h"
#import "XVimYankEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "NSString+VimHelper.h"



////////////////////////////////
// How to Implement Motion    //
////////////////////////////////

// On each key input calculate beginning and end of motion and call _motionFixedFrom:To:Type method (not motionFixedFrom:To:Type).
// It automatically treat switching inclusive/exclusive motion by 'v'.
// How the motion is treated depends on a subclass of the XVimMotionEvaluator.
// For example, XVimDeleteEvaluator will delete the letters represented by motion.

@interface XVimMotionEvaluator() {
    NSUInteger _motionFrom;
    NSUInteger _motionTo;
	NSUInteger _column;
	BOOL _preserveColumn;
	BOOL _forceMotionType;
}
@end

@implementation XVimMotionEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
{
    self = [super initWithContext:context];
    if (self) {
        _forceMotionType = NO;
		_column = NSNotFound;
    }
    return self;
}

- (NSUInteger)column
{
	return _column;
}

- (void)setColumnInWindow:(XVimWindow*)window
{
	if (!_preserveColumn)
	{
		_column = [[window sourceView] columnNumber:[self insertionPointInWindow:window]]; // TODO: Keep column somewhere else
	}
	_preserveColumn = NO;
}

- (void)preserveColumn
{
	_preserveColumn = YES;
}

- (void)becameHandlerInWindow:(XVimWindow*)window
{
	[super becameHandlerInWindow:window];
	
	if (_column == NSNotFound) {
		[self setColumnInWindow:window];
	}
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
    XVimSourceView* view = [window sourceView];
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
	
	XVimEvaluator *ret = [self motionFixedFrom:from To:to Type:type inWindow:window];
	[self setColumnInWindow:window];
	
	return ret;
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
    info.findEndOfWord = TRUE;
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSString *string = [[window sourceView] string];
    if (from + 1 < [string length] && from > 0){
        unichar curChar = [[[window sourceView] string] characterAtIndex:from];
        unichar nextChar = [[[window sourceView] string] characterAtIndex:from+1];
        if( [[window sourceView] isBlankLine:from]              ||  // blank line
            (isNonBlank(curChar) != isNonBlank(nextChar))       ||  // next character is different than current
            (isKeyword(curChar) != isKeyword(nextChar))         ||  // character != punctuation
            (isWhiteSpace(curChar) && isWhiteSpace(nextChar))   ||  // both are whitespace.
            (isWhiteSpace(curChar) && isNewLine(nextChar))){        // whitespace and newline
            // Increase count by one such that the last end of word is properly set
            realCount += 1;
        }
    }
    NSUInteger to = [[window sourceView] wordsForward:from count:realCount option:MOTION_OPTION_NONE info:&info];
    if (info.isFirstWordInALine && info.lastEndOfLine != NSNotFound) {
        to = info.lastEndOfLine;
    } else if (info.lastEndOfWord != NSNotFound) {
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
    if (info.isFirstWordInALine && info.lastEndOfLine != NSNotFound) {
        to = info.lastEndOfLine;
    } else if (info.lastEndOfWord != NSNotFound) {
        to = info.lastEndOfWord;
    }
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_INCLUSIVE inWindow:window];
}

- (XVimEvaluator*)f:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"f"]
																			  parent:self];
    eval.forward = YES;
    eval.previous = NO;
    return eval;
}

- (XVimEvaluator*)F:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"F"]
																			  parent:self];
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
    return [[XVimGMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"g"]
																					 parent:self];
}

- (XVimEvaluator*)G:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSUInteger end;
    if( [self numericMode] ){
        end = [view positionAtLineNumber:[self numericArg] column:0];
		if (end == NSNotFound) {
			end = [view firstOfLine:[[view string] length]];
		}
    }else{
        end = [view headOfLine:[[view string] length]];
        if( NSNotFound == end ){
            end = [[view string] length];
        }
    }
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)h:(XVimWindow*)window
{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger to = [[window sourceView] prev:from count:[self numericArg] option:LEFT_RIGHT_NOWRAP];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)H:(XVimWindow*)window{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)j:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger column = [self column];
	[self preserveColumn];
	
    NSUInteger to = [[window sourceView] nextLine:from column:column count:[self numericArg] option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:from To:to Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    NSUInteger from = [[window sourceView] selectedRange].location;
    NSUInteger column = [self column];
	[self preserveColumn];
	
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
    NSRange r = [searcher searchNextFrom:[window insertionPoint] inWindow:window];
	[searcher selectSearchResult:r inWindow:window];
    return nil;
}

- (XVimEvaluator*)N:(XVimWindow*)window{
	XVimSearch* searcher = [[XVim instance] searcher];
    NSRange r = [searcher searchPrevFrom:[window insertionPoint] inWindow:window];
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
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"t"]
																												 parent:self];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"T"]
																												 parent:self];
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
    return [[XVimZEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"z"]
																			   parent:self];
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
	
	NSUInteger cursorLocation = [window insertionPoint];
	NSUInteger searchLocation = cursorLocation;
    NSRange found=NSMakeRange(0, 0);
    for (NSUInteger i = 0; i < [self numericArg] && found.location != NSNotFound; ++i){
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
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"'"]
													 parent:self
											   markOperator:MARKOPERATOR_MOVETOSTARTOFLINE];
}

- (XVimEvaluator*)BACKQUOTE:(XVimWindow*)window{
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"`"] 
													 parent:self
											   markOperator:MARKOPERATOR_MOVETO];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger head = [view headOfLineWithoutSpaces:r.location];
    if( NSNotFound == head ){
        head = r.location;
    }
    return [self _motionFixedFrom:r.location To:head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

// Underscore ( "_") moves the cursor to the start of the line (past leading whitespace)
// Note: underscore without any numeric arguments behaves like caret but with a numeric argument greater than 1
// it will moves to start of the numeric argument - 1 lines down.
- (XVimEvaluator*)UNDERSCORE:(XVimWindow*)window{
    XVimSourceView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger repeat = [[self context] numericArg];
    NSUInteger linesUpCursorloc = [view nextLine:r.location column:0 count:(repeat - 1) option:MOTION_OPTION_NONE];
    NSUInteger head = [view headOfLineWithoutSpaces:linesUpCursorloc];
    if( NSNotFound == head && linesUpCursorloc != NSNotFound){
        head = linesUpCursorloc;
    }else if(NSNotFound == head){
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
    XVimSourceView* view = [window sourceView];
    NSString* s = [view string];
    NSRange at = [view selectedRange]; 
    if (at.location >= s.length-1) {
        // [window statusMessage:@"leveled match not found" :ringBell TRUE]
        [[XVim instance] ringBell];
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
        [[XVim instance] ringBell];
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
        [[XVim instance] ringBell];
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
    XVimSourceView* view = [window sourceView];
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
    XVimSourceView* view = [window sourceView];
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

- (XVimEvaluator*)LBRACE:(XVimWindow*)window{ // {
    XVimSourceView* view = [window sourceView];
    NSUInteger begin = [view selectedRange].location;
    NSUInteger paragraph_head = [view paragraphsBackward:begin count:[self numericArg] option:MOTION_OPTION_NONE];
	
	if (paragraph_head != NSNotFound)
	{
		return [self _motionFixedFrom:begin To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
	}
	return nil;
}

- (XVimEvaluator*)RBRACE:(XVimWindow*)window{ // }
    XVimSourceView* view = [window sourceView];
    NSUInteger begin = [view selectedRange].location;
    NSUInteger paragraph_head = [view paragraphsForward:begin count:[self numericArg] option:MOTION_OPTION_NONE];
	
	if (paragraph_head != NSNotFound)
	{
		return [self _motionFixedFrom:begin To:paragraph_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
	}
	return nil;
}


- (XVimEvaluator*)LPARENTHESIS:(XVimWindow*)window{ // (
    XVimSourceView* view = [window sourceView];
    NSUInteger begin = [view selectedRange].location;
    NSUInteger sentence_head = [view sentencesBackward:begin count:[self numericArg]option:MOTION_OPTION_NONE];
    if( NSNotFound != sentence_head  ){
        return [self _motionFixedFrom:begin To:sentence_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
    }else{
        return nil;
    }
}

- (XVimEvaluator*)RPARENTHESIS:(XVimWindow*)window{ // )
    XVimSourceView* view = [window sourceView];
    NSUInteger begin = [view selectedRange].location;
    NSUInteger sentence_head = [view sentencesForward:begin count:[self numericArg]option:MOTION_OPTION_NONE];
    if( NSNotFound != sentence_head  ){
        return [self _motionFixedFrom:begin To:sentence_head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
    }else{
        return nil;
    }
}

- (XVimEvaluator*)COMMA:(XVimWindow*)window{
	XVimCharacterSearch* charSearcher = [[XVim instance] characterSearcher];
    XVimSourceView *view = [window sourceView];
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
        [[XVim instance]ringBell];
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
    XVimSourceView *view = [window sourceView];
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
        [[XVim instance] ringBell];
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

-(XVimEvaluator*)Home:(XVimWindow*)window{
    return [self NUM0:(XVimWindow*)window];
}

-(XVimEvaluator*)End:(XVimWindow*)window{
    return [self DOLLAR:(XVimWindow*)window];
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


