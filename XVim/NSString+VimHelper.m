//
//  NSString+VimHelper.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/10/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSString+VimHelper.h"
/////////////////////////
// support functions   //
/////////////////////////
BOOL isDigit(unichar ch) { return ch >= '0' && ch <= '9'; }
BOOL isWhitespace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL isNewline(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; } // What's the defference with [NSCharacterSet newlineCharacterSet] characterIsMember:] ?
BOOL isNonAscii(unichar ch) { return ch > 128; } // is this not ch >= 128 ? (JugglerShu)
BOOL isAlpha(unichar ch) { 
    return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_';
}
BOOL isDelimeter(unichar ch) {
    return (ch >= '!' && ch <= '/') ||
    (ch >= ':' && ch <= '@') ||
    (ch >= '[' && ch <= '`' && ch != '_') ||
    (ch >= '{' && ch <= '~');
}
BOOL isNonblank(unichar ch) {
    return (!isWhitespace(ch)) && (!isNewline(ch));
}
BOOL isKeyword(unichar ch){ // same as Vim's 'iskeyword' except that Vim's one is only defined for 1 byte char
    return isDigit(ch) || isAlpha(ch)  || ch >= 192;
}

@implementation NSString (VimHelper)
- (BOOL) isDigit:(NSUInteger)index{
    return isDigit([self characterAtIndex:index]);
}

- (BOOL) isAlpha:(NSUInteger)index{
    return isAlpha([self characterAtIndex:index]);
}

- (BOOL) isDelimeter:(NSUInteger)index{
    return isDelimeter([self characterAtIndex:index]);
}

- (BOOL) isWhitespace:(NSUInteger)index{
    return isWhitespace([self characterAtIndex:index]);
}

- (BOOL) isNonAscii:(NSUInteger)index{
    return isNonAscii([self characterAtIndex:index]);
}

- (BOOL) isNewline:(NSUInteger)index{
    return isNewline([self characterAtIndex:index]); }

- (BOOL) isNonblank:(NSUInteger)index{
    return isNonblank([self characterAtIndex:index]);
}

- (BOOL) isKeyword:(NSUInteger)index{
    return isKeyword([self characterAtIndex:index]);
}

- (NSString*)convertToICURegex:(NSRegularExpressionOptions*)options{
    // TODO: These conversion may replace '\\<' into '\\b'
    //       (Note that characters here is NOT C language expression. So these string has 2 backslashes and one letter.)
    //       The 2 backshashes above should be processed as one backslash after processing REGEX escape.
    //       Since our code here replaces '\<' into '\b' the conversion happens.
    //       Buth the conversion should not be done and '\\<' should stay the same.
    
    // Word boundary
    // Vim : \<, \>
    // ICU : \b
    NSString* tmp = [self stringByReplacingOccurrencesOfString:@"\\<" withString:@"\\b"];
    tmp = [tmp stringByReplacingOccurrencesOfString:@"\\>" withString:@"\\b"];
    
    // Ignorecase
    if( [tmp rangeOfString:@"\\C"].location != NSNotFound ){
        *options &= ~NSRegularExpressionCaseInsensitive;
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\\C" withString:@""];
    }
    if( [tmp rangeOfString:@"\\c"].location != NSNotFound ){
        *options |= NSRegularExpressionCaseInsensitive;
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\\c" withString:@""];
    }
    
    return tmp;
}

@end
