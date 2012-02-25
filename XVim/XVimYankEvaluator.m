//
//  XVimYankEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimYankEvaluator.h"

@implementation XVimYankEvaluator

- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)y:(id)arg{
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    
    if (_repeat < 1) 
        return nil;
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    [view moveToEndOfLine:self];
    [view moveForward:self]; // include eol
    NSRange end = [view selectedRange];
    NSUInteger max = [[[self textView] string] length] - 1;
    [self setTextObject:NSMakeRange(start.location, end.location > max ? max-start.location: end.location-start.location)];
    // set cursor back to original position
    [view setSelectedRange:begin];
    
    return [self textObjectFixed];
}

-(XVimEvaluator*)textObjectFixed{
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view setSelectedRange:[self textObject]];
    [view copy:self];
    [view setSelectedRange:r];
    return nil;
}

@end


