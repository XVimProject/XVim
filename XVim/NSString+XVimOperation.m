//
//  NSString+XVimOperation.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/13/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "NSString+XVimOperation.h"

// Pay attention to the CAPITALIZATION of method names.
// They are intentional.
// Look at the Vim help about the defference between "WORDS" and "words"

@implementation NSString (XVimOperation)
- (NSUInteger)prev:(NSRange)currentRange{ //h
    return 0;
}

- (NSUInteger)next:(NSRange)currentRange{ //l
    return 0;
}

- (NSUInteger)nextLine:(NSRange)currentRange{ //j
    return 0;
   
}

- (NSUInteger)prevLine:(NSRange)currentRange{ //k
    return 0;
}

- (NSUInteger)wordsForward:(NSUInteger)count :(NSRange)currentRange{ //w
    return 0;
}

- (NSUInteger)WORDSForward:(NSUInteger)count :(NSRange)currentRange{ //W
    return 0;
}


- (NSUInteger)endOfWordsForward:(NSUInteger)count :(NSRange)currentRange{ //e
    return 0;
}

- (NSUInteger)endOfWORDSForward:(NSUInteger)count :(NSRange)currentRange{ //E
    return 0;
}

- (NSUInteger)wordsBackward:(NSUInteger)count :(NSRange)currentRange{ //b
    return 0;
}

- (NSUInteger)WORDSBackward:(NSUInteger)count :(NSRange)currentRange{ //B
    return 0;
}

- (NSUInteger)sentencesBackward:(NSUInteger)count :(NSRange)currentRange{ //(
    return 0;
}

- (NSUInteger)sentencesForward:(NSUInteger)count :(NSRange)currentRange{ //)
    return 0;
}

- (NSUInteger)pragraphsBackward:(NSUInteger)count :(NSRange)currentRange{ //{
    return 0;
}

- (NSUInteger)pragraphsForward:(NSUInteger)count :(NSRange)currentRange{ //{
    return 0;
}

- (NSUInteger)sectionsBackward:(NSUInteger)count :(NSRange)currentRange{ //[[
    return 0;
}

- (NSUInteger)sectionsForward:(NSUInteger)count :(NSRange)currentRange{ //]]
    return 0;
}
@end
