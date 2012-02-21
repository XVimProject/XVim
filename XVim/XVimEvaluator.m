

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
    else if ( charcode == 63232 ){
        [keyStr appendString:@"Up"];
    }
    else if ( charcode == 63233 ){
        [keyStr appendString:@"Down"];
    }
    else if ( charcode == 63234 ){
        [keyStr appendString:@"Left"];
    }
    else if ( charcode == 63235 ){
        [keyStr appendString:@"Right"];
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
    // This is default implementation of evaluator.
    _xvim = xvim; // weak reference
    
    // Only keyDown event supporsed to be passed here.
    NSString* key = [XVimEvaluator keyStringFromKeyEvent:event];
    
    // Invokes each key event handler
    // <C-k> invokes "C_k:" selector
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


// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET:(id)arg{
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    NSMutableString* s = [[view textStorage] mutableString];
    [view moveToBeginningOfLine:self];
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
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

/* 
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SP:(id)arg{
    return [self l:arg];
}

/* 
 * Delete (DEL) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)DEL:(id)arg{
    return [self h:arg];
}

- (XVimEvaluator*)PLUS:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveDown:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char, now that we are on the destination line
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
   _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

/* 
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR:(id)arg{
    return [self PLUS:arg];
}


- (XVimEvaluator*)MINUS:(id)arg{
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view moveUp:self];
        [view moveToBeginningOfLine:self];
    }
    NSRange end = [view selectedRange];
    // move to 1st non whitespace char, now that we are on the destination line
    for (NSUInteger idx = end.location; idx < s.length; idx++) {
        if (![(NSCharacterSet *)[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]])
            break;
        [view moveRight:self];
    }
    end = [view selectedRange];
    _destLocation = end.location;
    [self setTextObject:makeRangeFromLocations(begin.location, end.location)];
    
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}


- (XVimEvaluator*)LSQUAREBRACKET:(id)arg{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET:(id)arg{
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
- (XVimEvaluator*)LBRACE:(id)arg{ // {
    NSTextView* view = [self textView];
    NSMutableString* s = [[view textStorage] mutableString];
    NSRange begin = [view selectedRange];
    NSUInteger pos = begin.location;
    if( pos == 0 ){
        return nil;
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
    
    _destLocation = paragraph_head;
    [self setTextObject:makeRangeFromLocations(paragraph_head, begin.location)];
    return [self textObjectFixed];
}

- (XVimEvaluator*)RBRACE:(id)arg{ // }
    NSTextView* view = [self textView];
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
    
    _destLocation = paragraph_head;
    [self setTextObject:makeRangeFromLocations(paragraph_head, begin.location)];
    return [self textObjectFixed];
  
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
- (XVimEvaluator*)LPARENTHESIS:(id)arg{ // (
    NSTextView* view = [self textView];
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
        _destLocation = sentence_head;
        [self setTextObject:makeRangeFromLocations(sentence_head, begin.location)];
        return [self textObjectFixed];
    }else{
        // no movement
        return nil;
    }
   
    
}

- (XVimEvaluator*)RPARENTHESIS:(id)arg{ // )
    NSTextView* view = [self textView];
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
    
    _destLocation = sentence_head;
    [self setTextObject:makeRangeFromLocations(sentence_head, begin.location)];
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


@implementation XVimInsertEvaluator
- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    return [self initOneCharMode:FALSE withRepeat:repeat];
}

- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat{
    if (self) {
        _repeat = repeat;
        _oneCharMode = oneCharMode;
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
    if( [keyStr isEqualToString:@"ESC"] || [keyStr isEqualToString:@"C_LSQUAREBRACKET"] || [keyStr isEqualToString:@"C_c"]){
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
    if (_oneCharMode == TRUE) {
        xvim.mode = MODE_NORMAL;
        return nil;
    } else {
        return self;
    }
}

@end

@implementation XVimDeleteEvaluator

- (id)init
{
    return [self initWithRepeat:1 insertModeAtCompletion:FALSE];
}

- (id)initWithRepeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion {
    self = [super init];
    if (self) {
        _insertModeAtCompletion = insertModeAtCompletion;
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)d:(id)arg{
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if (_repeat < 1) 
        return nil;
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    [view moveToEndOfLine:self];
    [view moveRight:self]; // include eol
    NSRange end = [view selectedRange];
    //_destLocation = end.location;
    NSUInteger max = [[[self textView] string] length] - 1;
    [self setTextObject:makeRangeFromLocations(start.location, end.location > max ? max: end.location)];
    // set cursor back to original position
    [view setSelectedRange:begin];
    return [self textObjectFixed];
}

-(XVimEvaluator*)textObjectFixed{
    NSTextView* view = [self textView];
    [view setSelectedRange:[self textObject]];
    [view cut:self];
    if (_insertModeAtCompletion == TRUE) {
        // Go to insert 
        [self xvim].mode = MODE_INSERT;
        return [[XVimInsertEvaluator alloc] initWithRepeat:[self numericArg]];
    }
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
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    
    if (_repeat < 1) 
        return nil;
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    [view moveToEndOfLine:self];
    [view moveRight:self]; // include eol
    NSRange end = [view selectedRange];
    //_destLocation = end.location;
    NSUInteger max = [[[self textView] string] length] - 1;
    [self setTextObject:makeRangeFromLocations(start.location, end.location > max ? max: end.location)];
    // set cursor back to original position
    [view setSelectedRange:begin];
    
    return [self textObjectFixed];
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
