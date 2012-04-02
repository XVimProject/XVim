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
#import "XVim.h"
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
    self.xvim = xvim;
    [[xvim sourceView] adjustCursorPosition];
    if (self.playbackRegister) {
        [self.playbackRegister playback:[xvim sourceView] withRepeatCount:self.playbackCount];
        
        // Clear the playback register now that we have finished playing it back
        self.playbackRegister = nil;
    }
    return MODE_NORMAL;
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

// Command which results in cursor motion should be implemented in XVimMotionEvaluator

- (XVimEvaluator*)a:(id)arg{
    // if we are at the end of a line. the 'a' acts like 'i'. it does not start inserting on
    // next line. it appends to the current line
    // A cursor should not be on the new line break letter in Vim(Except empty line).
    // So the root solution is to prohibit a cursor be on the newline break letter.
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger idx = begin.location;
    if ([view isEOF:idx] || [[NSCharacterSet newlineCharacterSet] characterIsMember:[s characterAtIndex:idx]] ) {
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    } 
    [view moveForward:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)A:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    NSUInteger end = [view tailOfLine:r.location];
    [view setSelectedRange:NSMakeRange(end,0)];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_b:(id)arg{
    NSUInteger next = [[self textView] pageBackward:[[self textView] selectedRange].location count:[self numericArg]];
    [[self textView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode
- (XVimEvaluator*)c:(id)arg{
    return [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:TRUE];
}

// 'C' works similar to 'D' except that once it's done deleting
// it should go into insert mode
- (XVimEvaluator*)C:(id)arg{
    NSTextView* view = [self textView];
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
        [view setSelectedRangeWithBoundsCheck:range.location To:eol];
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
- (XVimEvaluator*)C_d:(id)arg{
    NSUInteger next = [[self textView] halfPageForward:[[self textView] selectedRange].location count:[self numericArg]];
    [[self textView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)d:(id)arg{
    return [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D:(id)arg{
    NSTextView* view = [self textView];
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
- (XVimEvaluator*)C_f:(id)arg{
    NSUInteger next = [[self textView] pageForward:[[self textView] selectedRange].location count:[self numericArg]];
    [[self textView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)i:(id)arg{
    // Go to insert 
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)I:(id)arg{
    NSRange range = [[self textView] selectedRange];
    NSUInteger head = [[self textView] headOfLineWithoutSpaces:range.location];
    if( NSNotFound == head ){
        return [self A:arg]; // If its blankline or has only whitespaces'I' works line 'A'
    }
    [self _motionFixedFrom:range.location To:head Type:CHARACTERWISE_INCLUSIVE];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

// For 'J' (join line) bring the line up from below. all leading whitespac 
// of the line joined in should be stripped and then one space should be inserted 
// between the joined lines
- (XVimEvaluator*)J:(id)arg{
    NSTextView* view = [self textView];
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
                [view setSelectedRangeWithBoundsCheck:curLocation To:[view tailOfLine:curLocation]-1];
                [view delete:self];
            }else{
                // Blank line. Nothing todo
            }
        }else{
            if( curLocation != nonblank ){
                [view setSelectedRangeWithBoundsCheck:[view selectedRange].location To:nonblank-1];
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

 - (XVimEvaluator*)m:(id)arg{
    // 'm{letter}' sets a local mark.
    return [[XVimLocalMarkEvaluator alloc] initWithMarkOperator:MARKOPERATOR_SET xvimTarget:[self xvim]];
}

- (XVimEvaluator*)o:(id)arg{
    NSTextView* view = [self textView];
    NSUInteger l = [view selectedRange].location;
    NSUInteger tail = [view tailOfLine:l];
    [view setSelectedRange:NSMakeRange(tail,0)];
    [view insertNewline:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)O:(id)arg{
    NSTextView* view = [self textView];
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

- (XVimEvaluator*)p:(id)arg{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    // TODO: This does not work when the text is copied from line which includes EOF since it does not have newline.
    //       If we want to treat the behaviour correctly we should prepare registers to copy and create an attribute to keep 'linewise'
    
    // TODO: dw of a word at the end of a line does not subsequently 'p' back correctly but that's
    // because dw is not working quite right it seems
    NSTextView* view = [self textView];
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

- (XVimEvaluator*)P:(id)arg{
    // if the paste text has a eol at the end (line oriented), then we are supposed to move to 
    // the line boundary and then paste the data in.
    NSTextView* view = [self textView];
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

- (XVimEvaluator*)q:(id)arg{
    if ([self xvim].recordingRegister != nil){
        [[self xvim] stopRecordingRegister:[self xvim].recordingRegister];
        return nil;
    }
    
    return [[XVimRegisterEvaluator alloc] initWithMode:REGISTER_EVAL_MODE_RECORD andCount:[self numericArg]];
}

- (XVimEvaluator*)C_r:(id)arg{
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] redo];
    }
    // Redo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}

- (XVimEvaluator*)r:(id)arg{
    return [[XVimInsertEvaluator alloc] initOneCharMode:YES withRepeat:[self numericArg]];
}

- (XVimEvaluator*)s:(id)arg{
    NSTextView *view = [self textView];
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, [self numericArg])];
    [view cut:self];
    return [[XVimInsertEvaluator alloc] initOneCharMode:NO withRepeat:1];
}

- (XVimEvaluator*)u:(id)arg{
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] undo];
    }

    // Undo should not keep anything selected
    NSRange r = [view selectedRange];
    [view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}

// This is not motion but scroll. That's the reason the implementation is here.
- (XVimEvaluator*)C_u:(id)arg{
    NSUInteger next = [[self textView] halfPageBackward:[[self textView] selectedRange].location count:[self numericArg]];
    [[self textView] setSelectedRange:NSMakeRange(next,0)];
    return nil;
}

- (XVimEvaluator*)v:(id)arg{
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_CHARACTER];
}

- (XVimEvaluator*)V:(id)arg{
    return [[XVimVisualEvaluator alloc] initWithMode:MODE_LINE]; 
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
    [view cut:self];
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
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)y:(id)arg{
    return [[XVimYankEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)AT:(id)arg{
    return [[XVimRegisterEvaluator alloc] initWithMode:REGISTER_EVAL_MODE_PLAYBACK andCount:[self numericArg]];
}

- (XVimEvaluator*)EQUAL:(id)arg{
    return [[XVimEqualEvaluator alloc] initWithRepeat:[self numericArg]];
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

- (XVimEvaluator*)HT:(id)arg{
    [[[self xvim] sourceView] selectNextPlaceholder:self];
    return nil;
}

- (XVimEvaluator*)COLON:(id)arg{
    // Go to Cmd Line mode
    // Command line mode is treated totally different way from this XVimEvaluation system
    // aet firstResponder to XVimCommandLine(NSView's subclass) and everything is processed there.
    [[self xvim] commandModeWithFirstLetter:@":"];
    return nil;
}

- (XVimEvaluator*)QUESTION:(id)arg{
    [[self xvim] commandModeWithFirstLetter:@"?"];
    return nil;
}

- (XVimEvaluator*)SLASH:(id)arg{
    [[self xvim] commandModeWithFirstLetter:@"/"];
    return nil;
}

- (XVimEvaluator*)DOT:(id)arg{
    XVimRegister *repeatRegister = [[self xvim] findRegister:@"repeat"];
    [[self xvim] playbackRegister:repeatRegister withRepeatCount:[self numericArg]];
    return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    // in normal mode
    // move the a cursor to end of motion. We ignore the motion type.
    NSTextView* view = [self textView];
    NSRange r = NSMakeRange(to, 0);
    [view setSelectedRange:r];
    [view scrollToCursor];
    return nil;
}

// There are fewer invalid keys than valid ones so make a list of invalid keys.
// This can always be changed to a set of valid keys in the future if need be.
NSArray *_invalidRepeatKeys;
- (XVimRegisterOperation)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    if (_invalidRepeatKeys == nil){
        _invalidRepeatKeys =
        [[NSArray alloc] initWithObjects:
         @"m",
         @"q",
         @"C_r",
         @"u",
         @"v",
         @"V",
         @"C_v",
         @"AT",
         @"COLON",
         @"DOT",
         @"QUESTION",
         @"SLASH",
         nil];
    }
    NSString *key = [XVimEvaluator keyStringFromKeyEvent:event];
    if (key == @"q"){
        return REGISTER_IGNORE;
    }else if (xregister.isRepeat){
        SEL handler = NSSelectorFromString([key stringByAppendingString:@":"]);
        if( [self respondsToSelector:handler] && [[self superclass] instancesRespondToSelector:handler] == NO){
            if ([_invalidRepeatKeys containsObject:key] == NO){
                return REGISTER_REPLACE;
            }
        }
    }
    return [super shouldRecordEvent:event inRegister:xregister];
}


@end