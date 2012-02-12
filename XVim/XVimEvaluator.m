//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"
#import "Logger.h"
#import "XVim.h"
    
static char* keynames[] = {
    "NUL",
    "SOH",
    "STX",
    "ETX",
    "EOT",
    "ENQ",
    "ACK",
    "BEL",
    "BS",
    "HT",
    "NL",
    "VT",
    "NP",
    "CR",
    "SO",
    "SI",
    "DLE",
    "DC1",
    "DC2",
    "DC3",
    "DC4",
    "NAK",
    "SYN",
    "ETB",
    "CAN",
    "EM",
    "SUB",
    "ESC",
    "FS",
    "GS",
    "RS",
    "US",
    "SP",
    "EXCLAMATION",
    "DQUOTE",
    "NUMBER",
    "DOLLAR",
    "PERCENT",
    "AMPERSAND",
    "SQUOTE",
    "LPARENTHESIS",
    "RPARENTHESIS",
    "ASTERISK",
    "PLUS",
    "COMMA",
    "MINUS",
    "DOT",
    "SLASH",
    "NUM0",
    "NUM1",
    "NUM2",
    "NUM3",
    "NUM4",
    "NUM5",
    "NUM6",
    "NUM7",
    "NUM8",
    "NUM9",
    "COLON",
    "SEMICOLON",
    "LESSTHAN",
    "EQUAL",
    "GREATERTHAN",
    "QUESTION",
    "AT",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "LSQUAREBRACKET",
    "BACKSLASH",
    "RSQUAREBRACKET",
    "CARET",
    "UNDERSCORE",
    "BACKQUOTE",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "LBRACE", // {
    "VERTICALLINE", // |
    "RBRACE", // }
    "TILDE", // ~
    "DEL"
};


@implementation XVimEvaluator
+ (NSString*) keyStringFromKeyEvent:(NSEvent*)event{
    // S- Shift
    // C- Control
    // M- Option
    // D- Command
    NSMutableString* keyStr = [[[NSMutableString alloc] init] autorelease];
    if( [event modifierFlags] & NSShiftKeyMask ){
        // implement later
    }
    if( [event modifierFlags] & NSControlKeyMask ){
        [keyStr appendString:@"C_"];
    }
    if( [event modifierFlags] & NSAlternateKeyMask ){
        [keyStr appendString:@"M_"];
    }
    if( [event modifierFlags] & NSCommandKeyMask ){
        [keyStr appendString:@"D_"];
    }
    
    unichar charcode = [[event charactersIgnoringModifiers] characterAtIndex:0];    
    if( 0 <= charcode && charcode <= 127 ){
        char* keyname = keynames[charcode];
        [keyStr appendFormat:[NSString stringWithCString:keyname encoding:NSASCIIStringEncoding]];
    }
    return keyStr;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    // This is default implemantation of evaluator.
    _xvim = xvim; // weak reference
    
    // Only keyDown event supporsed to be passed here.
    NSString* key = [XVimEvaluator keyStringFromKeyEvent:event];
    
    // Invokes each key event handler
    // <C-k> invokes "C-k:" selector
    // each method returns next evaluator(maybe self or maybe another evaluator )
    SEL handler = NSSelectorFromString([key stringByAppendingString:@":"]);
    if( [self respondsToSelector:handler] ){
        TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler withObject:nil];
    }
    else{
        TRACE_LOG(@"SELECTOR %@ not found", NSStringFromSelector(handler));
        return [self defaultNextEvaluator];
    }
}

- (XVimEvaluator*)defaultNextEvaluator{
    return nil;
}

- (NSTextView*)textView{
    return [_xvim sourceView];
}

- (XVim*)xvim{
    return _xvim;
}

@end

#pragma mark Numeric Evaluator

