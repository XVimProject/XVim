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
BOOL isOctDigit(unichar ch) { return ch >= '0' && ch <= '7'; }
BOOL isHexDigit(unichar ch) { return isDigit(ch) || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F'); }
BOOL isWhitespace(unichar ch) { return [[NSCharacterSet whitespaceCharacterSet] characterIsMember:ch]; }
BOOL isNewline(unichar ch) { return [[NSCharacterSet newlineCharacterSet] characterIsMember:ch]; }
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
BOOL isWhiteSpaceOrNewline(unichar ch) {
    return isWhitespace(ch) || isNewline(ch);
}
BOOL isKeyword(unichar ch){ // same as Vim's 'iskeyword' except that Vim's one is only defined for 1 byte char
    return isDigit(ch) || isAlpha(ch)  || ch >= 192;
}

static NSString *precomputed[9] = {
    @"",
    @" ",
    @"  ",
    @"   ",
    @"    ",
    @"     ",
    @"      ",
    @"       ",
    @"        ",
};

@implementation NSString (VimHelper)
- (BOOL) isDigit:(NSUInteger)index{
    return isDigit([self characterAtIndex:index]);
}

- (BOOL) isOctDigit:(NSUInteger)index{
    return isOctDigit([self characterAtIndex:index]);
}

- (BOOL) isHexDigit:(NSUInteger)index{
    return isHexDigit([self characterAtIndex:index]);
}

- (BOOL) isAlpha:(NSUInteger)index{
    return isAlpha([self characterAtIndex:index]);
}

- (BOOL) isDelimeter:(NSUInteger)index{
    return isDelimeter([self characterAtIndex:index]);
}

- (BOOL) isNewline:(NSUInteger)index{
    return isNewline([self characterAtIndex:index]); }

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

+ (NSString *)stringMadeOfSpaces:(NSUInteger)count
{
    if (count <= 8) {
        return precomputed[count];
    }
    return [NSMutableString mutableStringMadeOfSpaces:count];
}

@end

@implementation NSMutableString (VimHelper)

+ (NSMutableString *)mutableStringMadeOfSpaces:(NSUInteger)count
{
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:count];

    for (; count >= 8; count -= 8) {
        [s appendString:precomputed[8]];
    }
    if (count) {
        [s appendString:precomputed[count]];
    }
    return s;
}

@end
