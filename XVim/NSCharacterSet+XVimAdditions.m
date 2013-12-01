//
//  NSCharacterSet+XVimAdditions.m
//  XVim
//
//  Created by John AppleSeed on 25/11/13.
//
//

#import "NSCharacterSet+XVimAdditions.h"

@implementation NSCharacterSet (XVimAdditions)

static NSCharacterSet *_xvimHexDigits;
static NSCharacterSet *_xvimOctDigits;

NS_INLINE void _xvim_init_charsets(void)
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
#define CS(s) [[NSCharacterSet characterSetWithCharactersInString:s] retain]

        _xvimHexDigits = CS(@"0123456789abcdefABCDEF");
        _xvimOctDigits = CS(@"01234567");

#undef CS
    });
}

+ (NSCharacterSet *)xvim_octDigitsCharacterSet
{
    _xvim_init_charsets();
    return _xvimOctDigits;
}

+ (NSCharacterSet *)xvim_hexDigitsCharacterSet
{
    _xvim_init_charsets();
    return _xvimHexDigits;
}

@end
