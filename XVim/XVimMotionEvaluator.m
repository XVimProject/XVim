
//
//  XVimMotionEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEKit.h"
#import "XVimMotionEvaluator.h"
#import "XVimGMotionEvaluator.h"
#import "XVimArgumentEvaluator.h"
#import "XVimZEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"
#import "XVimYankEvaluator.h"
#import "NSTextStorage+VimOperation.h"
#import "NSString+VimHelper.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimOptions.h"


////////////////////////////////
// How to Implement Motion    //
////////////////////////////////

// On each key input calculate beginning and end of motion and call _motionFixedFrom:To:Type method (not motionFixedFrom:To:Type).
// It automatically treat switching inclusive/exclusive motion by 'v'.
// How the motion is treated depends on a subclass of the XVimMotionEvaluator.
// For example, XVimDeleteEvaluator will delete the letters represented by motion.



@interface XVimMotionEvaluator() {
    MOTION_TYPE _forcedMotionType;
	BOOL _toggleInclusiveExclusive;
}
@end

@implementation XVimMotionEvaluator
@synthesize motion = _motion;

- (id)initWithWindow:(XVimWindow *)window{
    self = [super initWithWindow:window];
    if (self) {
        _forcedMotionType = DEFAULT_MOTION_TYPE;
        _motion = [XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, 1) retain];
    }
    return self;
}

- (void)dealloc{
    [_motion release];
    [super dealloc];
}

// This is helper method commonly used by many key event handlers.
// You do not need to use this if this is not proper to express the motion.
- (XVimEvaluator*)commonMotion:(SEL)motion Type:(MOTION_TYPE)type{
    NSTextView* view = [self sourceView];
	NSUInteger motionTo = (NSUInteger)[view performSelector:motion withObject:[NSNumber numberWithUnsignedInteger:[self numericArg]]];
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, type, MOTION_OPTION_NONE, [self numericArg]);
    m.position = motionTo;
    return [self _motionFixed:m];
}

/*
- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    TRACE_LOG(@"from:%d to:%d type:%d", from, to, type);
    if( _forcedMotionType != CHARACTERWISE_EXCLUSIVE){
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
 */

