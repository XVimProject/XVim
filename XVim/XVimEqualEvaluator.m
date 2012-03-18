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
#import "Logger.h"

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

    NSUInteger from = [view headOfLine:begin.location];
    if (from == NSNotFound){
        from = begin.location;
    }

    NSUInteger to = from;
    for (int i = 1; i < _repeat; ++i) {
        NSUInteger next = [view nextNewLine:to];
        if (next == NSNotFound){
            [self.xvim ringBell];
            break;
        }
        to = next + 1;
    }
    
    NSUInteger next = [view endOfLine:to];
    if (next != NSNotFound){
        to = next + 1;
    }
    TRACE_LOG(@"to: %d", to);
    return [self motionFixedFrom:from To:to Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    TRACE_LOG(@"from:%d to:%d type:%d", from, to, type);
    NSTextView* view = [self textView];
    NSRange begin = [view selectedRange];

    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    if( to != 0 && type == CHARACTERWISE_EXCLUSIVE){
        to--;
    }else if( type == LINEWISE ){
        [view setSelectedRange:NSMakeRange(to,0)];
        to = [view nextNewLine:to];
        if( NSNotFound == to ){
            to = [view string].length-1;
        }
        
        NSRange r = [view selectedRange];
        [view setSelectedRange:NSMakeRange(from,0)];
        from = [view prevNewLine:from];
        [view setSelectedRange:r];
        if( NSNotFound == from ){
            from = 0;
        }else{
            from++;
        }
    }

    [view setSelectedRangeWithBoundsCheck:from To:to];
    NSUInteger currentLength = [[view string] length] - 1;

    // Indent
    [[view textStorage] indentCharacterRange: [view selectedRange] undoManager:[view undoManager]];

    begin.location -= currentLength - [[view string] length] + 1;
    [view setSelectedRange:begin];
    return nil;
}

@end