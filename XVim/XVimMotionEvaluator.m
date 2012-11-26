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
	BOOL _forceMotionType;
}
@end

@implementation XVimMotionEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context {
    self = [super initWithContext:context];
    if (self) {
        _forceMotionType = NO;
    }
    return self;
}

- (void)becameHandlerInWindow:(XVimWindow*)window {
	[super becameHandlerInWindow:window];
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window {
    XVimSourceView* view = [window sourceView];
	NSUInteger motionTo = (NSUInteger)[view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, type, MOTION_OPTION_NONE, [self numericArg]);
    m.position = motionTo;
    return [self _motionFixed:m inWindow:window];
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window {
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
	return ret;
}

-(XVimEvaluator*)_motionFixed:(XVimMotion*)motion inWindow:(XVimWindow*)window
{
    if( _forceMotionType ){
		if ( motion.type == LINEWISE) {
			motion.type = CHARACTERWISE_EXCLUSIVE;
		} else if ( motion.type == CHARACTERWISE_EXCLUSIVE ){
            motion.type = CHARACTERWISE_INCLUSIVE;
        } else if(motion.type == CHARACTERWISE_INCLUSIVE) {
            motion.type = CHARACTERWISE_EXCLUSIVE;
        }
	}
	return [self motionFixed:motion inWindow:window];
}

// Methods to override by subclass
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window {
    return nil;
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion inWindow:(XVimWindow*)window{
    return nil;
}

////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)B:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, [self numericArg]) inWindow:window];
}

/*
// Since Ctrl-b, Ctrl-d is not "motion" but "scroll" 
// they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
- (XVimEvaluator*)C_b:(XVimWindow*)window{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}
 
*/

- (XVimEvaluator*)e:(XVimWindow*)window{
    XVimMotion* motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_FORWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:motion inWindow:window];
}

- (XVimEvaluator*)E:(XVimWindow*)window{
    XVimMotion* motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_FORWARD, CHARACTERWISE_INCLUSIVE, BIGWORD, [self numericArg]);
    return [self _motionFixed:motion inWindow:window];
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
    return [[XVimGMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"g"] parent:self];
}

- (XVimEvaluator*)G:(XVimWindow*)window{
    XVimMotion* m =XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, LEFT_RIGHT_NOWRAP, [self numericArg]);
    if([self numericMode]){
        m.line = [self numericArg];
    }else{
        m.motion = MOTION_LASTLINE;
    }
    return [self _motionFixed:m inWindow:window];
}

- (XVimEvaluator*)h:(XVimWindow*)window {
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BACKWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)H:(XVimWindow*)window{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)j:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)l:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg]) inWindow:window];
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
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"t"] parent:self];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T:(XVimWindow*)window{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"T"] parent:self];
    eval.forward = NO;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    _forceMotionType = !_forceMotionType;
    return self;
}

- (XVimEvaluator*)w:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)W:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)z:(XVimWindow*)window{
    return [[XVimZEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"z"] parent:self];
}

- (XVimEvaluator*)NUM0:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BEGINNING_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
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
	
	if (![searcher selectSearchResult:found inWindow:window]) {
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
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"'"] parent:self markOperator:MARKOPERATOR_MOVETOSTARTOFLINE];
}

- (XVimEvaluator*)BACKQUOTE:(XVimWindow*)window{
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"`"] parent:self markOperator:MARKOPERATOR_MOVETO];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FIRST_NONBLANK, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
    XVimSourceView* view = [window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger head = [view headOfLineWithoutSpaces:r.location];
    if( NSNotFound == head ){
        head = r.location;
    }
    return [self _motionFixedFrom:r.location To:head Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)DOLLAR:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)PERCENT:(XVimWindow*)window {
    if( self.numericMode ){
       return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PERCENT, LINEWISE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
    }else{
       return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_NEXT_MATCHED_ITEM, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
    }
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
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_NEXT_FIRST_NONBLANK, LINEWISE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}
/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(XVimWindow*)window{
    return [self PLUS:window];
}

- (XVimEvaluator*)MINUS:(XVimWindow*)window{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PREV_FIRST_NONBLANK, LINEWISE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
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
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PARAGRAPH_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)RBRACE:(XVimWindow*)window{ // }
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PARAGRAPH_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}


- (XVimEvaluator*)LPARENTHESIS:(XVimWindow*)window{ // (
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_SENTENCE_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
}

- (XVimEvaluator*)RPARENTHESIS:(XVimWindow*)window{ // )
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_SENTENCE_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg]) inWindow:window];
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