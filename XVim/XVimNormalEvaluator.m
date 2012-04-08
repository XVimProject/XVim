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
#import "XVimEqualEvaluator.h"
#import "XVimShiftEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimRegisterEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"
#import "XVimKeyStroke.h"
#import "XVim.h"
#import "NSTextView+VimMotion.h"
#import "DVTCompletionController.h"
#import "Logger.h"

@interface XVimNormalEvaluator()
@property (readwrite) NSUInteger playbackCount;
@property (nonatomic, weak) XVimRegister *playbackRegister;
@end

@implementation XVimNormalEvaluator

@synthesize playbackCount = _playbackCount;
@synthesize playbackRegister = _playbackRegister;

-(id)initWithRegister:(XVimRegister*)xregister andPlaybackCount:(NSUInteger)count{
    self = [super init];
    if (self){
        _playbackCount = count;
        _playbackRegister = xregister;
    }
    return self;
}

- (XVIM_MODE)becameHandler:(XVim*)xvim{
    //[[xvim sourceView] adjustCursorPosition];
    if (self.playbackRegister) {
        [self.playbackRegister playbackWithHandler:xvim withRepeatCount:self.playbackCount];
        
        // Clear the playback register now that we have finished playing it back
        self.playbackRegister = nil;
    }
    return MODE_NORMAL;
}

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
	return keymaps[MODE_NORMAL];
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a:(XVim*)xvim{
    // if we are at the end of a line. the 'a' acts like 'i'. it does not start inserting on
   // next line. it appends to the current line
    // A cursor should not be on the new line break letter in Vim(Except empty line).
    // So the root solution is to prohibit a cursor be on the newline break letter.
    NSTextView* view = [xvim sourceView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    if ([view isEOF:idx] || [[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx]] ) {
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    } 
    [view moveForward:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)A:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange r = [view selectedRange];
    NSUInteger end = [view tailOfLine:r.location];
    [view setSelectedRange:NSMakeRange(end,0)];
    [view scrollToCursor];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b:(XVim*)xvim{
    NSUInteger next = [[xvim sourceView] pageBackward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [[xvim sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c:(XVim*)xvim{
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:TRUE];
    return [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:TRUE];
}

// 'C' works similar to 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange range = [view selectedRange];
    NSUInteger count = [self numericArg];
    NSUInteger to = range.location;
    NSUInteger column = [view columnNumber:to];
    to = [view nextLine:range.location column:column count:count-1 option:MOTION_OPTION_NONE];
    NSUInteger eol = [view endOfLine:to];
    
    if (eol == NSNotFound && to != range.location){
        // This is blank line.
        // If the start and end point is not the same, the end position is before the blank line.
        eol = to-1;
    }
    
    if( eol != NSNotFound ){
        [view setSelectedRangeWithBoundsCheck:range.location To:eol+1];
        if( ![view isEOF:range.location] ){
            [view cut:self]; // cut with selection with {EOF,0} cause exception. This is a little strange since  setSelectedRange with {EOF,0} does not cause any exception...
        }
    }
    
    // Go to insert 
    NSUInteger end = [view tailOfLine:[view selectedRange].location];
    [view setSelectedRange:NSMakeRange(end,0)];
    return [[XVimInsertEvaluator alloc] initWithRepeat:1];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_d:(XVim*)xvim{
    NSUInteger next = [[xvim sourceView] halfPageForward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [[xvim sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)d:(XVim*)xvim{
	XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithInsertModeAtCompletion:FALSE];	
    return [[XVimDeleteEvaluator alloc] initWithOperatorAction:action repeat:[self numericArg] insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSRange range = [view selectedRange];
    NSUInteger count = [self numericArg];
    NSString *text = [view string];
    NSUInteger to = range.location;
    for (; to < text.length && count > 0; ++to) {
        unichar c = [text characterAtIndex:to];
        if (isNewLine(c)) {
            --count;
        }
    }
    NSUInteger from = range.location;
    NSUInteger head = [view headOfLine:range.location];
    if ([self numericArg] > 1 && !isWhiteSpace([text characterAtIndex:from])){
        for (; from >= head; --from){
            unichar c = [text characterAtIndex:from-1];
            if (isNewLine(c)){
                --from;
                break;
            }
            if (!isWhiteSpace(c)){
                break;
            }
        }
    }
    
    NSUInteger length = to - from - 1;
    if (length > 0){
        [view setSelectedRange:NSMakeRange(from, length)];
        [view cut:self];
        
        // Bounds check
        if (from == range.location && ![view isBlankLine:from]){
            --range.location;
        }
        
        [view setSelectedRange:NSMakeRange(range.location, 0)];
    }
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_f:(XVim*)xvim{
    NSUInteger next = [[xvim sourceView] pageForward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [[xvim sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)i:(XVim*)xvim{
    // Go to insert 
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)I:(XVim*)xvim{
    NSRange range = [[xvim sourceView] selectedRange];
    NSUInteger head = [[xvim sourceView] headOfLineWithoutSpaces:range.location];
    if( NSNotFound == head ){
        return [self A:xvim]; // If its blankline or has only whitespaces'I' works line 'A'
    }
    [self _motionFixedFrom:range.location To:head Type:CHARACTERWISE_INCLUSIVE XVim:xvim];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// For 'J' (join line) bring the line up from below. all leading whitespac 
// of the line joined in should be stripped and then one space should be inserted 
// between the joined lines
- (XVimEvaluator*)J:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSUInteger repeat = [self numericArg];
    //if( 1 != repeat ){ repeat--; }
    NSRange r = [view selectedRange];
    BOOL addSpace = YES;
    for( NSUInteger i = 0 ; i < repeat ; i++ ){
        if( [view isBlankLine:r.location] ){
            [view deleteForward:self];
            continue;
        }
        
        if( [view isWhiteSpace:[view endOfLine:r.location]] ){
            // since the line is not empty, we do not need to check if its NSNotFound
            addSpace = NO;
        }
        
        NSUInteger nextnewline;
        nextnewline = [view nextNewLine:r.location];
        if( NSNotFound == nextnewline ){
            // Nothing to do
            break;
        }
        
        [view setSelectedRange:NSMakeRange(nextnewline,0)];
        [view deleteForward:self];
        NSRange cursorAfterConcatenate = [view selectedRange]; // After concatenate, the cursor position get back to this pos.
        if( addSpace ){
            [view insertText:@" "];
        }
        NSUInteger curLocation = [view selectedRange].location;
        
        NSUInteger nonblank = [view nextNonBlankInALine:[view selectedRange].location];
        if( NSNotFound == nonblank ){
            if( ![view isNewLine:curLocation] && [view isEOF:curLocation]){
                [view setSelectedRangeWithBoundsCheck:curLocation To:[view tailOfLine:curLocation]];
                [view delete:self];
            }else{
                // Blank line. Nothing todo
            }
        }else{
            if( curLocation != nonblank ){
                [view setSelectedRangeWithBoundsCheck:[view selectedRange].location To:nonblank];
                [view delete:self];
            }else{
                // No white spaces in next line.
            }
        }
        [view setSelectedRange:cursorAfterConcatenate];
    }
    return nil;
}

// Should be moveed to XVimMotionEvaluator

 - (XVimEvaluator*)m:(XVim*)xvim{
    // 'm{letter}' sets a local mark.
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_SET xvimTarget:xvim];
}

- (XVimEvaluator*)o:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSUInteger l = [view selectedRange].location;
    NSUInteger tail = [view tailOfLine:l];
    [view setSelectedRange:NSMakeRange(tail,0)];
    [view insertNewline:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)O:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    NSUInteger l = [view selectedRange].location;
    NSUInteger head = [view headOfLine:l];
    if( NSNotFound == head ){
        head = l;
    }
    if( 0 != head ){
        [view setSelectedRange:NSMakeRange(head-1,0)];
        [view insertNewline:self];
    }else{
        
        [view setSelectedRange:NSMakeRange(head,0)];
        [view insertNewline:self];
        NSUInteger prev = [view prevLine:[view selectedRange].location column:0 count:1 option:MOTION_OPTION_NONE];
        [view setSelectedRange:NSMakeRange(prev,0)];
    }
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)C_o:(XVim*)xvim{
    [NSApp sendAction:@selector(goBackInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)C_i:(XVim*)xvim{
    [NSApp sendAction:@selector(goForwardInHistoryByCommand:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)p:(XVim*)xvim{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    // TODO: This does not work when the text is copied from line which includes EOF since it does not have newline.
    //       If we want to treat the behaviour correctly we should prepare registers to copy and create an attribute to keep 'linewise'
    
    // TODO: dw of a word at the end of a line does not subsequently 'p' back correctly but that's
    // because dw is not working quite right it seems
    NSTextView* view = [xvim sourceView];
    NSUInteger loc = [view selectedRange].location;
    NSString *pb_string = [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
    unichar uc =[pb_string characterAtIndex:[pb_string length] -1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:uc]) {
        if( [view isBlankLine:loc] && ![view isEOF:loc]){
            [view setSelectedRange:NSMakeRange(loc+1,0)];
        }else{
            NSUInteger newline = [view nextNewLine:loc];
            if( NSNotFound == newline ){
                // add newline at EOF
                [view setSelectedRange:NSMakeRange([[view string]length], 0)];
                [view insertNewline:self];
            }else{
                [view setSelectedRange:NSMakeRange(newline+1, 0)];
            }
        }
    }else{
        [view moveForward:self];
    }
    
    for(NSUInteger i = 0; i < [self numericArg]; i++ ){
        [view paste:self];
    }
    return nil;
}

- (XVimEvaluator*)P:(XVim*)xvim{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    NSTextView* view = [xvim sourceView];
    NSString *pb_string = [[NSPasteboard generalPasteboard]stringForType:NSStringPboardType];
    unichar uc =[pb_string characterAtIndex:[pb_string length] -1];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:uc]) {
        NSUInteger b = [view headOfLine:[view selectedRange].location];
        if( NSNotFound != b ){
            [view setSelectedRange:NSMakeRange(b,0)];
        }
    }
    for(NSUInteger i = 0; i < [self numericArg]; i++ ){
        [view paste:self];
    }
    return nil;
}

- (XVimEvaluator*)q:(XVim*)xvim{
    if (xvim.recordingRegister != nil){
        [xvim stopRecordingRegister:xvim.recordingRegister];
        return nil;
    }
    
    return [[XVimRegisterEvaluator alloc] initWithMode:REGISTER_EVAL_MODE_RECORD andCount:[self numericArg]];
}

- (XVimEvaluator*)C_r:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] redo];
    }
    // Redo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}

- (XVimEvaluator*)r:(XVim*)xvim{
    return [[XVimInsertEvaluator alloc] initOneCharMode:YES withRepeat:[self numericArg]];
}

- (XVimEvaluator*)s:(XVim*)xvim{
    NSTextView *view = [xvim sourceView];
    NSRange r = [view selectedRange];
	
	// Set range to replace, ensuring we don't run over the end of the buffer
	NSUInteger endi = r.location + self.numericArg;
	NSUInteger maxi = [[view string] length];
	endi = MIN(endi, maxi);
	NSRange replacementRange = NSMakeRange(r.location, endi - r.location);
	
    [view setSelectedRange:replacementRange];
	
	// Xcode crashes if we cut a zero length selection
	if (replacementRange.length > 0)
	{
		[view cut:self];
	}
	
    return [[XVimInsertEvaluator alloc] initOneCharMode:NO withRepeat:1];
}

- (XVimEvaluator*)u:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] undo];
    }

    // Undo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_u:(XVim*)xvim{
    NSUInteger next = [[xvim sourceView] halfPageBackward:[[xvim sourceView] selectedRange].location count:[self numericArg]];
    [[xvim sourceView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)v:(XVim*)xvim{
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_CHARACTER];
}

- (XVimEvaluator*)V:(XVim*)xvim{
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_LINE]; 
}

- (XVimEvaluator*)C_v:(XVim*)xvim{
    // Block selection
    return nil;
}

- (XVimEvaluator*)x:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
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
    [view cut:self];
    return nil;
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
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
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)y:(XVim*)xvim{
	XVimOperatorAction *operatorAction = [[XVimYankAction alloc] init];
    return [[XVimYankEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
}

- (XVimEvaluator*)AT:(XVim*)xvim{
    return [[XVimRegisterEvaluator alloc] initWithMode:REGISTER_EVAL_MODE_PLAYBACK andCount:[self numericArg]];
}

- (XVimEvaluator*)EQUAL:(XVim*)xvim{
	XVimOperatorAction *operatorAction = [[XVimEqualAction alloc] init];
    return [[XVimEqualEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
}

- (XVimEvaluator*)GREATERTHAN:(XVim*)xvim{
	XVimOperatorAction *operatorAction = [[XVimShiftAction alloc] initWithUnshift:NO];
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
    return eval;
}

- (XVimEvaluator*)LESSTHAN:(XVim*)xvim{
	XVimOperatorAction *operatorAction = [[XVimShiftAction alloc] initWithUnshift:YES];
    XVimShiftEvaluator* eval =  [[XVimShiftEvaluator alloc] initWithOperatorAction:operatorAction repeat:[self numericArg]];
    return eval;
    
}

- (XVimEvaluator*)HT:(XVim*)xvim{
    [[xvim sourceView] selectNextPlaceholder:self];
    return nil;
}

- (XVimEvaluator*)COLON:(XVim*)xvim{
    // Go to Cmd Line mode
    // Command line mode is treated totally different way from this XVimEvaluation system
    // aet firstResponder to XVimCommandLine(NSView's subclass) and everything is processed there.
    [xvim commandModeWithFirstLetter:@":"];
    return nil;
}

- (XVimEvaluator*)QUESTION:(XVim*)xvim{
    [xvim commandModeWithFirstLetter:@"?"];
    return nil;
}

- (XVimEvaluator*)SLASH:(XVim*)xvim{
    [xvim commandModeWithFirstLetter:@"/"];
    return nil;
}

- (XVimEvaluator*)DOT:(XVim*)xvim{
    XVimRegister *repeatRegister = [xvim findRegister:@"repeat"];
    [xvim playbackRegister:repeatRegister withRepeatCount:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)TILDE:(XVim*)xvim{
    NSTextView* view = [xvim sourceView];
	NSRange replacementRange = [view selectedRange];
	replacementRange.length = [self numericArg];
	[view clampRangeToEndOfLine:&replacementRange];
	[view toggleCaseForRange:replacementRange];
	return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
    // in normal mode
    // move the a cursor to end of motion. We ignore the motion type.
    NSTextView* view = [xvim sourceView];
    NSRange r = NSMakeRange(to, 0);
    [view setSelectedRange:r];
    [view scrollToCursor];
    return nil;
}

// There are fewer invalid keys than valid ones so make a list of invalid keys.
// This can always be changed to a set of valid keys in the future if need be.
NSArray *_invalidRepeatKeys;
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    if (_invalidRepeatKeys == nil){
        _invalidRepeatKeys =
        [[NSArray alloc] initWithObjects:
         [NSValue valueWithPointer:@selector(m:)],
         [NSValue valueWithPointer:@selector(C_r:)],
         [NSValue valueWithPointer:@selector(u:)],
         [NSValue valueWithPointer:@selector(v:)],
         [NSValue valueWithPointer:@selector(V:)],
         [NSValue valueWithPointer:@selector(C_v:)],
         [NSValue valueWithPointer:@selector(AT:)],
         [NSValue valueWithPointer:@selector(COLON:)],
         [NSValue valueWithPointer:@selector(DOT:)],
         [NSValue valueWithPointer:@selector(QUESTION:)],
         [NSValue valueWithPointer:@selector(SLASH:)],
         nil];
    }
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if (keySelector == [NSValue valueWithPointer:@selector(q:)]){
        return REGISTER_IGNORE;
    }else if (xregister.isRepeat){
        if([keyStroke classResponds:[XVimNormalEvaluator class]] &&
           ![keyStroke classResponds:[XVimNormalEvaluator superclass]]){
            if ([_invalidRepeatKeys containsObject:keySelector] == NO){
                return REGISTER_REPLACE;
            }
        }
    }
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}


@end
