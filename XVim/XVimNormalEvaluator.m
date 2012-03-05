//
//  XVimNormalEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//


#import "XVimNormalEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimLocalMarkEvaluator.h"
#import "XVimSearchLineEvaluator.h"
#import "XVimYankEvaluator.h"
#import "XVimShiftEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"

@implementation XVimNormalEvaluator
/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////


// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a:(id)arg{
    // if we are at the end of a line. the 'a' acts like 'i'. it does not start inserting on
    // next line. it appends to the current line
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx]]) {
        [self xvim].mode = MODE_INSERT;
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    } 
    [view moveForward:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)A:(id)arg{
    NSTextView* view = [self textView];
    [view moveToEndOfLine:self];
    [self xvim].mode=MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c:(id)arg{
    return [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:TRUE];
}

// 'C' works like 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C:(id)arg{
    // TODO: handle numericArg
    NSTextView* view = [self textView];
    [view moveToEndOfLineAndModifySelection:self];
    [view cut:self];

    // Go to insert 
    [self xvim].mode = MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)C_b:(id)arg{
    for(NSUInteger i = 0 ; i < [self numericArg] ; i++ ){
        [[self textView] pageUp:self];
    }
    return nil;
}

- (XVimEvaluator*)C_d:(id)arg{
    for(NSUInteger i = 0 ; i < [self numericArg] ; i++ ){
        [[self textView] pageDown:self];
    }
    return nil;
}

- (XVimEvaluator*)d:(id)arg{
    return [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D:(id)arg{
    // TODO: handle numericArg
    NSTextView* view = [self textView];
    [view moveToEndOfLineAndModifySelection:self];
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)C_f:(id)arg{
    for(NSUInteger i = 0 ; i < [self numericArg] ; i++ ){
        [[self textView] pageDown:self];
    }
    return nil;
}

- (XVimEvaluator*)i:(id)arg{
    // Go to insert 
    [self xvim].mode = MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)I:(id)arg{
    NSTextView* view = [self textView];
    [view moveToBeginningOfLine:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// For 'J' (join line) bring the line up from below. all leading whitespac 
// of the line joined in should be stripped and then one space should be inserted 
// between the joined lines
- (XVimEvaluator*)J:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSUInteger repeat = [self numericArg];
    //if( 1 != repeat ){ repeat--; }
    NSRange r = [view selectedRange];
    for( NSUInteger i = 0 ; i < repeat ; i++ ){
        [view moveToEndOfLine:self]; // move to eol
        [view deleteForward:self];
        NSRange at = [view selectedRange];
        [[view textStorage] replaceCharactersInRange:at withString:@" "];
        while (TRUE) { // delete any leading whitespace from lower line
            if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:at.location+1]])
                break;
            [view deleteForward:self];
        }
        [view setSelectedRange:r];
    }
    return nil;
}

// Should be moveed to XVimMotionEvaluator
- (XVimEvaluator*)m:(id)arg{
    // 'm{letter}' sets a local mark. 
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_SET xvimTarget:[self xvim]];
}

- (XVimEvaluator*)n:(id)arg{
    [[self xvim] searchNext];
    return nil;
}

- (XVimEvaluator*)N:(id)arg{
    [[self xvim] searchPrevious];
    return nil;
}

- (XVimEvaluator*)o:(id)arg{
    NSTextView* view = [self textView];
    [view moveToEndOfLine:self];
    [view insertNewline:self];
    [self xvim].mode = MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)O:(id)arg{
    NSTextView* view = [self textView];
    if( [view _currentLineNumber] == 1 ){
        [view moveToBeginningOfLine:self];
        [view insertNewline:self];
        [view moveUp:self];
    }
    else {
        [view moveUp:self];
        [view moveToEndOfLine:self];
        [view insertNewline:self];
    }
    [self xvim].mode = MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)p:(id)arg{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    // TODO: dw of a word at the end of a line does not subsequently 'p' back correctly but that's
    // because dw is not working quite right it seems
    NSTextView* view = [self textView];
    NSString *pb_string = [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
    unichar uc =[pb_string characterAtIndex:[pb_string length] -1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:uc]) {
        [view moveToEndOfLine:self];
    }
    [view moveForward:self];
    for(NSUInteger i = 0; i < [self numericArg]; i++ ){
        [view paste:self];
    }
    return nil;
}

