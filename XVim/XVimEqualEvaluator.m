//
//  XVimEqualEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/5/2012
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEqualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimMotionEvaluator.h"
#import <CoreServices/CoreServices.h>

@implementation XVimEqualEvaluator
- (id)init{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
   self = [super init];
   if (self) {
       _repeat = repeat;
   }
    return self;
}

- (XVimEvaluator*)EQUAL:(id)arg{
    NSTextView *view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    
    [view moveToEndOfLine:self];
    [view moveForward:self]; // include eol
    
    NSRange end = [view selectedRange];
    [view setSelectedRange:NSMakeRange(begin.location, end.location - begin.location)];
    
    [[view textStorage] indentCharacterRange: [view selectedRange] undoManager:[view undoManager]];
    
    // set cursor back to original position
    [view setSelectedRange:begin];
    
    NSUInteger max = [[view string] length] - 1;
    return [self _motionFixedFrom:start.location To:end.location>max?max:end.location Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    if( to != 0 && type == CHARACTERWISE_EXCLUSIVE){
        to--;
    }else if( type == LINEWISE ){
        [view setSelectedRange:NSMakeRange(to,0)];
        to = [view nextNewline];
        if( NSNotFound == to ){
            to = [view string].length-1;
        }
        
        NSRange r = [view selectedRange];
        [view setSelectedRange:NSMakeRange(from,0)];
        from = [view prevNewline];
        [view setSelectedRange:r];
        if( NSNotFound == from ){
            from = 0;
        }else{
            from++;
        }
    }
    
    NSRange begin = [view selectedRange];
    [view setSelectedRangeWithBoundsCheck:from To:to];
    NSUInteger currentLength = [[view string] length] - 1;
    
    // Indent
    [[view textStorage] indentCharacterRange: [view selectedRange] undoManager:[view undoManager]];
    
    begin.location -= currentLength - [[view string] length] + 1;
    [view setSelectedRange:begin];
    return nil;
}

@end