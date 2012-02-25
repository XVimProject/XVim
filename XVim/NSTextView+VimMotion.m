//
//  NSTextView+VimMotion.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSTextView+VimMotion.h"
#import "Logger.h"


//
// This category deals Vim's motion in NSTextView.
// Each method of motion should return the destination position of the motion.
// They shouldn't change the position of current insertion point(selected range)

@implementation NSTextView (VimMotion)

- (NSUInteger)prev:(NSNumber*)count{ //h
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveLeft:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)next:(NSNumber*)count{ //l
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveRight:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)prevLine:(NSNumber*)count{ //k
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)nextLine:(NSNumber*)count{ //j
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)wordsForward:(NSNumber*)count{ //w
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordForward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)WORDSForward:(NSNumber*)count{ //W
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordForward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}


- (NSUInteger)endOfWordsForward:(NSNumber*)count{ //e
    return 0;
}

- (NSUInteger)endOfWORDSForward:(NSNumber*)count{ //E
    return 0;
}

- (NSUInteger)wordsBackward:(NSNumber*)count{ //b
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordBackward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)WORDSBackward:(NSNumber*)count{ //B
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self moveWordBackward:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;
}

- (NSUInteger)halfPageForward:(NSNumber*)count{ // C-d
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)halfPageBackward:(NSNumber*)count{ // C-u
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)pageForward:(NSNumber*)count{ // C-f
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageDown:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)pageBackward:(NSNumber*)count{ // C-b
    // sample impl
    NSRange original = [self selectedRange];
    for( int i = 0 ; i < [count intValue]; i++ ){
        [self pageUp:self];
    }
    NSUInteger dest = [self selectedRange].location;
    [self setSelectedRange:original];
    return dest;   
}

- (NSUInteger)sentencesBackward:(NSNumber*)count{ //(
    return 0;
}

- (NSUInteger)sentencesForward:(NSNumber*)count{ //)
    return 0;
}

- (NSUInteger)pragraphsBackward:(NSNumber*)count{ //{
    return 0;
}

- (NSUInteger)pragraphsForward:(NSNumber*)count{ //{
    return 0;
}

- (NSUInteger)sectionsBackward:(NSNumber*)count{ //[[
    return 0;
}

- (NSUInteger)sectionsForward:(NSNumber*)count{ //]]
    return 0;
}
@end