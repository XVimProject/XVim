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
- (BOOL) isNewLine:(NSUInteger)index;
- (BOOL) isBlankLine:(NSUInteger)index;
- (BOOL) isValidCursorPosition:(NSUInteger)index;
- (NSUInteger)headOfLine:(NSUInteger)index;
- (NSUInteger)nextNewLine:(NSUInteger)index;
- (NSUInteger)endOfLine:(NSUInteger)index;
- (NSUInteger)headOfLine; // Obsolete
- (NSUInteger)prevNewline; // Obsolete
- (NSUInteger)endOfLine; // Obsolete
- (NSUInteger)nextNewline; // Obsolete
- (NSUInteger)columnNumber:(NSUInteger)index;

// Motions
- (NSUInteger)prev:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)next:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)prev:(NSNumber*)count; // Obsolete
- (NSUInteger)next:(NSNumber*)count; //Obsolete

- (NSUInteger)nextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)prevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (NSUInteger)nextNewline; // Obsolete
- (NSUInteger)prevNewline; // Obsolete
- (NSUInteger)wordsForward:(NSUInteger)index count:(NSUInteger)count option:(MOTION_OPTION)opt info:(XVimWordInfo*)info;
    
- (void)setSelectedRangeWithBoundsCheck:(NSUInteger)from To:(NSUInteger)to;
@end