- (XVimEvaluator*)P:(id)arg{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    NSTextView* view = [self textView];
    NSString *pb_string = [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
    unichar uc =[pb_string characterAtIndex:[pb_string length] -1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:uc]) {
        [view moveToBeginningOfLine:self];
    }
    for(NSUInteger i = 0; i < [self numericArg]; i++ ){
        [view paste:self];
    }
    return nil;
}

- (XVimEvaluator*)C_r:(id)arg{
    // Go to insert 
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] redo];
    }
    return nil;
}

- (XVimEvaluator*)r:(id)arg{
    NSTextView* view = [self textView];
    [view moveForwardAndModifySelection:self];
    [self xvim].mode = MODE_INSERT;
    return [[XVimInsertEvaluator alloc] initOneCharMode:TRUE withRepeat:1];
}

- (XVimEvaluator*)u:(id)arg{
    // Go to insert
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] undo];
    }
    return nil;
}
- (XVimEvaluator*)C_u:(id)arg{
    for(NSUInteger i = 0 ; i < [self numericArg] ; i++ ){
        [[self textView] pageUp:self];
    }
    return nil;
}

- (XVimEvaluator*)v:(id)arg{
    NSTextView* view = [self textView];
    [self xvim].mode = MODE_VISUAL;
    NSRange r = [view selectedRange];
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_CHARACTER initialSelection:r.location :(NSUInteger)r.location+r.length];
}

- (XVimEvaluator*)V:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];

    // Select the currnet line before entering XVimVisualEvalutor becuase its linewise visual mode.
    // This is not really good implementation I feel.
    // This selection should be done by XVimVisualEvaluator...
    // We may need to prepare new initializer which can operate on the view when its initialized.
    // Since such structure may be needed from other operations this should be implemented in XVimEvaluator (Base class) 
    [view setSelectedRangeWithBoundsCheck:[view headOfLine] To:[view nextNewline]];
    [self xvim].mode = MODE_VISUAL;
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_LINE initialSelection:r.location :(NSUInteger)r.location+r.length];
}

- (XVimEvaluator*)C_v:(id)arg{
    // Block selection
    return nil;
}

- (XVimEvaluator*)x:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    // note: in vi you are not supposed to move beyond the end of a line when doing "x" operations
    // it's that way on purpose. this allows you to hit a bunch of x's in a row and not worry about 
    // accidentally joining the next line into the current line.
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    for( NSUInteger i = 0 ; idx < s.length && i < [self numericArg]; i++,idx++ ){
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx]]) {
            // if at the end of line, and are just doing a single x it's like doing X
            if ([self numericArg] == 1) {
                if (idx > 0 && ![[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx-1]]) {
                    [view moveBackwardAndModifySelection:self]; 
                }
            }
            break;
        }
        [view moveForwardAndModifySelection:self];
    }
    [view delete:self];
    return nil;
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    // note: in vi you are not supposed to move beyond the start of a line when doing "X" operations
    // it's that way on purpose. this allows you to hit a bunch of X's in a row and not worry about 
    // accidentally joining the current line up into the previous line.
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    for( NSUInteger i = 0 ; idx > 0 && i < [self numericArg]; i++,idx-- ){
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx-1]])
            break;
        [view moveBackwardAndModifySelection:self]; 
    }
    [view delete:self];
    return nil;
}

- (XVimEvaluator*)y:(id)arg{
    return [[XVimYankEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithRepeat:[self numericArg]];
    eval.unshift = NO;
    return eval;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithRepeat:[self numericArg]];
    eval.unshift = YES;
    return eval;
    
}

- (XVimEvaluator*)COLON:(id)arg{
    // Go to Cmd Line mode
    // Command line mode is treated totally different way from this XVimEvaluation system
    // aet firstResponder to XVimCommandLine(NSView's subclass) and everything is processed there.
    [[self xvim] commandModeWithFirstLetter:@":"];
    return nil;
}

- (XVimEvaluator*)SLASH:(id)arg{
    [[self xvim] commandModeWithFirstLetter:@"/"];
    return nil;
}

- (XVimEvaluator*)QUESTION:(id)arg{
    [[self xvim] commandModeWithFirstLetter:@"?"];
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

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    // in normal mode
    // move the a cursor to end of motion. We ignore the motion type.
    NSTextView* view = [self textView];
    NSRange r = NSMakeRange(to, 0);
    [view setSelectedRange:r];
    [view scrollRangeToVisible:r];
    return nil;
}

@end
