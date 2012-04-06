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

@implementation XVimEvaluator

@synthesize xvim = _xvim;

- (NSUInteger)insertionPoint{
    NSRange range = [[self textView] selectedRange];
    return range.location + range.length;
}

- (XVIM_MODE)becameHandler:(XVim*)xvim{
    self.xvim = xvim;
    return MODE_NORMAL;
}

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

+ (BOOL) isNumericKey:(NSEvent*)event{
    NSString *keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    return [keyStr hasPrefix:@"NUM"] && [keyStr length] == 4;
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

- (DVTSourceTextView*)textView{
    return [self.xvim sourceView];
}

- (XVimRegisterOperation)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    if (xregister.isReadOnly){
        return REGISTER_IGNORE;
    }
    return REGISTER_APPEND;
}

- (XVimEvaluator*)D_d:(id)arg{
    // This is for debugging purpose.
    // Write any debugging process to confirme some behaviour.
    
    return nil;
}
@end


