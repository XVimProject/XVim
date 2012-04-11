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
BOOL isWhiteSpace(unichar ch) { return ch == ' ' || ch == '\t'; }
BOOL isNewLine(unichar ch) { return (ch >= 0xA && ch <= 0xD) || ch == 0x85; } // What's the defference with [NSCharacterSet newlineCharacterSet] characterIsMember:] ?
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
BOOL isNonBlank(unichar ch) {
    return (!isWhiteSpace(ch)) && (!isNewLine(ch));
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

- (BOOL) isWhiteSpace:(NSUInteger)index{
    return isWhiteSpace([self characterAtIndex:index]);
}

- (BOOL) isNonAscii:(NSUInteger)index{
    return isNonAscii([self characterAtIndex:index]);
}

- (BOOL) isNewLine:(NSUInteger)index{
    return isNewLine([self characterAtIndex:index]); }

- (BOOL) isNonBlank:(NSUInteger)index{
    return isNonBlank([self characterAtIndex:index]);
}

- (BOOL) isKeyword:(NSUInteger)index{
    return isKeyword([self characterAtIndex:index]);
}

@end
