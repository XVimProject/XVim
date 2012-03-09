//
//  XVimEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.  
//  Copyright 2012 JugglerShu.Net. All rights reserved.  
//

#import "XVimEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "NSTextView+VimMotion.h"
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


#pragma mark XVimEvaluator
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

- (BOOL)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    return NO;
}

@end

#pragma mark VimLocalMarkEvaluator


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


// This evaluator is base class of an evaluator which takes argument to fix the motion
// e.g. 'f','F'
@implementation XVimMotionArgumentEvaluator
- (id)initWithMotionEvaluator:(XVimMotionEvaluator*)evaluator withRepeat:(NSUInteger)repeat{
    self = [super init];
    if( self ){
        _repeat = repeat;
        _motionEvaluator = [evaluator retain];
    }
    return self;
}


- (void)dealloc{
    [_motionEvaluator release];
    [super dealloc];
}

- (NSUInteger)repeat{
    return _repeat;
}

- (XVimEvaluator*)_motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    if( nil != _motionEvaluator ){
        return [_motionEvaluator motionFixedFrom:from To:to Type:type];
    }
    return nil;
}

- (XVimEvaluator*)commonMotion:(SEL)motion Type:(BOOL)type{
    if( nil != _motionEvaluator ){
        return [_motionEvaluator commonMotion:motion Type:type];
    }
    return nil;
}
@end