-(XVimEvaluator*)_motionFixed:(XVimMotion*)motion{
    if( _forcedMotionType == CHARACTERWISE_EXCLUSIVE){ // CHARACTERWISE_EXCLUSIVE means 'v' is pressed and it means toggle inclusive/exclusive. So its not always "exclusive"
        if( motion.type == LINEWISE ){
            motion.type = CHARACTERWISE_EXCLUSIVE;
        }else{
            if ( motion.type == CHARACTERWISE_EXCLUSIVE ){
                motion.type = CHARACTERWISE_INCLUSIVE;
            } else if(motion.type == CHARACTERWISE_INCLUSIVE) {
                motion.type = CHARACTERWISE_EXCLUSIVE;
            }
        }
	}else if (_forcedMotionType == LINEWISE){
        motion.type = LINEWISE;
    }else if (_forcedMotionType == BLOCKWISE){
        // TODO: Implemente BLOCKWISE operation
        // Currently BLOCKWISE is not supporeted by operations implemented in NSTextView.m
        motion.type = LINEWISE;
    }else{
        // _forceMotionType == DEFAULT_MOTION_TYPE
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

- (XVimEvaluator*)onComplete_fFtT:(XVimArgumentEvaluator*)childEvaluator{
    // FIXME:
    // Do not use toString here.
    // keyStroke must generate a internal code
    /*
    if( childEvaluator.keyStroke.toString.length != 1 ){
        return [XVimEvaluator invalidEvaluator];
    }
     */
    
    self.motion.count = self.numericArg;
    self.motion.character = childEvaluator.keyStroke.character;
    [XVim instance].lastCharacterSearchMotion = self.motion;
    return [self _motionFixed:self.motion];
}
                                   
- (XVimEvaluator*)f{
    [self.argumentString appendString:@"f"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.motion = MOTION_NEXT_CHARACTER;
    self.motion.type = CHARACTERWISE_INCLUSIVE;
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)F{
    [self.argumentString appendString:@"F"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.motion = MOTION_PREV_CHARACTER;
    self.motion.type = CHARACTERWISE_EXCLUSIVE;
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

/*
 // Since Ctrl-f is not "motion" but "scroll"
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 - (XVimEvaluator*)C_f{
 return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
 }
 */

- (XVimEvaluator*)g{
    [self.argumentString appendString:@"g"];
    self.onChildCompleteHandler = @selector(onComplete_g:);
    return [[[XVimGMotionEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_g:(XVimGMotionEvaluator*)childEvaluator{
    return [self _motionFixed:childEvaluator.motion];
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
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_HOME, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)j{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)k{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)l{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, LEFT_RIGHT_NOWRAP, [self numericArg])];
}

- (XVimEvaluator*)L{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BOTTOM, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)M{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_MIDDLE, LINEWISE, MOTION_OPTION_NONE, [self numericArg])];
}


- (XVimEvaluator*)nN_impl:(BOOL)opposite{
    XVimMotion* m = [XVim.instance.searcher motionForRepeatSearch];
    if( opposite ){
        m.motion = (m.motion == MOTION_SEARCH_FORWARD) ? MOTION_SEARCH_BACKWARD : MOTION_SEARCH_FORWARD;
    }
    self.motion = m;
    return [self _motionFixed:m];
}

- (XVimEvaluator*)n{
    return [self nN_impl:NO];
}

- (XVimEvaluator*)N{
    return [self nN_impl:YES];
}

/*
 // Since Ctrl-u is not "motion" but "scroll"
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 
 - (XVimEvaluator*)C_u{
 // This should not be implemneted here
 }
 */

- (XVimEvaluator*)t{
    [self.argumentString appendString:@"t"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.motion = MOTION_TILL_NEXT_CHARACTER;
    self.motion.type = CHARACTERWISE_INCLUSIVE;
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)T{
    [self.argumentString appendString:@"T"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.motion = MOTION_TILL_PREV_CHARACTER;
    self.motion.type = CHARACTERWISE_EXCLUSIVE;
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)v{
    _forcedMotionType = CHARACTERWISE_EXCLUSIVE; // This does not mean the motion will always be "exclusive". This is just for remembering that its type is "characterwise" forced.
                                                 // Actual motion is decided by motions' default inclusive/exclusive attribute and _toggleInclusiveExclusive flag.
    _toggleInclusiveExclusive = !_toggleInclusiveExclusive;
    return self;
}

- (XVimEvaluator*)V{
    _toggleInclusiveExclusive = NO;
    _forcedMotionType = LINEWISE;
    return self;
}

- (XVimEvaluator*)C_v{
    _toggleInclusiveExclusive = NO;
    _forcedMotionType = BLOCKWISE;
    return self;
}

- (XVimEvaluator*)w{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)W{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_WORD_FORWARD, CHARACTERWISE_EXCLUSIVE, BIGWORD, [self numericArg])];
}

- (XVimEvaluator*)z{
    [self.argumentString appendString:@"z"];
    return [[[XVimZEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)NUM0{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_BEGINNING_OF_LINE, CHARACTERWISE_INCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)searchCurrentWordForward:(BOOL)forward {
    XVimCommandLineEvaluator* eval = [self searchEvaluatorForward:forward];
    NSRange r = [self.sourceView xvim_currentWord:MOTION_OPTION_NONE];
    if( r.location == NSNotFound ){
        return nil;
    }
    // This is not for matching the searching word itself
    // Vim also does this behavior( when matched string is not found )
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    m.position = r.location;
    [self.sourceView xvim_move:m];
    
    NSString* word = [self.sourceView.string substringWithRange:r];
    NSString* searchWord = [NSRegularExpression escapedPatternForString:word];
    searchWord = [NSString stringWithFormat:@"%@%@%@", @"\\b", searchWord, @"\\b"];
    [eval appendString:searchWord];
    [eval execute];
    return [self _motionFixed:eval.evalutionResult];
}

- (XVimEvaluator*)ASTERISK{
    return [self searchCurrentWordForward:YES];
}

- (XVimEvaluator*)NUMBER{
	return [self searchCurrentWordForward:NO];
}

// This is internal method used by SQUOTE, BACKQUOTE
// TODO: rename firstOfLine -> firstNonblankOfLine
- (XVimEvaluator*)jumpToMark:(XVimMark*)mark firstOfLine:(BOOL)fol{
    NSUInteger cur_pos = self.sourceView.insertionPoint;
	MOTION_TYPE motionType = fol?LINEWISE:CHARACTERWISE_EXCLUSIVE;
    
    if( mark.line == NSNotFound ){
        return [XVimEvaluator invalidEvaluator];
    }
    
    if( ![mark.document isEqualToString:self.sourceView.documentURL.path]){
        IDEDocumentController* ctrl = [IDEDocumentController sharedDocumentController];
        NSError* error;
        NSURL* doc = [NSURL fileURLWithPath:mark.document];
        [ctrl openDocumentWithContentsOfURL:doc display:YES error:&error];
    }
    
    NSUInteger to = [self.sourceView.textStorage positionAtLineNumber:mark.line column:mark.column];
    if( NSNotFound == to ){
        return [XVimEvaluator invalidEvaluator];
    }
    
    if( fol ){
        to = [self.sourceView.textStorage firstNonblankInLine:to]; // This never returns NSNotFound
    }
	
    // set the position before the jump
    XVimMark* cur_mark = [[[XVimMark alloc] init] autorelease];
    cur_mark.line = [self.sourceView.textStorage lineNumber:cur_pos];
    cur_mark.column = [self.sourceView.textStorage columnNumber:cur_pos];
    cur_mark.document = [self.sourceView documentURL].path;
    if( nil != mark.document ){
        [[XVim instance].marks setMark:cur_mark forName:@"'"];
    }
    
    XVimMotion* m =XVIM_MAKE_MOTION(MOTION_POSITION, motionType, MOTION_OPTION_NONE, self.numericArg);
    m.position = to;
    return [self _motionFixed:m];
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE{
    [self.argumentString appendString:@"'"];
    self.onChildCompleteHandler = @selector(onComplete_SQUOTE:);
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_SQUOTE:(XVimArgumentEvaluator*)childEvaluator{
    // FIXME:
    // This will work for Ctrl-c as register c but it should not
    //NSString* key = [childEvaluator.keyStroke toString];
    NSString* key = [NSString stringWithFormat:@"%c", childEvaluator.keyStroke.character];
    XVimMark* mark = [[XVim instance].marks markForName:key forDocument:[self.sourceView documentURL].path];
    return [self jumpToMark:mark firstOfLine:YES];
}

- (XVimEvaluator*)BACKQUOTE{
    [self.argumentString appendString:@"`"];
    self.onChildCompleteHandler = @selector(onComplete_BACKQUOTE:);
    return [[[XVimArgumentEvaluator alloc] initWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)onComplete_BACKQUOTE:(XVimArgumentEvaluator*)childEvaluator{
    // FIXME:
    // This will work for Ctrl-c as register c but it should not
    // NSString* key = [childEvaluator.keyStroke toString];
    NSString* key = [NSString stringWithFormat:@"%c", childEvaluator.keyStroke.character];
    XVimMark* mark = [[XVim instance].marks markForName:key forDocument:[self.sourceView documentURL].path];
    return [self jumpToMark:mark firstOfLine:NO];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_FIRST_NONBLANK, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

- (XVimEvaluator*)DOLLAR{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_END_OF_LINE, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, [self numericArg])];
}

// Underscore ( "_") moves the cursor to the start of the line (past leading whitespace)
// Note: underscore without any numeric arguments behaves like caret but with a numeric argument greater than 1
// it will moves to start of the numeric argument - 1 lines down.
- (XVimEvaluator*)UNDERSCORE{
    // TODO add this motion interface to NSTextView
    NSTextView* view = [self.window sourceView];
    NSRange r = [view selectedRange];
    NSUInteger repeat = self.numericArg;
    NSUInteger linesUpCursorloc = [view.textStorage nextLine:r.location column:0 count:(repeat - 1) option:MOTION_OPTION_NONE];
    NSUInteger head = [view.textStorage firstOfLineWithoutSpaces:linesUpCursorloc];
    if( NSNotFound == head && linesUpCursorloc != NSNotFound){
        head = linesUpCursorloc;
    }else if(NSNotFound == head){
        head = r.location;
    }
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 0);
    m.position = head;
    return [self _motionFixed:m];
}

- (XVimEvaluator*)PERCENT {
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
    XVimMotion* m = [XVim instance].lastCharacterSearchMotion;
    if( nil == m ){
        return [XVimEvaluator invalidEvaluator];
    }
    
    MOTION new_motion = MOTION_PREV_CHARACTER;
    switch( m.motion ){
        case MOTION_NEXT_CHARACTER:
            new_motion = MOTION_PREV_CHARACTER;
            break;
        case MOTION_PREV_CHARACTER:
            new_motion = MOTION_NEXT_CHARACTER;
            break;
        case MOTION_TILL_NEXT_CHARACTER:
            new_motion = MOTION_TILL_PREV_CHARACTER;
            break;
        case MOTION_TILL_PREV_CHARACTER:
            new_motion = MOTION_TILL_NEXT_CHARACTER;
            break;
        default:
            NSAssert(NO, @"Should not reach here");
            break;
    }
    XVimMotion* n = XVIM_MAKE_MOTION(new_motion, m.type, m.option, [self numericArg]);
    n.character = m.character;
    return [self _motionFixed:n];
}

- (XVimEvaluator*)SEMICOLON{
    XVimMotion* m = [XVim instance].lastCharacterSearchMotion;
    if( nil == m ){
        return [XVimEvaluator invalidEvaluator];
    }
    XVimMotion* n = XVIM_MAKE_MOTION(m.motion, m.type, m.option, [self numericArg]);
    n.character = m.character;
    return [self _motionFixed:n];
}


// QESTION and SLASH are "motion" since it can be used as an arugment for operators.
// "d/abc<CR>" will delete until "abc" characters.
- (XVimEvaluator*)QUESTION{
    self.onChildCompleteHandler = @selector(onCompleteSearch:);
	return [self searchEvaluatorForward:NO];
}

- (XVimEvaluator*)SLASH{
    self.onChildCompleteHandler = @selector(onCompleteSearch:);
	return [self searchEvaluatorForward:YES];
}

- (XVimEvaluator*)onCompleteSearch:(XVimCommandLineEvaluator*)childEvaluator{
    self.onChildCompleteHandler = nil;
    if( childEvaluator.evalutionResult != nil ){
        return [self _motionFixed:childEvaluator.evalutionResult];
    }
    return [XVimEvaluator invalidEvaluator];
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

@end
