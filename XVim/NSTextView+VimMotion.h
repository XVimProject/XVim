//
//  NSTextView+VimMotion.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"

typedef enum{
    MOTION_OPTION_NONE,
    LEFT_RIGHT_WRAP,
    LEFT_RIGHT_NOWRAP,
    BIGWORD // for 'WORD' motion
} MOTION_OPTION;

typedef struct _XVimWordInfo{
    BOOL isFirstWordInALine;
    NSUInteger lastEndOfLine;
    NSUInteger lastEndOfWord;
}XVimWordInfo;

BOOL isDigit(unichar ch);
BOOL isAlpha(unichar ch);
BOOL isDelimeter(unichar ch);
BOOL isWhiteSpace(unichar ch);
BOOL isNonAscii(unichar ch);
BOOL isNewLine(unichar ch);
BOOL isFuzzyWord(unichar ch);
BOOL isNonBlank(unichar ch);
BOOL isKeyword(unichar ch);

@interface NSTextView (VimMotion)
// Support Methods
- (BOOL) isEOF:(NSUInteger)index;
- (BOOL) isEOL:(NSUInteger)index;
- (BOOL) isNewLine:(NSUInteger)index;
- (BOOL) isBlankLine:(NSUInteger)index;
- (BOOL) isWhiteSpace:(NSUInteger)index;
- (BOOL) isValidCursorPosition:(NSUInteger)index;
- (NSUInteger)headOfLine:(NSUInteger)index;
- (NSUInteger)headOfLineWithoutSpaces:(NSUInteger)index;
- (NSUInteger)firstNonBlankInALine:(NSUInteger)index;
- (NSUInteger)nextNewLine:(NSUInteger)index;
- (NSUInteger)prevNewLine:(NSUInteger)index;
- (NSUInteger)tailOfLine:(NSUInteger)index;
- (NSUInteger)endOfLine:(NSUInteger)index;
- (NSUInteger)columnNumber:(NSUInteger)index;
- (void)adjustCursorPosition;
- (NSUInteger)positionAtLineNumber:(NSUInteger)num column:(NSUInteger)column;
- (NSUInteger)nextNonBlankInALine:(NSUInteger)index;

    
// Motions
- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;

- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info;
- (NSUInteger)wordsBackward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;

    
- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to;


// Scrolls
- (NSUInteger)pageForward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)pageBackward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)halfPageForward:(NSUInteger)index count:(NSUInteger)count;
- (NSUInteger)halfPageBackward:(NSUInteger)index count:(NSUInteger)count;
    
@end