@implementation XVimNumericEvaluator
- (id)init
{
    self = [super init];
    if (self) {
        _numericArg = 1;
        _numericMode = NO;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if( [keyStr hasPrefix:@"NUM"] ){
        if( _numericMode ){
            NSString* numStr = [keyStr substringFromIndex:3];
            NSInteger n = [numStr integerValue]; 
            _numericArg*=10; //FIXME: consider integer overflow
            _numericArg+=n;
            return self;
        }
        else{
            if( [keyStr isEqualToString:@"NUM0"] ){
                // Nothing to do
                // Maybe handled by XVimNormalEvaluator
            }else{
                NSString* numStr = [keyStr substringFromIndex:3];
                NSInteger n = [numStr integerValue]; 
                _numericArg=n;
                _numericMode=YES;
                return self;
            }
        }
    }
    
    return [super eval:event ofXVim:xvim];
}

- (NSUInteger)numericArg{
    return _numericArg;
}

- (void)resetNumericArg{
    _numericArg = 1;
    _numericMode = NO;
}
@end

#pragma mark Text Object Evaluator

static NSRange makeRangeFromLocations( NSUInteger pos1, NSUInteger pos2 ){
    TRACE_LOG(@"pos1:%d  pos2:%d", pos1, pos2);
    NSRange r;
    if( pos1 < pos2 ){
        r = NSMakeRange(pos1, pos2-pos1);
    }else{
        r = NSMakeRange(pos2, pos1-pos2);
    }
    TRACE_LOG(@"location:%d  length:%d", r.location, r.length);
    return r;
}

@implementation XVimTextObjectEvaluator

- (id)init
{
    self = [super init];
    if (self) {
        _textObject = NSMakeRange(0, 0);
    }
    return self;
}

- (void)dealloc{
    [_textObjectFixedHandlerObject release];
}

- (void)setTextObjectFixed:(id)obj handler:(SEL)sel{
    [_textObjectFixedHandlerObject release];
    _textObjectFixedHandlerObject = [obj retain];
    _textObjectFixedHandler = sel;
}

- (NSRange)textObject{
    return _textObject;
}
- (void)setTextObject:(NSRange)textObject{
    _textObject = textObject;
}

- (NSUInteger)destLocation{
    return _destLocation;
}

// TODO: parse string and find the end of word byourself.
- (XVimEvaluator*)w:(id)arg{
    // Currently implemented easily
    NSTextView* view = [self textView];
    // Current position
    NSRange begin = [view selectedRange];
    
    // Position to next word
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordForward:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    // set cursor back to original position
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)W:(id)arg{
    return nil;
}

- (XVimEvaluator*)b:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordBackward:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)B:(id)arg{
    
    return nil;
}

- (XVimEvaluator*)g:(id)arg{
    return [[XVimgEvaluator alloc] init];
}

- (XVimEvaluator*)G:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToEndOfDocument:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;

    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)NUM0:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;

    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)DOLLAR:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToEndOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)k:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)j:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDown:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)l:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveRight:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)h:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveLeft:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}


- (XVimEvaluator*)PLUS:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDown:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
   [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}


- (XVimEvaluator*)LSQUAREBRACKET:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

- (XVimEvaluator*)RSQUAREBRACKET:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}


- (XVimEvaluator*)textObjectFixed{
    if( nil != _textObjectFixedHandlerObject ){
        return [_textObjectFixedHandlerObject performSelector:_textObjectFixedHandler withObject:self];
    }
    else{
        return nil;
    }
}
@end

#pragma mark Normal Command Evaluator

@implementation XVimNormalEvaluator
/////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please.  //
/////////////////////////////////////////////////////////////

- (XVimEvaluator*)a:(id)arg{
    NSTextView* view = [self textView];
    [view moveForward:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)A:(id)arg{
    NSTextView* view = [self textView];
    [view moveToEndOfLine:self];
    return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)C_b:(id)arg{
    NSTextView* view = [self textView];
    [view pageUp:self];
    return nil;
}

- (XVimEvaluator*)d:(id)arg{
    return [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg]];
}

