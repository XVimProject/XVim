
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

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:(XVimWindow *)window{
    self = [super initWithContext:context withWindow:window];
    if (self) {
        _forceMotionType = NO;
    }
    return self;
}

- (void)becameHandlerInWindow{
	[super becameHandler];
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type{
    XVimSourceView* view = [self sourceView];
	NSUInteger motionTo = (NSUInteger)[view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, type, MOTION_OPTION_NONE, [self numericArg]);
    m.position = motionTo;
    return [self _motionFixed:m];
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
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
	
	XVimEvaluator *ret = [self motionFixedFrom:from To:to Type:type];
	return ret;
}

-(XVimEvaluator*)_motionFixed:(XVimMotion*)motion{
    if( _forceMotionType ){
		if ( motion.type == LINEWISE) {
			motion.type = CHARACTERWISE_EXCLUSIVE;
		} else if ( motion.type == CHARACTERWISE_EXCLUSIVE ){
            motion.type = CHARACTERWISE_INCLUSIVE;
        } else if(motion.type == CHARACTERWISE_INCLUSIVE) {
            motion.type = CHARACTERWISE_EXCLUSIVE;
        }
	}
	return [self motionFixed:motion];
}

// Methods to override by subclass
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    return nil;
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion{
    return nil;
}

////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)B{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_BACKWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, [self numericArg])];
}

/*
 // Since Ctrl-b, Ctrl-d is not "motion" but "scroll"
 // Do not implement it here. they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 */

- (XVimEvaluator*)e{
    XVimMotion* motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_FORWARD, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:motion];
}

- (XVimEvaluator*)E{
    XVimMotion* motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_FORWARD, CHARACTERWISE_INCLUSIVE, BIGWORD, [self numericArg]);
    return [self _motionFixed:motion];
}

- (XVimEvaluator*)f{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"f"] withWindow:self.window withParent:self];
    eval.forward = YES;
    eval.previous = NO;
    return eval;
}

- (XVimEvaluator*)F{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"F"] withWindow:self.window withParent:self];
    eval.forward = NO;
    eval.previous = NO;
    return eval;
}

/*
 // Since Ctrl-f is not "motion" but "scroll"
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 - (XVimEvaluator*)C_f{
 return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
 }
 */

- (XVimEvaluator*)g{
    return [[XVimGMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"g"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)G{
    XVimMotion* m =XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, LEFT_RIGHT_NOWRAP, [self numericArg]);
    if([self numericMode]){
        m.line = [self numericArg];
    }else{
        m.motion = MOTION_LASTLINE;
    }
    return [self _motionFixed:m];
}

- (XVimEvaluator*)h{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BACKWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg])];
}

- (XVimEvaluator*)H{
    return [self commonMotion:@selector(cursorTop:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)j{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)k{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)l{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg])];
}

- (XVimEvaluator*)L{
    return [self commonMotion:@selector(cursorBottom:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)M{
    return [self commonMotion:@selector(cursorCenter:) Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)n{
	XVimSearch* searcher = [[XVim instance] searcher];
    NSRange r = [searcher searchNextFrom:[self.window insertionPoint] inWindow:self.window];
	[searcher selectSearchResult:r inWindow:self.window];
    return nil;
}

- (XVimEvaluator*)N{
	XVimSearch* searcher = [[XVim instance] searcher];
    NSRange r = [searcher searchPrevFrom:[self.window insertionPoint] inWindow:self.window];
	[searcher selectSearchResult:r inWindow:self.window];
    return nil;
}

/*
 // Since Ctrl-u is not "motion" but "scroll"
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
 - (XVimEvaluator*)C_u{
 // This should not be implemneted here
 }
 */

- (XVimEvaluator*)t{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"t"] withWindow:self.window withParent:self];
    eval.forward = YES;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)T{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"T"] withWindow:self.window withParent:self];
    eval.forward = NO;
    eval.previous = YES;
    return eval;
}

- (XVimEvaluator*)v{
    _forceMotionType = !_forceMotionType;
    return self;
}

- (XVimEvaluator*)w{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)W{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, [self numericArg])];
}

- (XVimEvaluator*)z{
    return [[XVimZEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"z"] withWindow:self.window withParent:self];
}

- (XVimEvaluator*)NUM0{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BEGINNING_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)searchCurrentWordInWindow:(XVimWindow*)window forward:(BOOL)forward {
	XVimSearch* searcher = [[XVim instance] searcher];
	
	NSUInteger cursorLocation = [window insertionPoint];
	NSUInteger searchLocation = cursorLocation;
    NSRange found=NSMakeRange(0, 0);
    for (NSUInteger i = 0; i < [self numericArg] && found.location != NSNotFound; ++i){
        found = [searcher searchCurrentWordFrom:searchLocation forward:forward matchWholeWord:YES inWindow:self.window];
		searchLocation = found.location;
    }
	
	if (![searcher selectSearchResult:found inWindow:window]) {
		return nil;
	}
    
	return [self motionFixedFrom:cursorLocation To:found.location Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)ASTERISK{
    // FIXME
   // return [self searchCurrentWord:YES];
    return nil;
}

- (XVimEvaluator*)NUMBER{
    // FIXME
	// return [self searchCurrentWord:NO];
    return nil;
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE{
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"'"] withWindow:self.window withParent:self markOperator:MARKOPERATOR_MOVETOSTARTOFLINE];
}

- (XVimEvaluator*)BACKQUOTE{
    return [[XVimMarkMotionEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"`"] withWindow:self.window withParent:self markOperator:MARKOPERATOR_MOVETO];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FIRST_NONBLANK, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)DOLLAR{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)PERCENT:(XVimWindow*)window {
    if( self.numericMode ){
        return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PERCENT, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
    }else{
        return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_NEXT_MATCHED_ITEM, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
    }
}

/*
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SPACE{
    return [self l];
}

/*
 * Delete (DEL) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)DEL{
    return [self h];
}

- (XVimEvaluator*)PLUS{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_NEXT_FIRST_NONBLANK, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}
/*
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR{
    return [self PLUS];
}

- (XVimEvaluator*)MINUS{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PREV_FIRST_NONBLANK, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}


- (XVimEvaluator*)LSQUAREBRACKET{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET{
    // TODO: implement XVimRSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)LBRACE{ // {
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PARAGRAPH_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)RBRACE{ // }
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_PARAGRAPH_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}


- (XVimEvaluator*)LPARENTHESIS{ // (
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_SENTENCE_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)RPARENTHESIS{ // )
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_SENTENCE_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)COMMA{
	XVimCharacterSearch* charSearcher = [[XVim instance] characterSearcher];
    XVimSourceView *view = [self.window sourceView];
    NSUInteger location = [view selectedRange].location;
    
	for (NSUInteger i = 0;;) {
        location = [charSearcher searchPrevCharacterFrom:location inWindow:self.window];
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
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type];
    }
    
    return nil;
}

- (XVimEvaluator*)SEMICOLON{
	XVimCharacterSearch* charSearcher = [[XVim instance] characterSearcher];
    XVimSourceView *view = [self sourceView];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [charSearcher searchNextCharacterFrom:location inWindow:self.window];
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
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type];
    }
    return nil;
}

- (XVimEvaluator*)Up{
    return [self k];
}

- (XVimEvaluator*)Down{
    return [self j];
}

- (XVimEvaluator*)Left{
    return [self h];
}

- (XVimEvaluator*)Right{
    return [self l];
}

-(XVimEvaluator*)Home{
    return [self NUM0];
}

-(XVimEvaluator*)End{
    return [self DOLLAR];
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
