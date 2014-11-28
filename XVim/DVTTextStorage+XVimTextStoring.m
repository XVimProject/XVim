//
//  DVTTextStorage+XVimTextStoring.m
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import "XVimStringBuffer.h"
#import "NSString+VimHelper.h"
#import "DVTTextStorage+XVimTextStoring.h"
#import "Logger.h"

#if XVIM_XCODE_VERSION != 5
#define DVTTextStorage DVTSourceTextStorage
#endif

@implementation DVTTextStorage (XVimTextStoring)

- (NSUInteger)xvim_numberOfLines
{
    return self.numberOfLines;
}

- (NSUInteger)xvim_tabWidth
{
    return self.tabWidth;
}

- (NSUInteger)xvim_indentWidth
{
    return self.indentWidth;
}

- (NSRange)xvim_indexRangeForLineNumber:(NSUInteger)num newLineLength:(NSUInteger *)newLineLength
{
    xvim_string_buffer_t sb;

    NSAssert(num > 0, @"Line numbers start at 1");
    if (num <= self.numberOfLines) {
        NSRange range = [self characterRangeForLineRange:NSMakeRange(num - 1, 1)];

        xvim_sb_init(&sb, self.xvim_string, range.location, range);
        xvim_sb_find_backward(&sb, [NSCharacterSet newlineCharacterSet]);

        if (newLineLength) *newLineLength = xvim_sb_range_to_end(&sb).length;
        return xvim_sb_range_to_start(&sb);
    }

    if (newLineLength) *newLineLength = 0;
    return NSMakeRange(NSNotFound, 0);
}

- (NSRange)xvim_indexRangeForLines:(NSRange)range
{
    NSAssert(range.location > 0, @"Line numbers start at 1");

    range.location--;
    return [self characterRangeForLineRange:range];
}

- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)index
{
    ASSERT_VALID_RANGE_WITH_EOF(index);
    if (index >= [self length]) {
        return self.numberOfLines;
    }
    return [self lineRangeForCharacterRange:NSMakeRange(index, 0)].location + 1;
}

@end

#if XVIM_XCODE_VERSION != 5

@implementation DVTFoldingTextStorage (XVimTextStoring)

- (NSString *)xvim_string
{
    NSString *string;

    [self increaseUsingFoldedRanges];
    string = self.string;
    [self decreaseUsingFoldedRanges];
    return string;

}

@end

#endif