- (XVimEvaluator*)D:(id)arg{
    NSTextView* view = [self textView];
    [view moveToEndOfLineAndModifySelection:self];
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)C_d:(id)arg{
    NSTextView* view = [self textView];
    [view pageDown:self];
    return nil;
}

- (XVimEvaluator*)f:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithRepeat:[self numericArg]];
    eval.forward = YES;
    return eval;
}

- (XVimEvaluator*)F:(id)arg{
    XVimSearchLineEvaluator* eval = [[XVimSearchLineEvaluator alloc] initWithRepeat:[self numericArg]];
    eval.forward = NO;
    return eval;
}

- (XVimEvaluator*)C_f:(id)arg{
    NSTextView* view = [self textView];
    [view pageDown:self];
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

- (XVimEvaluator*)J:(id)arg{
    NSTextView* view = [self textView];
    NSUInteger repeat = [self numericArg];
    if( 1 != repeat ){
        repeat--;
    }
    NSRange r = [view selectedRange];
    for( NSUInteger i = 0 ; i < repeat ; i++ ){
        [view moveToEndOfLine:self];
        [view deleteForward:self];
    }
    [view setSelectedRange:r];
    return nil;
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
    NSTextView* view = [self textView];
    [view moveForward:self];
    for(NSUInteger i = 0; i < [self numericArg]; i++ ){
        [view paste:self];
    }
    return nil;
    
}

- (XVimEvaluator*)P:(id)arg{
    NSTextView* view = [self textView];
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

- (XVimEvaluator*)u:(id)arg{
    // Go to insert
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg] ; i++){
        [[view undoManager] undo];
    }
    return nil;
}

- (XVimEvaluator*)C_u:(id)arg{
    NSTextView* view = [self textView];
    [view pageUp:self];
    return nil;
}

- (XVimEvaluator*)v:(id)arg{
    NSTextView* view = [self textView];
    [self xvim].mode = MODE_VISUAL;
    return [[XVimVisualEvaluator alloc] initWithOriginalSelectedRange:[view selectedRange]];
}

- (XVimEvaluator*)V:(id)arg{
    NSTextView* view = [self textView];
    [view selectLine:self];
    [self xvim].mode = MODE_VISUAL;
    return [[XVimVisualEvaluator alloc] initWithOriginalSelectedRange:[view selectedRange]];
}

- (XVimEvaluator*)x:(id)arg{
    NSTextView* view = [self textView];
    for( NSUInteger i = 0 ; i < [self numericArg]; i++ ){
        [view moveForwardAndModifySelection:self];
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
    // set firstResponder to XVimCommandLine(NSView's subclass) and everything is processed there.
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

- (XVimEvaluator*)textObjectFixed{
    // in normal mode
    // move the aaacursor to the end of range
    NSTextView* view = [self textView];
    [view setSelectedRange:NSMakeRange([self destLocation], 0)];
    return nil;
}

@end

@implementation XVimInsertEvaluator
- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
        _insertedEvents = [[NSMutableArray alloc] init];
        _insertedEventsAbort = NO;
    }
    return self;
}

- (void)dealloc{
    [_insertedEvents release];
    [super dealloc];
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if( [keyStr isEqualToString:@"ESC"] ){
        if( !_insertedEventsAbort ){
            for( int i = 0 ; i < _repeat-1; i++ ){
                for( NSEvent* e in _insertedEvents ){
                    [[xvim sourceView] XVimKeyDown:e];
                }
            }
        }
        xvim.mode = MODE_NORMAL;
        return nil;
    }    
    
    unichar c = [[event characters] characterAtIndex:0];
    if( !_insertedEventsAbort && 63232 <= c && c <= 63235){ // arrow keys. Ignore numericArg when "ESC" is pressed
        _insertedEventsAbort = YES;
    }
    else{
        [_insertedEvents addObject:event];
    }
    [[xvim sourceView] XVimKeyDown:event];
    return self;
}

@end

@implementation XVimDeleteEvaluator

- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)d:(id)arg{
    NSTextView* view = [self textView];
    [view selectLine:self];
    [view cut:self];
    
    return nil;
}

-(XVimEvaluator*)textObjectFixed{
    NSTextView* view = [self textView];
    [view setSelectedRange:[self textObject]];
    [view cut:self];
    return nil;
}

@end

@implementation XVimYankEvaluator

- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)y:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view selectLine:self];
    [view copy:self];
    [view setSelectedRange:r];
    return nil;
}

-(XVimEvaluator*)textObjectFixed{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view setSelectedRange:[self textObject]];
    [view copy:self];
    [view setSelectedRange:r];
    return nil;
}

@end


@implementation XVimVisualEvaluator 
@synthesize lineSelection;

- (id)initWithOriginalSelectedRange:(NSRange)selection{
    self = [super init];
    if (self) {
        _origin = selection.location;
    }
    return self;
}

- (XVimEvaluator*)defaultNextEvaluator{
    return self;
}

- (XVimEvaluator*)d:(id)arg{
    NSTextView* view = [self textView];
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)y:(id)arg{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view copy:self];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}
- (XVimEvaluator*)w:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordForwardAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)W:(id)arg{
    
    return self;
}

- (XVimEvaluator*)b:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveWordBackwardAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)B:(id)arg{
    return self;
}

- (XVimEvaluator*)C_d:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view pageDownAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
        
}

- (XVimEvaluator*)C_u:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view pageUpAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)NUM0:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)DOLLAR:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveToEndOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)k:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUpAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)j:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDownAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)l:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveRightAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)h:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveLeftAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}


- (XVimEvaluator*)PLUS:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDownAndModifySelection:self];
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUpAndModifySelection:self];
        [view moveToBeginningOfLineAndModifySelection:self];
    }
    [self resetNumericArg];
    return self;
}

- (XVimEvaluator*)ESC:(id)arg{
    [self xvim].mode = MODE_NORMAL;
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [[self textView] setSelectedRange:r];
   return nil;
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}
@end

@implementation XVimSearchLineEvaluator
@synthesize forward;

- (id) initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent *)event ofXVim:(XVim *)xvim{
    NSString* str = [event characters];
    NSTextView* view = [xvim sourceView];
    NSRange original = [view selectedRange];
    NSRange result = original;
    NSRange findRange;
    if( forward ){
        for( NSUInteger i = 0 ; i < _repeat; i++ ){
            if( result.location != NSNotFound ){
                [view setSelectedRange:NSMakeRange(result.location,0)];
                [view moveToEndOfLineAndModifySelection:self];
                findRange = [view selectedRange];
                findRange.location++;
            }
            else{
                break;
            }
            result = [[view string] rangeOfString:str options:0 range:findRange];
        }
    }
    else{
        for( NSUInteger i = 0 ; i < _repeat; i++ ){
            if( result.location != NSNotFound ){
                [view setSelectedRange:NSMakeRange(result.location,0)];
                [view moveToBeginningOfLineAndModifySelection:self];
                findRange = [view selectedRange];
            }
            else{
                break;
            }
            result = [[view string] rangeOfString:str options:NSBackwardsSearch range:findRange];
        }
    }
    if( result.location != NSNotFound ){
        [view setSelectedRange:NSMakeRange(result.location, 0)];
    }
    else{
        [view setSelectedRange:original];
    }
    return nil;
}


@end



@implementation XVimgEvaluator
- (XVimEvaluator*)g:(id)arg{
    NSTextView* view = [self textView];
    [view moveToBeginningOfDocument:self];
    return nil;
}
@end


@implementation XVimShiftEvaluator
@synthesize unshift;

- (id) initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}
    
- (XVimEvaluator*)GREATERTHAN:(id)arg{
    if( !unshift ){
        NSTextView* view = [self textView];
        [view shiftRight:self];
    }
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    //unshift
    if( unshift ){
        NSTextView* view = [self textView];
        [view shiftLeft:self];
    }
    return nil;
}
@end
